//
//  FlowTool.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import Foundation

enum FlowTool: String, CaseIterable, Identifiable, Codable {
    case drift = "Drift"
    case taper = "Taper"
    case wind = "Wind"
    case turbulenceNoise = "Turbulence Noise"
    case gravityWell = "Gravity Well"
    case swirl = "Swirl"
    case shear = "Shear"
    case rippleAlongFrames = "Ripple Along Frames"
    case glitchSprinkle = "Glitch Sprinkle"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .drift: return "arrow.left.and.right"
        case .taper: return "arrow.down"
        case .wind: return "wind"
        case .turbulenceNoise: return "sparkles"
        case .gravityWell: return "circle.circle"
        case .swirl: return "arrow.triangle.2.circlepath"
        case .shear: return "arrow.turn.up.right"
        case .rippleAlongFrames: return "waveform.path"
        case .glitchSprinkle: return "exclamationmark.triangle"
        }
    }
}

struct FlowToolSettings: Codable {
    var selectedTool: FlowTool = .drift
    
    // Drift settings
    var driftDirection: Bool = true // true = right, false = left
    var driftAmount: Float = 0.1
    
    // Taper settings
    var taperStartIntensity: Float = 1.0
    var taperEndIntensity: Float = 0.5
    
    // Wind settings
    var windDirection: Bool = true // true = left to right
    var windStrength: Float = 0.5
    var windFalloff: Float = 0.5
    
    // Turbulence Noise settings
    var turbulenceNoiseAmount: Float = 0.1
    var turbulenceNoiseFreqFrames: Float = 1.0
    var turbulenceNoiseFreqSamples: Float = 1.0
    
    // Gravity Well settings
    var gravityWellTargetAmplitude: Float = 0.0
    var gravityWellStrength: Float = 0.5
    
    // Swirl settings
    var swirlAmount: Float = 1.0 // radians
    var swirlCenterX: Float = 0.5
    var swirlCenterY: Float = 0.5
    
    // Shear settings
    var shearAmount: Float = 0.1
    var shearFrameInfluence: Float = 0.5
    
    // Ripple Along Frames settings
    var rippleDepth: Float = 0.2
    var ripplePeriodFrames: Float = 32.0
    var ripplePhaseOffset: Float = 0.0
    
    // Glitch Sprinkle settings
    var glitchProbabilityPerFrame: Float = 0.05
    var glitchIntensity: Float = 0.5
}

// Flow settings enum for type-safe dispatch
enum FlowSettings: Codable {
    case turbulenceNoise(TurbulenceNoiseSettings)
    case gravityWell(GravityWellSettings)
    case swirl(SwirlSettings)
    case shear(ShearSettings)
    case rippleAlongFrames(RippleAlongFramesSettings)
    case glitchSprinkle(GlitchSprinkleSettings)
    
    enum CodingKeys: String, CodingKey {
        case type
        case settings
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "turbulenceNoise":
            let s = try container.decode(TurbulenceNoiseSettings.self, forKey: .settings)
            self = .turbulenceNoise(s)
        case "gravityWell":
            let s = try container.decode(GravityWellSettings.self, forKey: .settings)
            self = .gravityWell(s)
        case "swirl":
            let s = try container.decode(SwirlSettings.self, forKey: .settings)
            self = .swirl(s)
        case "shear":
            let s = try container.decode(ShearSettings.self, forKey: .settings)
            self = .shear(s)
        case "rippleAlongFrames":
            let s = try container.decode(RippleAlongFramesSettings.self, forKey: .settings)
            self = .rippleAlongFrames(s)
        case "glitchSprinkle":
            let s = try container.decode(GlitchSprinkleSettings.self, forKey: .settings)
            self = .glitchSprinkle(s)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown flow settings type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .turbulenceNoise(let s):
            try container.encode("turbulenceNoise", forKey: .type)
            try container.encode(s, forKey: .settings)
        case .gravityWell(let s):
            try container.encode("gravityWell", forKey: .type)
            try container.encode(s, forKey: .settings)
        case .swirl(let s):
            try container.encode("swirl", forKey: .type)
            try container.encode(s, forKey: .settings)
        case .shear(let s):
            try container.encode("shear", forKey: .type)
            try container.encode(s, forKey: .settings)
        case .rippleAlongFrames(let s):
            try container.encode("rippleAlongFrames", forKey: .type)
            try container.encode(s, forKey: .settings)
        case .glitchSprinkle(let s):
            try container.encode("glitchSprinkle", forKey: .type)
            try container.encode(s, forKey: .settings)
        }
    }
}

struct TurbulenceNoiseSettings: Codable {
    var noiseAmount: Float = 0.1
    var noiseFreqFrames: Float = 1.0
    var noiseFreqSamples: Float = 1.0
}

struct GravityWellSettings: Codable {
    var targetAmplitude: Float = 0.0
    var strength: Float = 0.5
}

struct SwirlSettings: Codable {
    var swirlAmount: Float = 1.0
    var centerX: Float = 0.5
    var centerY: Float = 0.5
}

struct ShearSettings: Codable {
    var shearAmount: Float = 0.1
    var frameInfluence: Float = 0.5
}

struct RippleAlongFramesSettings: Codable {
    var rippleDepth: Float = 0.2
    var ripplePeriodFrames: Float = 32.0
    var phaseOffset: Float = 0.0
}

struct GlitchSprinkleSettings: Codable {
    var probabilityPerFrame: Float = 0.05
    var glitchIntensity: Float = 0.5
}

struct FrameGradient: Codable {
    var points: [CGPoint] // Normalized points (x: 0-1 frame index, y: 0-1 strength)
    
    init() {
        // Default linear gradient
        points = [
            CGPoint(x: 0.0, y: 1.0),
            CGPoint(x: 1.0, y: 1.0)
        ]
    }
    
    func strength(at frameIndex: Int, totalFrames: Int) -> Float {
        guard totalFrames > 0 else { return 1.0 }
        let normalizedX = Float(frameIndex) / Float(totalFrames - 1)
        
        // Find surrounding points
        guard let firstPoint = points.first, let lastPoint = points.last else { return 1.0 }
        
        if normalizedX <= 0 { return Float(firstPoint.y) }
        if normalizedX >= 1.0 { return Float(lastPoint.y) }
        
        // Simple linear interpolation between points
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            
            if normalizedX >= Float(p1.x) && normalizedX <= Float(p2.x) {
                let t = (normalizedX - Float(p1.x)) / (Float(p2.x) - Float(p1.x))
                return Float(p1.y) * (1.0 - t) + Float(p2.y) * t
            }
        }
        
        return 1.0
    }
}

// CGPoint already conforms to Codable in CoreGraphics, no extension needed

