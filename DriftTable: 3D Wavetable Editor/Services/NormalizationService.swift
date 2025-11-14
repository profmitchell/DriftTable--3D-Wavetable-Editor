//
//  NormalizationService.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import Foundation

struct NormalizationService {
    /// Normalize a single frame to ensure it's audible and within bounds
    static func normalizeFrame(_ frame: [Float]) -> [Float] {
        guard !frame.isEmpty else { return frame }
        
        var normalized = frame
        
        // Step 1: Remove DC offset (zero crossing)
        normalized = removeDCOffset(normalized)
        
        // Step 2: Normalize amplitude to use full range without clipping
        normalized = normalizeAmplitude(normalized)
        
        // Step 3: Ensure no samples are out of bounds
        normalized = clampToBounds(normalized)
        
        return normalized
    }
    
    /// Normalize all frames in a wavetable
    static func normalizeWavetable(_ frames: [[Float]]) -> [[Float]] {
        return frames.map { normalizeFrame($0) }
    }
    
    /// Remove DC offset by centering the waveform around zero
    private static func removeDCOffset(_ frame: [Float]) -> [Float] {
        guard !frame.isEmpty else { return frame }
        
        // Calculate mean (DC offset)
        let mean = frame.reduce(0.0, +) / Float(frame.count)
        
        // Subtract mean from all samples
        return frame.map { $0 - mean }
    }
    
    /// Normalize amplitude to use full range (-1.0 to 1.0) without clipping
    private static func normalizeAmplitude(_ frame: [Float]) -> [Float] {
        guard !frame.isEmpty else { return frame }
        
        // Find peak amplitude
        let peak = frame.map { abs($0) }.max() ?? 1.0
        
        // Avoid division by zero
        guard peak > 0.0001 else {
            // If frame is essentially silent, return zeros
            return [Float](repeating: 0.0, count: frame.count)
        }
        
        // Normalize to use 95% of range to avoid clipping
        let targetPeak: Float = 0.95
        let scale = targetPeak / peak
        
        return frame.map { $0 * scale }
    }
    
    /// Clamp all samples to valid range [-1.0, 1.0]
    private static func clampToBounds(_ frame: [Float]) -> [Float] {
        return frame.map { max(-1.0, min(1.0, $0)) }
    }
    
    /// Check if a frame is essentially silent
    static func isSilent(_ frame: [Float], threshold: Float = 0.001) -> Bool {
        guard !frame.isEmpty else { return true }
        let peak = frame.map { abs($0) }.max() ?? 0.0
        return peak < threshold
    }
    
    /// Get peak amplitude of a frame
    static func peakAmplitude(_ frame: [Float]) -> Float {
        guard !frame.isEmpty else { return 0.0 }
        return frame.map { abs($0) }.max() ?? 0.0
    }
    
    /// Get RMS (Root Mean Square) amplitude
    static func rmsAmplitude(_ frame: [Float]) -> Float {
        guard frame.count > 0 else { return 0.0 }
        let sumOfSquares = frame.reduce(0.0) { $0 + $1 * $1 }
        return sqrt(sumOfSquares / Float(frame.count))
    }
}

