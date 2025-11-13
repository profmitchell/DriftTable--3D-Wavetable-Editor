//
//  FlowViewModel.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import Foundation
import SwiftUI
import Combine

class FlowViewModel: ObservableObject {
    @Published var settings = FlowToolSettings()
    @Published var gradient = FrameGradient()
    
    func applyToProject(_ projectViewModel: ProjectViewModel) {
        // Manual apply saves to history
        projectViewModel.applyFlowTool(settings.selectedTool, settings: settings, gradient: gradient, saveToHistory: true)
    }
}

