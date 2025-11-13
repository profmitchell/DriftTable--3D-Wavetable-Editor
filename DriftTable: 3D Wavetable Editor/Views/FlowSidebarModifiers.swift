//
//  FlowSidebarModifiers.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import SwiftUI

extension View {
    /// Applies onChange handlers for all flow tool settings
    func flowToolChangeHandlers(
        flowViewModel: FlowViewModel,
        projectViewModel: ProjectViewModel,
        applyFlowTool: @escaping () -> Void
    ) -> some View {
        self
            .flowToolChangeHandlersPart1(flowViewModel: flowViewModel, applyFlowTool: applyFlowTool)
            .flowToolChangeHandlersPart2(flowViewModel: flowViewModel, applyFlowTool: applyFlowTool)
            .flowToolChangeHandlersPart3(flowViewModel: flowViewModel, applyFlowTool: applyFlowTool)
    }
    
    private func flowToolChangeHandlersPart1(
        flowViewModel: FlowViewModel,
        applyFlowTool: @escaping () -> Void
    ) -> some View {
        self
            .onChange(of: flowViewModel.settings.selectedTool) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.driftDirection) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.driftAmount) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.taperStartIntensity) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.taperEndIntensity) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.windDirection) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.windStrength) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.windFalloff) { _, _ in applyFlowTool() }
    }
    
    private func flowToolChangeHandlersPart2(
        flowViewModel: FlowViewModel,
        applyFlowTool: @escaping () -> Void
    ) -> some View {
        self
            .onChange(of: flowViewModel.settings.turbulenceNoiseAmount) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.turbulenceNoiseFreqFrames) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.turbulenceNoiseFreqSamples) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.gravityWellTargetAmplitude) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.gravityWellStrength) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.swirlAmount) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.swirlCenterX) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.swirlCenterY) { _, _ in applyFlowTool() }
    }
    
    private func flowToolChangeHandlersPart3(
        flowViewModel: FlowViewModel,
        applyFlowTool: @escaping () -> Void
    ) -> some View {
        self
            .onChange(of: flowViewModel.settings.shearAmount) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.shearFrameInfluence) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.rippleDepth) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.ripplePeriodFrames) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.ripplePhaseOffset) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.glitchProbabilityPerFrame) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.glitchIntensity) { _, _ in applyFlowTool() }
    }
}

