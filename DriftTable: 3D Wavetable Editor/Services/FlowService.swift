//
//  FlowService.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import Foundation

struct FlowService {
    // MARK: - Noise Utility
    
    /// Simple deterministic coherent noise function for turbulence effects
    /// Returns a value in [-1, 1] that is smooth and coherent
    static func smoothNoise2D(x: Float, y: Float, seed: UInt64) -> Float {
        // Use a hash-based approach with bilinear interpolation
        let gridX0 = Int(floor(x))
        let gridX1 = gridX0 + 1
        let gridY0 = Int(floor(y))
        let gridY1 = gridY0 + 1
        
        // Get fractional parts for interpolation
        let fx = x - Float(gridX0)
        let fy = y - Float(gridY0)
        
        // Smooth interpolation function (smoothstep)
        let smoothFx = fx * fx * (3.0 - 2.0 * fx)
        let smoothFy = fy * fy * (3.0 - 2.0 * fy)
        
        // Hash function for grid points
        func hash(_ x: Int, _ y: Int) -> Float {
            var hash = UInt64(x) &* 73856093 &+ UInt64(y) &* 19349663 &+ seed
            hash = (hash << 13) ^ hash
            hash = hash &* (hash &* hash &* 15731 &+ 789221) &+ 1376312589
            // Mask to 31 bits before conversion to avoid overflow
            let maskedHash = hash & 0x7FFFFFFF
            return Float(maskedHash) / Float(0x7FFFFFFF) * 2.0 - 1.0
        }
        
        // Get noise values at grid corners
        let n00 = hash(gridX0, gridY0)
        let n10 = hash(gridX1, gridY0)
        let n01 = hash(gridX0, gridY1)
        let n11 = hash(gridX1, gridY1)
        
        // Bilinear interpolation
        let nx0 = n00 * (1.0 - smoothFx) + n10 * smoothFx
        let nx1 = n01 * (1.0 - smoothFx) + n11 * smoothFx
        let result = nx0 * (1.0 - smoothFy) + nx1 * smoothFy
        
        return result
    }
    /// Apply flow tools to wavetable frames
    static func applyFlow(to frames: [[Float]], tool: FlowTool, settings: FlowToolSettings, gradient: FrameGradient, seed: UInt64 = 12345) -> [[Float]] {
        guard !frames.isEmpty else { return frames }
        
        var modifiedFrames = frames
        
        switch tool {
        case .drift, .taper, .wind:
            // Existing tools
            for (frameIndex, frame) in frames.enumerated() {
                let strength = gradient.strength(at: frameIndex, totalFrames: frames.count)
                
                switch tool {
                case .drift:
                    modifiedFrames[frameIndex] = applyDrift(
                        to: frame,
                        direction: settings.driftDirection,
                        amount: settings.driftAmount * Float(strength)
                    )
                case .taper:
                    modifiedFrames[frameIndex] = applyTaper(
                        to: frame,
                        startIntensity: settings.taperStartIntensity,
                        endIntensity: settings.taperEndIntensity,
                        frameIndex: frameIndex,
                        totalFrames: frames.count,
                        gradientStrength: Float(strength)
                    )
                case .wind:
                    modifiedFrames[frameIndex] = applyWind(
                        to: frame,
                        direction: settings.windDirection,
                        strength: settings.windStrength * Float(strength),
                        falloff: settings.windFalloff,
                        frameIndex: frameIndex,
                        totalFrames: frames.count
                    )
                default:
                    break
                }
            }
            
        case .turbulenceNoise:
            let turbulenceSettings = TurbulenceNoiseSettings(
                noiseAmount: settings.turbulenceNoiseAmount,
                noiseFreqFrames: settings.turbulenceNoiseFreqFrames,
                noiseFreqSamples: settings.turbulenceNoiseFreqSamples
            )
            applyTurbulenceNoise(frames: &modifiedFrames, gradient: gradient, settings: turbulenceSettings, seed: seed)
            
        case .gravityWell:
            let gravitySettings = GravityWellSettings(
                targetAmplitude: settings.gravityWellTargetAmplitude,
                strength: settings.gravityWellStrength
            )
            applyGravityWell(frames: &modifiedFrames, gradient: gradient, settings: gravitySettings)
            
        case .swirl:
            let swirlSettings = SwirlSettings(
                swirlAmount: settings.swirlAmount,
                centerX: settings.swirlCenterX,
                centerY: settings.swirlCenterY
            )
            applySwirl(frames: &modifiedFrames, gradient: gradient, settings: swirlSettings)
            
        case .shear:
            let shearSettings = ShearSettings(
                shearAmount: settings.shearAmount,
                frameInfluence: settings.shearFrameInfluence
            )
            applyShear(frames: &modifiedFrames, gradient: gradient, settings: shearSettings)
            
        case .rippleAlongFrames:
            let rippleSettings = RippleAlongFramesSettings(
                rippleDepth: settings.rippleDepth,
                ripplePeriodFrames: settings.ripplePeriodFrames,
                phaseOffset: settings.ripplePhaseOffset
            )
            applyRippleAlongFrames(frames: &modifiedFrames, gradient: gradient, settings: rippleSettings)
            
        case .glitchSprinkle:
            let glitchSettings = GlitchSprinkleSettings(
                probabilityPerFrame: settings.glitchProbabilityPerFrame,
                glitchIntensity: settings.glitchIntensity
            )
            applyGlitchSprinkle(frames: &modifiedFrames, gradient: gradient, settings: glitchSettings, seed: seed)
        }
        
        return modifiedFrames
    }
    
    private static func applyDrift(to samples: [Float], direction: Bool, amount: Float) -> [Float] {
        guard !samples.isEmpty else { return samples }
        var modified = samples
        
        // Much more powerful - up to 50% shift, can go up to 2x for even more dramatic effect
        let effectiveAmount = min(amount, 2.0) // Allow up to 2x for extreme effects
        let shift = Int(effectiveAmount * Float(samples.count) * 0.25) // 25% per unit, so 2.0 = 50%
        if shift == 0 { return samples }
        
        if direction {
            // Shift right
            for i in 0..<samples.count {
                let sourceIndex = (i - shift + samples.count) % samples.count
                modified[i] = samples[sourceIndex]
            }
        } else {
            // Shift left
            for i in 0..<samples.count {
                let sourceIndex = (i + shift) % samples.count
                modified[i] = samples[sourceIndex]
            }
        }
        
        return modified
    }
    
    private static func applyTaper(to samples: [Float], startIntensity: Float, endIntensity: Float, frameIndex: Int, totalFrames: Int, gradientStrength: Float) -> [Float] {
        let t = Float(frameIndex) / Float(max(totalFrames - 1, 1))
        // More powerful taper - can go from 0 to 3x intensity
        let intensity = startIntensity * (1.0 - t) + endIntensity * t
        return samples.map { $0 * intensity * gradientStrength }
    }
    
    private static func applyWind(to samples: [Float], direction: Bool, strength: Float, falloff: Float, frameIndex: Int, totalFrames: Int) -> [Float] {
        guard !samples.isEmpty else { return samples }
        var modified = samples
        
        let normalizedPos = Float(frameIndex) / Float(max(totalFrames - 1, 1))
        // Much more powerful wind effect - can go up to 2x strength
        let effectiveStrength = min(strength, 2.0) // Allow up to 2x
        let windEffect = effectiveStrength * (1.0 - normalizedPos * falloff) * 1.5 // 1.5x multiplier
        
        let sampleCount = samples.count
        // Up to 45% shift - much more dramatic (30% base * 1.5 multiplier)
        let shiftAmount = Int(windEffect * Float(sampleCount) * 0.3)
        
        // Apply smooth interpolation for better results
        if direction {
            // Wind left to right - push samples right with interpolation
            for i in 0..<sampleCount {
                let targetIndex = Float(i) - Float(shiftAmount) * (Float(i) / Float(sampleCount))
                let sourceIndex0 = max(0, min(sampleCount - 1, Int(floor(targetIndex))))
                let sourceIndex1 = max(0, min(sampleCount - 1, sourceIndex0 + 1))
                let t = targetIndex - Float(sourceIndex0)
                
                if sourceIndex0 >= 0 && sourceIndex0 < sampleCount && sourceIndex1 < sampleCount {
                    modified[i] = samples[sourceIndex0] * (1.0 - t) + samples[sourceIndex1] * t
                } else {
                    modified[i] = samples[i]
                }
            }
        } else {
            // Wind right to left - push samples left with interpolation
            for i in 0..<sampleCount {
                let targetIndex = Float(i) + Float(shiftAmount) * (1.0 - Float(i) / Float(sampleCount))
                let sourceIndex0 = max(0, min(sampleCount - 1, Int(floor(targetIndex))))
                let sourceIndex1 = max(0, min(sampleCount - 1, sourceIndex0 + 1))
                let t = targetIndex - Float(sourceIndex0)
                
                if sourceIndex0 >= 0 && sourceIndex0 < sampleCount && sourceIndex1 < sampleCount {
                    modified[i] = samples[sourceIndex0] * (1.0 - t) + samples[sourceIndex1] * t
                } else {
                    modified[i] = samples[i]
                }
            }
        }
        
        return modified
    }
    
    // MARK: - New Flow Modes
    
    /// Apply turbulence noise - adds gentle coherent noise distortion
    private static func applyTurbulenceNoise(frames: inout [[Float]], gradient: FrameGradient, settings: TurbulenceNoiseSettings, seed: UInt64) {
        guard !frames.isEmpty else { return }
        let totalFrames = frames.count
        let sampleCount = frames[0].count
        
        for frameIndex in 0..<totalFrames {
            let frameNorm = Float(frameIndex) / Float(max(totalFrames - 1, 1))
            let frameStrength = gradient.strength(at: frameIndex, totalFrames: totalFrames)
            
            for sampleIndex in 0..<sampleCount {
                let baseSample = frames[frameIndex][sampleIndex]
                let sampleNorm = Float(sampleIndex) / Float(max(sampleCount - 1, 1))
                
                // Compute noise at this position
                let noise = smoothNoise2D(
                    x: frameNorm * settings.noiseFreqFrames,
                    y: sampleNorm * settings.noiseFreqSamples,
                    seed: seed
                )
                
                // Apply noise with frame gradient strength
                let delta = noise * settings.noiseAmount * frameStrength
                let newSample = baseSample + delta
                
                // Clamp to [-1, 1]
                frames[frameIndex][sampleIndex] = max(-1.0, min(1.0, newSample))
            }
        }
    }
    
    /// Apply gravity well - pulls amplitudes toward a target level
    private static func applyGravityWell(frames: inout [[Float]], gradient: FrameGradient, settings: GravityWellSettings) {
        guard !frames.isEmpty else { return }
        let totalFrames = frames.count
        
        for frameIndex in 0..<totalFrames {
            let frameStrength = gradient.strength(at: frameIndex, totalFrames: totalFrames)
            
            for sampleIndex in 0..<frames[frameIndex].count {
                let baseSample = frames[frameIndex][sampleIndex]
                
                // Blend strength increases with distance from target
                let distance = abs(baseSample - settings.targetAmplitude)
                let adaptiveStrength = settings.strength * (1.0 + distance * 0.5) // Stronger pull on far-away points
                let t = adaptiveStrength * frameStrength
                
                // Interpolate toward target
                let newSample = (1.0 - t) * baseSample + t * settings.targetAmplitude
                frames[frameIndex][sampleIndex] = max(-1.0, min(1.0, newSample))
            }
        }
    }
    
    /// Apply swirl - rotates waveform around a center point
    private static func applySwirl(frames: inout [[Float]], gradient: FrameGradient, settings: SwirlSettings) {
        guard !frames.isEmpty else { return }
        let totalFrames = frames.count
        let sampleCount = frames[0].count
        
        // Map centerY from [0,1] to [-1,1]
        let centerYMapped = (settings.centerY - 0.5) * 2.0
        
        for frameIndex in 0..<totalFrames {
            let frameNorm = Float(frameIndex) / Float(max(totalFrames - 1, 1))
            let frameStrength = gradient.strength(at: frameIndex, totalFrames: totalFrames)
            
            // Calculate rotation angle for this frame
            let angle = settings.swirlAmount * frameNorm * frameStrength
            
            // Create a temporary copy for reading
            let originalFrame = frames[frameIndex]
            var newFrame = [Float](repeating: 0.0, count: sampleCount)
            
            for i in 0..<sampleCount {
                let xNorm = Float(i) / Float(max(sampleCount - 1, 1))
                let y = originalFrame[i]
                
                // Translate to swirl center
                let px = xNorm - settings.centerX
                let py = y - centerYMapped
                
                // Convert to polar coordinates
                let r = sqrt(px * px + py * py)
                let theta = atan2(py, px)
                
                // Apply rotation
                let thetaNew = theta + angle
                
                // Convert back to Cartesian
                let pxNew = r * cos(thetaNew)
                let pyNew = r * sin(thetaNew)
                
                // Translate back
                let xNormNew = pxNew + settings.centerX
                let yNew = pyNew + centerYMapped
                
                // Sample original waveform at new x position (with linear interpolation)
                let sourceIndex = xNormNew * Float(sampleCount - 1)
                let index0 = max(0, min(sampleCount - 1, Int(floor(sourceIndex))))
                let index1 = max(0, min(sampleCount - 1, index0 + 1))
                let t = sourceIndex - Float(index0)
                
                let sampledValue = originalFrame[index0] * (1.0 - t) + originalFrame[index1] * t
                
                // Blend between sampled value and rotated y value
                newFrame[i] = max(-1.0, min(1.0, sampledValue * 0.5 + yNew * 0.5))
            }
            
            frames[frameIndex] = newFrame
        }
    }
    
    /// Apply shear - tilts waveforms horizontally based on amplitude
    private static func applyShear(frames: inout [[Float]], gradient: FrameGradient, settings: ShearSettings) {
        guard !frames.isEmpty else { return }
        let totalFrames = frames.count
        let sampleCount = frames[0].count
        
        for frameIndex in 0..<totalFrames {
            let frameNorm = Float(frameIndex) / Float(max(totalFrames - 1, 1))
            let frameStrength = gradient.strength(at: frameIndex, totalFrames: totalFrames)
            
            let originalFrame = frames[frameIndex]
            var newFrame = [Float](repeating: 0.0, count: sampleCount)
            
            for i in 0..<sampleCount {
                let baseSample = originalFrame[i]
                let amp = baseSample
                
                // Calculate offset based on amplitude and frame influence
                let frameFactor = settings.frameInfluence * frameNorm + (1.0 - settings.frameInfluence)
                let offsetSamples = settings.shearAmount * amp * frameFactor * Float(sampleCount) * frameStrength
                
                // Calculate new index with linear interpolation
                let newIndex = Float(i) + offsetSamples
                let clampedIndex = max(0.0, min(Float(sampleCount - 1), newIndex))
                
                let index0 = Int(floor(clampedIndex))
                let index1 = min(index0 + 1, sampleCount - 1)
                let t = clampedIndex - Float(index0)
                
                newFrame[i] = originalFrame[index0] * (1.0 - t) + originalFrame[index1] * t
            }
            
            frames[frameIndex] = newFrame
        }
    }
    
    /// Apply ripple along frames - makes amplitude "breathe" along frame axis
    private static func applyRippleAlongFrames(frames: inout [[Float]], gradient: FrameGradient, settings: RippleAlongFramesSettings) {
        guard !frames.isEmpty else { return }
        let totalFrames = frames.count
        
        for frameIndex in 0..<totalFrames {
            let frameNorm = Float(frameIndex) / Float(totalFrames)
            
            // Calculate phase for this frame
            let phase = (2.0 * Float.pi * frameNorm * Float(totalFrames) / settings.ripplePeriodFrames) + settings.phaseOffset
            let scale = 1.0 + settings.rippleDepth * sin(phase)
            
            let frameStrength = gradient.strength(at: frameIndex, totalFrames: totalFrames)
            let finalScale = 1.0 + (scale - 1.0) * frameStrength
            
            // Apply scale to all samples in frame
            for sampleIndex in 0..<frames[frameIndex].count {
                let newSample = frames[frameIndex][sampleIndex] * finalScale
                frames[frameIndex][sampleIndex] = max(-1.0, min(1.0, newSample))
            }
        }
    }
    
    /// Apply glitch sprinkle - occasionally applies strong distortions to frames
    private static func applyGlitchSprinkle(frames: inout [[Float]], gradient: FrameGradient, settings: GlitchSprinkleSettings, seed: UInt64) {
        guard !frames.isEmpty else { return }
        let totalFrames = frames.count
        
        // Simple seeded RNG for determinism
        var rngState = seed
        
        func nextRandom() -> Float {
            rngState = rngState &* 1103515245 &+ 12345
            // Mask to 31 bits before conversion to avoid overflow
            let maskedState = rngState & 0x7FFFFFFF
            return Float(maskedState) / Float(0x7FFFFFFF)
        }
        
        for frameIndex in 0..<totalFrames {
            let frameStrength = gradient.strength(at: frameIndex, totalFrames: totalFrames)
            let r = nextRandom()
            
            // Check if this frame should be glitched
            if r < settings.probabilityPerFrame * frameStrength {
                let sampleCount = frames[frameIndex].count
                let originalFrame = frames[frameIndex]
                
                // Apply glitch distortion
                for i in 0..<sampleCount {
                    // Random jitter offset
                    let jitterRange = Int(settings.glitchIntensity * Float(sampleCount) * 0.1)
                    let jitter = Int(nextRandom() * Float(jitterRange * 2) - Float(jitterRange))
                    let sourceIndex = max(0, min(sampleCount - 1, i + jitter))
                    
                    let baseSample = originalFrame[sourceIndex]
                    
                    // Apply nonlinear distortion (tanh fold)
                    let distortionFactor = 1.0 + settings.glitchIntensity * 4.0
                    let newSample = tanh(baseSample * distortionFactor)
                    
                    frames[frameIndex][i] = max(-1.0, min(1.0, newSample))
                }
            }
        }
    }
}

