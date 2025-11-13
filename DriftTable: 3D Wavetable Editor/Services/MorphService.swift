//
//  MorphService.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import Foundation

struct MorphService {
    /// Generate wavetable frames by morphing between key shapes
    static func generateFrames(from keyShapes: [KeyShape], settings: MorphSettings, samplesPerFrame: Int) -> [[Float]] {
        guard keyShapes.count >= 2 else {
            // If only one key shape, return it repeated
            if let first = keyShapes.first {
                return Array(repeating: first.samples, count: settings.frameCount)
            }
            return []
        }
        
        var frames: [[Float]] = []
        
        // Calculate interpolation curve based on morph style
        let curve = interpolationCurve(for: settings.morphStyle, frameCount: settings.frameCount)
        
        // Distribute key shapes across frames
        let segments = keyShapes.count - 1
        let framesPerSegment = settings.frameCount / segments
        let remainderFrames = settings.frameCount % segments
        
        var frameIndex = 0
        
        for segment in 0..<segments {
            let startShape = keyShapes[segment]
            let endShape = keyShapes[segment + 1]
            
            let segmentFrames = framesPerSegment + (segment < remainderFrames ? 1 : 0)
            
            for _ in 0..<segmentFrames {
                let curveT = curve[frameIndex]
                
                // Interpolate between shapes
                let interpolated = interpolateShapes(startShape.samples, endShape.samples, t: curveT)
                
                // Add organic variation if needed
                let final = settings.morphStyle == .organic ? addOrganicVariation(interpolated, intensity: 0.02) : interpolated
                
                frames.append(final)
                frameIndex += 1
            }
        }
        
        // Apply final smoothing pass to ensure smooth transitions between frames
        return smoothFrames(frames)
    }
    
    /// Apply smoothing across frames to ensure smooth transitions
    private static func smoothFrames(_ frames: [[Float]]) -> [[Float]] {
        guard frames.count > 2 else { return frames }
        
        var smoothed = frames
        
        // Smooth transitions between adjacent frames
        for frameIndex in 1..<(frames.count - 1) {
            let prevFrame = frames[frameIndex - 1]
            let currFrame = frames[frameIndex]
            let nextFrame = frames[frameIndex + 1]
            
            guard prevFrame.count == currFrame.count && currFrame.count == nextFrame.count else {
                continue
            }
            
            // Blend each sample with neighbors from adjacent frames
            for sampleIndex in 0..<currFrame.count {
                let prev = prevFrame[sampleIndex]
                let curr = currFrame[sampleIndex]
                let next = nextFrame[sampleIndex]
                
                // Gentle cross-frame smoothing (10% influence from neighbors)
                smoothed[frameIndex][sampleIndex] = prev * 0.05 + curr * 0.9 + next * 0.05
            }
        }
        
        return smoothed
    }
    
    private static func interpolateShapes(_ shape1: [Float], _ shape2: [Float], t: Float) -> [Float] {
        guard shape1.count == shape2.count else {
            // If sizes don't match, pad the smaller one
            let maxCount = max(shape1.count, shape2.count)
            let padded1 = padArray(shape1, to: maxCount)
            let padded2 = padArray(shape2, to: maxCount)
            let interpolated = zip(padded1, padded2).map { $0 * (1.0 - t) + $1 * t }
            // Apply smoothing to reduce artifacts
            return smoothFrame(interpolated)
        }
        
        let interpolated = zip(shape1, shape2).map { $0 * (1.0 - t) + $1 * t }
        // Apply smoothing to reduce artifacts
        return smoothFrame(interpolated)
    }
    
    /// Apply gentle smoothing to a frame to reduce high-frequency artifacts and make transitions smoother
    private static func smoothFrame(_ frame: [Float]) -> [Float] {
        guard frame.count > 2 else { return frame }
        
        var smoothed = [Float](repeating: 0.0, count: frame.count)
        
        // Use a simple 3-point moving average with edge handling
        for i in 0..<frame.count {
            let prev = i > 0 ? frame[i - 1] : frame[i]
            let curr = frame[i]
            let next = i < frame.count - 1 ? frame[i + 1] : frame[i]
            
            // Weighted average: center sample gets more weight
            smoothed[i] = prev * 0.25 + curr * 0.5 + next * 0.25
        }
        
        return smoothed
    }
    
    private static func padArray(_ array: [Float], to count: Int) -> [Float] {
        guard array.count < count else { return array }
        var padded = array
        while padded.count < count {
            padded.append(0.0)
        }
        return padded
    }
    
    private static func interpolationCurve(for style: MorphStyle, frameCount: Int) -> [Float] {
        var curve: [Float] = []
        
        for i in 0..<frameCount {
            let t = Float(i) / Float(frameCount - 1)
            let curveT: Float
            
            switch style {
            case .direct:
                curveT = t
            case .soft:
                // Slow at ends, faster in middle (ease in-out)
                curveT = t * t * (3.0 - 2.0 * t)
            case .punchy:
                // Fast start, slow end
                curveT = 1.0 - pow(1.0 - t, 3.0)
            case .stepped:
                // Discrete steps
                let steps = 8
                let step = Int(t * Float(steps))
                curveT = Float(step) / Float(steps)
            case .organic:
                // Direct with slight variation
                curveT = t
            }
            
            curve.append(curveT)
        }
        
        return curve
    }
    
    private static func addOrganicVariation(_ samples: [Float], intensity: Float) -> [Float] {
        return samples.map { sample in
            let variation = (Float.random(in: -1...1) * intensity)
            return sample + variation
        }
    }
}

