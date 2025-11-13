//
//  WavetableProject.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import Foundation

struct WavetableProject: Codable {
    var name: String
    var sampleRate: Double
    var frameCount: Int
    var samplesPerFrame: Int
    var keyShapes: [KeyShape]
    var morphSettings: MorphSettings
    var generatedFrames: [[Float]] // Full wavetable frames
    
    init(name: String = "Untitled Project",
         sampleRate: Double = 44100.0,
         frameCount: Int = 256,
         samplesPerFrame: Int = 2048,
         keyShapes: [KeyShape] = [],
         morphSettings: MorphSettings = MorphSettings(),
         generatedFrames: [[Float]] = []) {
        self.name = name
        self.sampleRate = sampleRate
        self.frameCount = frameCount
        self.samplesPerFrame = samplesPerFrame
        self.keyShapes = keyShapes
        self.morphSettings = morphSettings
        self.generatedFrames = generatedFrames
    }
    
    /// Create a default project with a sine wave key shape
    static func defaultProject() -> WavetableProject {
        var project = WavetableProject()
        project.keyShapes = [KeyShape.sine(id: "A")]
        return project
    }
}

