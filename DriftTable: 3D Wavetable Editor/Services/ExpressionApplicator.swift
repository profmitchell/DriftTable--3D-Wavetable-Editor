//
//  ExpressionApplicator.swift
//  DriftTable
//
//  Applies compiled expressions to wavetable frames
//

import Foundation

// MARK: - Expression Mode

enum ExpressionMode {
    case singleFrame
    case multiFrame
}

func expressionMode(for compiled: CompiledExpression, engine: FormulaEngine) -> ExpressionMode {
    return engine.usesFrameVariables(compiled) ? .multiFrame : .singleFrame
}

// MARK: - Single-Frame Application

func applyExpressionSingleFrame(
    compiled: CompiledExpression,
    engine: FormulaEngine,
    frames: inout [[Float]],
    selectedFrameIndex: Int,
    sampleCount: Int
) throws {
    // Validate inputs
    guard selectedFrameIndex >= 0 && selectedFrameIndex < frames.count else {
        throw FormulaError.evaluationError("Invalid frame index: \(selectedFrameIndex)")
    }
    
    guard sampleCount > 0 else {
        throw FormulaError.evaluationError("Invalid sample count: \(sampleCount)")
    }
    
    guard frames[selectedFrameIndex].count == sampleCount else {
        throw FormulaError.evaluationError("Frame sample count mismatch")
    }
    
    // Copy the selected frame for "in" and "sel" references
    let oldFrame = frames[selectedFrameIndex]
    
    // Precompute random values per sample (reproducible)
    let randomPerSample = generateRandomSamples(count: sampleCount)
    
    // Process each sample
    for i in 0..<sampleCount {
        let w = sampleCount > 1 ? Float(i) / Float(sampleCount - 1) : 0.5
        let x = w * 2.0 - 1.0
        
        let context = FormulaContext(
            x: x,
            w: w,
            y: 0.0,
            z: 0.0,
            inSample: oldFrame[i],
            selSample: oldFrame[i],
            randSample: randomPerSample[i],
            q: nil
        )
        
        let value = try engine.evaluate(compiled, context: context)
        
        // Clamp to [-1, 1]
        frames[selectedFrameIndex][i] = max(-1.0, min(1.0, value))
    }
}

// MARK: - Multi-Frame Application

func applyExpressionMultiFrame(
    compiled: CompiledExpression,
    engine: FormulaEngine,
    frames: inout [[Float]],
    selectedFrameIndex: Int,
    sampleCount: Int
) throws {
    // Validate inputs
    guard selectedFrameIndex >= 0 && selectedFrameIndex < frames.count else {
        throw FormulaError.evaluationError("Invalid frame index: \(selectedFrameIndex)")
    }
    
    guard sampleCount > 0 else {
        throw FormulaError.evaluationError("Invalid sample count: \(sampleCount)")
    }
    
    let frameCount = frames.count
    guard frameCount > 0 else {
        throw FormulaError.evaluationError("No frames available")
    }
    
    // Validate all frames have correct sample count
    for (index, frame) in frames.enumerated() {
        guard frame.count == sampleCount else {
            throw FormulaError.evaluationError("Frame \(index) sample count mismatch")
        }
    }
    
    // Copy all frames for "in" reference
    let oldFrames = frames
    
    // Precompute random values per sample (reproducible)
    let randomPerSample = generateRandomSamples(count: sampleCount)
    
    // Process each frame
    for t in 0..<frameCount {
        let y = frameCount > 1 ? Float(t) / Float(frameCount - 1) : 0.5
        let z = y * 2.0 - 1.0
        
        // Process each sample in this frame
        for i in 0..<sampleCount {
            let w = sampleCount > 1 ? Float(i) / Float(sampleCount - 1) : 0.5
            let x = w * 2.0 - 1.0
            
            let context = FormulaContext(
                x: x,
                w: w,
                y: y,
                z: z,
                inSample: oldFrames[t][i],
                selSample: oldFrames[selectedFrameIndex][i],
                randSample: randomPerSample[i],
                q: nil
            )
            
            let value = try engine.evaluate(compiled, context: context)
            
            // Clamp to [-1, 1]
            frames[t][i] = max(-1.0, min(1.0, value))
        }
    }
}

// MARK: - Helper Functions

private func generateRandomSamples(count: Int) -> [Float] {
    // Use a seeded random generator for reproducibility
    var generator = SeededRandomGenerator(seed: 42)
    return (0..<count).map { _ in
        Float.random(in: -1.0...1.0, using: &generator)
    }
}

// Simple seeded random number generator for reproducibility
private struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        state = seed
    }
    
    mutating func next() -> UInt64 {
        // Simple LCG algorithm
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

