//
//  MorphSettings.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import Foundation

enum MorphStyle: String, Codable, CaseIterable {
    case direct = "Direct"
    case soft = "Soft"
    case punchy = "Punchy"
    case stepped = "Stepped"
    case organic = "Organic"
}

struct MorphSettings: Codable {
    var frameCount: Int = 256
    var morphStyle: MorphStyle = .direct
    
    static let frameCountOptions = [64, 128, 256]
}

