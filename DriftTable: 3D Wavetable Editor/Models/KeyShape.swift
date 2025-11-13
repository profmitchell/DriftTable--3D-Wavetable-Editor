//
//  KeyShape.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import Foundation

struct KeyShape: Identifiable, Codable {
    let id: String // e.g. "A", "B", "C"
    var samples: [Float] // One cycle of waveform samples (e.g. 2048 samples)
    
    init(id: String, samples: [Float]) {
        self.id = id
        self.samples = samples
    }
    
    /// Create a KeyShape with a sine wave
    static func sine(id: String, sampleCount: Int = 2048) -> KeyShape {
        let samples = (0..<sampleCount).map { i in
            sin(Float(i) * 2.0 * Float.pi / Float(sampleCount))
        }
        return KeyShape(id: id, samples: samples)
    }
    
    /// Create a KeyShape with a sawtooth wave
    static func sawtooth(id: String, sampleCount: Int = 2048) -> KeyShape {
        let samples = (0..<sampleCount).map { i in
            (Float(i) / Float(sampleCount)) * 2.0 - 1.0
        }
        return KeyShape(id: id, samples: samples)
    }
    
    /// Create a KeyShape with a triangle wave
    static func triangle(id: String, sampleCount: Int = 2048) -> KeyShape {
        let samples = (0..<sampleCount).map { i in
            let phase = Float(i) / Float(sampleCount)
            if phase < 0.5 {
                return phase * 4.0 - 1.0
            } else {
                return 3.0 - phase * 4.0
            }
        }
        return KeyShape(id: id, samples: samples)
    }
    
    /// Create a KeyShape with a square wave
    static func square(id: String, sampleCount: Int = 2048) -> KeyShape {
        let samples = (0..<sampleCount).map { i in
            (Float(i) / Float(sampleCount)) < 0.5 ? Float(1.0) : Float(-1.0)
        }
        return KeyShape(id: id, samples: samples)
    }
}

