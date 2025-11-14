//
//  ExpressionPanelView.swift
//  DriftTable
//
//  SwiftUI panel for math expression wavetable generation
//

import SwiftUI

struct ExpressionPanelView: View {
    @State private var expressionText: String = "sin(2 * pi * x)"
    @State private var lastError: String? = nil
    @State private var detectedMode: ExpressionMode? = nil
    @State private var isProcessing: Bool = false
    
    @Binding var frames: [[Float]]
    @Binding var selectedFrameIndex: Int
    let sampleCount: Int
    
    // Formula engine instance
    private let engine = FormulaEngine()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("Math Expression Generator")
                .font(.headline)
            
            // Expression editor
            VStack(alignment: .leading, spacing: 4) {
                Text("Expression:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $expressionText)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .onChange(of: expressionText) { _ in
                        updateDetectedMode()
                    }
            }
            
            // Mode indicator
            HStack {
                Text("Mode:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let mode = detectedMode {
                    switch mode {
                    case .singleFrame:
                        Label("Single-frame", systemImage: "waveform")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    case .multiFrame:
                        Label("Multi-frame", systemImage: "waveform.badge.plus")
                            .font(.subheadline)
                            .foregroundColor(.purple)
                    }
                } else {
                    Text("—")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Variables reference
            DisclosureGroup("Available Variables") {
                VStack(alignment: .leading, spacing: 4) {
                    variableRow("x", "Position in [-1, 1]")
                    variableRow("w", "Position in [0, 1]")
                    variableRow("y", "Frame index in [0, 1] (multi-frame)")
                    variableRow("z", "Frame index in [-1, 1] (multi-frame)")
                    variableRow("in", "Original sample value")
                    variableRow("sel", "Sample from selected frame")
                    variableRow("rand", "Random value per sample")
                    
                    Divider()
                    
                    Text("Constants: pi, e")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Functions: sin, cos, tan, asin, acos, atan, sinh, cosh, tanh, asinh, acosh, atanh, log2, log10, log, ln, exp, sqrt, sign, rint, abs, min, max, sum, avg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
            .font(.caption)
            
            // Apply button
            Button(action: applyExpression) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    }
                    Text(isProcessing ? "Applying..." : "Apply Expression")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isProcessing || expressionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            // Error display
            if let error = lastError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Example expressions
            DisclosureGroup("Example Expressions") {
                VStack(alignment: .leading, spacing: 8) {
                    exampleButton("Sine Wave", "sin(2 * pi * x)")
                    exampleButton("Square Wave", "sign(sin(2 * pi * x))")
                    exampleButton("Sawtooth", "x")
                    exampleButton("Triangle", "abs(x) * 2 - 1")
                    exampleButton("PWM", "x < 0.5 ? 1 : -1")
                    exampleButton("Harmonics", "sin(2*pi*x) + 0.5*sin(4*pi*x) + 0.25*sin(6*pi*x)")
                    exampleButton("Evolving (multi)", "sin(2*pi*x) * (1 - y) + sign(sin(2*pi*x)) * y")
                    exampleButton("Morph Sine→Square", "sin(2*pi*x) + z * abs(sin(2*pi*x))")
                }
                .padding(.vertical, 4)
            }
            .font(.caption)
        }
        .padding()
        .onAppear {
            updateDetectedMode()
        }
    }
    
    // MARK: - Helper Views
    
    private func variableRow(_ name: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text(name)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.semibold)
                .frame(width: 40, alignment: .leading)
            Text("—")
                .foregroundColor(.secondary)
            Text(description)
                .foregroundColor(.secondary)
        }
    }
    
    private func exampleButton(_ title: String, _ expression: String) -> some View {
        Button(action: {
            expressionText = expression
        }) {
            HStack {
                Text(title)
                Spacer()
                Text(expression)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .buttonStyle(.borderless)
    }
    
    // MARK: - Actions
    
    private func updateDetectedMode() {
        lastError = nil
        
        let trimmed = expressionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            detectedMode = nil
            return
        }
        
        do {
            let compiled = try engine.compile(trimmed)
            detectedMode = expressionMode(for: compiled, engine: engine)
        } catch {
            detectedMode = nil
        }
    }
    
    private func applyExpression() {
        lastError = nil
        
        let trimmed = expressionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            lastError = "Expression is empty"
            return
        }
        
        isProcessing = true
        
        // Run on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Compile expression
                let compiled = try engine.compile(trimmed)
                let mode = expressionMode(for: compiled, engine: engine)
                
                // Create mutable copy of frames
                var newFrames = frames
                
                // Apply based on mode
                switch mode {
                case .singleFrame:
                    try applyExpressionSingleFrame(
                        compiled: compiled,
                        engine: engine,
                        frames: &newFrames,
                        selectedFrameIndex: selectedFrameIndex,
                        sampleCount: sampleCount
                    )
                case .multiFrame:
                    try applyExpressionMultiFrame(
                        compiled: compiled,
                        engine: engine,
                        frames: &newFrames,
                        selectedFrameIndex: selectedFrameIndex,
                        sampleCount: sampleCount
                    )
                }
                
                // Update on main thread
                DispatchQueue.main.async {
                    frames = newFrames
                    detectedMode = mode
                    isProcessing = false
                }
            } catch let error as FormulaError {
                DispatchQueue.main.async {
                    switch error {
                    case .parseError(let msg):
                        lastError = "Parse error: \(msg)"
                    case .evaluationError(let msg):
                        lastError = "Evaluation error: \(msg)"
                    }
                    isProcessing = false
                }
            } catch {
                DispatchQueue.main.async {
                    lastError = "Unexpected error: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var frames: [[Float]] = Array(repeating: Array(repeating: 0.0, count: 256), count: 8)
        @State private var selectedFrameIndex = 0
        
        var body: some View {
            ExpressionPanelView(
                frames: $frames,
                selectedFrameIndex: $selectedFrameIndex,
                sampleCount: 256
            )
        }
    }
    
    return PreviewWrapper()
}

