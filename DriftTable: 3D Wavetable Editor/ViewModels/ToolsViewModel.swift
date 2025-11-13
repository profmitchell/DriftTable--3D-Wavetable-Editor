//
//  ToolsViewModel.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import Foundation
import SwiftUI
import Combine

class ToolsViewModel: ObservableObject {
    @Published var selectedTool: Tool = .liftDrop
    
    // Tool parameters
    @Published var liftDropAmount: Float = 0.0 // -1.0 to 1.0
    @Published var verticalStretchAmount: Float = 1.0 // 0.1 to 3.0
    @Published var horizontalStretchAmount: Float = 1.0 // 0.1 to 3.0
    @Published var pinchStrength: Float = 0.5 // 0.0 to 1.0
    @Published var pinchPosition: Float = 0.5 // 0.0 to 1.0 (normalized position)
    @Published var tiltAmount: Float = 0.0 // -1.0 to 1.0
    @Published var symmetryAmount: Float = 0.0 // 0.0 to 1.0
    @Published var smoothBrushSize: Float = 0.1 // 0.01 to 0.5 (normalized)
    @Published var smoothBrushStrength: Float = 0.5 // 0.0 to 1.0
    
    // Arc tool parameters
    @Published var arcStartPosition: Float = 0.25 // 0.0 to 1.0
    @Published var arcEndPosition: Float = 0.75 // 0.0 to 1.0
    @Published var arcCurvature: Float = 0.5 // -1.0 (concave) to 1.0 (convex)
    
    // Grit brush parameters
    @Published var gritBrushSize: Float = 0.1 // 0.01 to 0.5 (normalized)
    @Published var gritBrushIntensity: Float = 0.3 // 0.0 to 1.0
    
    // Global application callback
    var applyGlobally: (() -> Void)?
    
    // Apply Lift/Drop
    func applyLiftDrop(to shape: KeyShape, amount: Float) -> KeyShape {
        var modified = shape
        modified.samples = shape.samples.map { $0 + amount }
        return modified
    }
    
    // Apply Vertical Stretch/Squeeze
    func applyVerticalStretch(to shape: KeyShape, amount: Float) -> KeyShape {
        var modified = shape
        modified.samples = shape.samples.map { $0 * amount }
        return modified
    }
    
    // Apply Horizontal Stretch/Compress
    func applyHorizontalStretch(to shape: KeyShape, amount: Float) -> KeyShape {
        var modified = shape
        let sampleCount = shape.samples.count
        var newSamples = [Float](repeating: 0.0, count: sampleCount)
        
        for i in 0..<sampleCount {
            let sourceIndex = Float(i) / amount
            let index0 = Int(floor(sourceIndex))
            let index1 = min(index0 + 1, sampleCount - 1)
            let t = sourceIndex - Float(index0)
            
            if index0 >= 0 && index0 < sampleCount {
                let value0 = shape.samples[index0]
                let value1 = shape.samples[index1]
                newSamples[i] = value0 + (value1 - value0) * t
            }
        }
        
        modified.samples = newSamples
        return modified
    }
    
    // Apply Pinch
    func applyPinch(to shape: KeyShape, position: Float, strength: Float) -> KeyShape {
        var modified = shape
        let sampleCount = shape.samples.count
        let pinchIndex = Int(Float(sampleCount) * position)
        
        modified.samples = shape.samples.enumerated().map { index, sample in
            let distance = abs(Float(index) - Float(pinchIndex)) / Float(sampleCount)
            let pinchFactor = 1.0 - (strength * exp(-distance * 10.0))
            return sample * pinchFactor
        }
        
        return modified
    }
    
    // Apply Tilt
    func applyTilt(to shape: KeyShape, amount: Float) -> KeyShape {
        var modified = shape
        let sampleCount = shape.samples.count
        
        modified.samples = shape.samples.enumerated().map { index, sample in
            let normalizedPos = Float(index) / Float(sampleCount) // 0.0 to 1.0
            let tiltOffset = (normalizedPos - 0.5) * amount * 2.0
            return sample + tiltOffset
        }
        
        return modified
    }
    
    // Apply Symmetry
    func applySymmetry(to shape: KeyShape, amount: Float) -> KeyShape {
        var modified = shape
        let sampleCount = shape.samples.count
        
        modified.samples = shape.samples.enumerated().map { index, sample in
            let mirroredIndex = sampleCount - 1 - index
            let mirroredSample = shape.samples[mirroredIndex]
            let blended = sample * (1.0 - amount) + mirroredSample * amount
            return blended
        }
        
        return modified
    }
    
    // Apply Arc
    func applyArc(to shape: KeyShape, startPos: Float, endPos: Float, curvature: Float) -> KeyShape {
        var modified = shape
        let sampleCount = shape.samples.count
        let startIndex = Int(Float(sampleCount) * startPos)
        let endIndex = Int(Float(sampleCount) * endPos)
        
        guard startIndex < endIndex && startIndex >= 0 && endIndex < sampleCount else {
            return shape
        }
        
        let regionLength = endIndex - startIndex
        
        modified.samples = shape.samples.enumerated().map { index, sample in
            if index >= startIndex && index <= endIndex {
                // Calculate position within arc region (0.0 to 1.0)
                let t = Float(index - startIndex) / Float(regionLength)
                
                // Create arc curve (quadratic)
                let arcOffset = curvature * sin(t * Float.pi) * 0.5
                
                // Interpolate between start and end with arc
                let startValue = shape.samples[startIndex]
                let endValue = shape.samples[endIndex]
                let linearValue = startValue * (1.0 - t) + endValue * t
                
                return linearValue + arcOffset
            }
            return sample
        }
        
        return modified
    }
    
    // Apply Grit Brush (adds micro-ripples)
    func applyGritBrush(to shape: KeyShape, at position: Float, size: Float, intensity: Float) -> KeyShape {
        var modified = shape
        let sampleCount = shape.samples.count
        let brushIndex = Int(Float(sampleCount) * position)
        let brushRadius = Int(Float(sampleCount) * size)
        
        modified.samples = shape.samples.enumerated().map { index, sample in
            let distance = abs(index - brushIndex)
            if distance <= brushRadius {
                // Add controlled micro-ripples
                let weight = 1.0 - (Float(distance) / Float(brushRadius))
                let rippleFreq = Float.random(in: 20...50) // Random frequency for texture
                let ripple = sin(Float(index) * rippleFreq / Float(sampleCount) * Float.pi * 2.0)
                let rippleAmount = ripple * intensity * weight * 0.1 // Small amplitude
                return sample + rippleAmount
            }
            return sample
        }
        
        return modified
    }
    
    // Apply Smooth Brush (local smoothing)
    func applySmoothBrush(to shape: KeyShape, at position: Float, size: Float, strength: Float) -> KeyShape {
        var modified = shape
        let sampleCount = shape.samples.count
        let brushIndex = Int(Float(sampleCount) * position)
        let brushRadius = Int(Float(sampleCount) * size)
        
        modified.samples = shape.samples.enumerated().map { index, sample in
            let distance = abs(index - brushIndex)
            if distance <= brushRadius {
                // Calculate weighted average of nearby samples
                let weight = 1.0 - (Float(distance) / Float(brushRadius))
                let smoothWeight = weight * strength
                
                // Get surrounding samples for averaging
                let start = max(0, index - brushRadius)
                let end = min(sampleCount - 1, index + brushRadius)
                var sum: Float = 0.0
                var count: Float = 0.0
                
                for i in start...end {
                    let w = 1.0 - (Float(abs(i - index)) / Float(brushRadius))
                    sum += shape.samples[i] * w
                    count += w
                }
                
                let average = count > 0 ? sum / count : sample
                return sample * (1.0 - smoothWeight) + average * smoothWeight
            }
            return sample
        }
        
        return modified
    }
    
    // Apply current tool to a shape
    func applyCurrentTool(to shape: KeyShape) -> KeyShape {
        switch selectedTool {
        case .liftDrop:
            return applyLiftDrop(to: shape, amount: liftDropAmount)
        case .verticalStretch:
            return applyVerticalStretch(to: shape, amount: verticalStretchAmount)
        case .horizontalStretch:
            return applyHorizontalStretch(to: shape, amount: horizontalStretchAmount)
        case .pinch:
            return applyPinch(to: shape, position: pinchPosition, strength: pinchStrength)
        case .arc:
            return applyArc(to: shape, startPos: arcStartPosition, endPos: arcEndPosition, curvature: arcCurvature)
        case .tilt:
            return applyTilt(to: shape, amount: tiltAmount)
        case .symmetry:
            return applySymmetry(to: shape, amount: symmetryAmount)
        case .smoothBrush:
            // Smooth brush is applied interactively, not via parameters
            return shape
        case .gritBrush:
            // Grit brush is applied interactively, not via parameters
            return shape
        }
    }
}

