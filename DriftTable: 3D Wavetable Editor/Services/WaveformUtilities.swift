//
//  WaveformUtilities.swift
//  DriftTable: 3D Wavetable Editor
//
//  Created by Codex on 11/12/25.
//

import Foundation

enum WaveformUtilities {
    static func removeDC(from samples: [Float]) -> [Float] {
        guard !samples.isEmpty else { return samples }
        let mean = samples.reduce(0, +) / Float(samples.count)
        return samples.map { $0 - mean }
    }
    
    static func lockEndpoints(_ samples: [Float]) -> [Float] {
        guard samples.count > 1 else { return samples }
        let start = samples[0]
        let end = samples[samples.count - 1]
        let delta = end - start
        let countMinusOne = Float(samples.count - 1)
        return samples.enumerated().map { index, sample in
            let t = Float(index) / countMinusOne
            let correction = start + delta * t
            return sample - correction
        }
    }
    
    static func normalize(_ samples: [Float], targetPeak: Float = 0.99) -> [Float] {
        guard let maxSample = samples.map({ abs($0) }).max(), maxSample > 0 else {
            return samples
        }
        let scale = targetPeak / maxSample
        return samples.map { $0 * scale }
    }
    
    static func sanitize(_ samples: [Float], targetPeak: Float = 0.99) -> [Float] {
        let dcFree = removeDC(from: samples)
        let clamped = lockEndpoints(dcFree)
        return normalize(clamped, targetPeak: targetPeak)
    }
    
    static func bendWarp(samples: [Float], amount: Float) -> [Float] {
        guard samples.count > 1 else { return samples }
        let lastIndex = samples.count - 1
        return (0..<samples.count).map { i in
            let phase = Float(i) / Float(lastIndex)
            let warpedPhase = bendPhase(phase, amount: amount)
            let sampleIndex = warpedPhase * Float(lastIndex)
            let index0 = max(0, min(lastIndex, Int(floor(sampleIndex))))
            let index1 = min(lastIndex, index0 + 1)
            let t = sampleIndex - Float(index0)
            let value0 = samples[index0]
            let value1 = samples[index1]
            return value0 + (value1 - value0) * t
        }
    }
    
    private static func bendPhase(_ phase: Float, amount: Float) -> Float {
        let clamped = max(-0.99, min(0.99, amount))
        if clamped >= 0 {
            let exponent = 1 + clamped * 2
            return pow(phase, exponent)
        } else {
            let exponent = 1 + abs(clamped) * 2
            return 1 - pow(1 - phase, exponent)
        }
    }
}
