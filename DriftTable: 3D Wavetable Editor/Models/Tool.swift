//
//  Tool.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import Foundation

enum Tool: String, CaseIterable, Identifiable {
    case liftDrop = "Lift / Drop"
    case verticalStretch = "Vertical Stretch"
    case horizontalStretch = "Horizontal Stretch"
    case pinch = "Pinch"
    case arc = "Arc"
    case tilt = "Tilt"
    case symmetry = "Symmetry"
    case smoothBrush = "Smooth Brush"
    case gritBrush = "Grit Brush"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .liftDrop: return "arrow.up.and.down"
        case .verticalStretch: return "arrow.up.and.down.circle"
        case .horizontalStretch: return "arrow.left.and.right"
        case .pinch: return "hand.pinch"
        case .arc: return "waveform.path"
        case .tilt: return "arrow.turn.up.right"
        case .symmetry: return "arrow.triangle.2.circlepath"
        case .smoothBrush: return "paintbrush"
        case .gritBrush: return "sparkles"
        }
    }
}

