//
//  FlowToolChangeModifier.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import SwiftUI

struct FlowToolChangeModifier: ViewModifier {
    @ObservedObject var flowViewModel: FlowViewModel
    @ObservedObject var projectViewModel: ProjectViewModel
    
    func body(content: Content) -> some View {
        content
            .modifier(FlowToolChangePart1(flowViewModel: flowViewModel, projectViewModel: projectViewModel))
            .modifier(FlowToolChangePart2(flowViewModel: flowViewModel, projectViewModel: projectViewModel))
            .modifier(FlowToolChangePart3(flowViewModel: flowViewModel, projectViewModel: projectViewModel))
    }
}

struct FlowToolChangePart1: ViewModifier {
    @ObservedObject var flowViewModel: FlowViewModel
    @ObservedObject var projectViewModel: ProjectViewModel
    
    func body(content: Content) -> some View {
        content
            .onChange(of: flowViewModel.settings.selectedTool) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.driftDirection) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.driftAmount) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.taperStartIntensity) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.taperEndIntensity) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.windDirection) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.windStrength) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.windFalloff) { _, _ in applyFlowTool() }
    }
    
    private func applyFlowTool() {
        guard !projectViewModel.project.generatedFrames.isEmpty else { return }
        projectViewModel.applyFlowTool(
            flowViewModel.settings.selectedTool,
            settings: flowViewModel.settings,
            gradient: flowViewModel.gradient,
            saveToHistory: false
        )
    }
}

struct FlowToolChangePart2: ViewModifier {
    @ObservedObject var flowViewModel: FlowViewModel
    @ObservedObject var projectViewModel: ProjectViewModel
    
    func body(content: Content) -> some View {
        content
            .onChange(of: flowViewModel.settings.turbulenceNoiseAmount) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.turbulenceNoiseFreqFrames) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.turbulenceNoiseFreqSamples) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.gravityWellTargetAmplitude) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.gravityWellStrength) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.swirlAmount) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.swirlCenterX) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.swirlCenterY) { _, _ in applyFlowTool() }
    }
    
    private func applyFlowTool() {
        guard !projectViewModel.project.generatedFrames.isEmpty else { return }
        projectViewModel.applyFlowTool(
            flowViewModel.settings.selectedTool,
            settings: flowViewModel.settings,
            gradient: flowViewModel.gradient,
            saveToHistory: false
        )
    }
}

struct FlowToolChangePart3: ViewModifier {
    @ObservedObject var flowViewModel: FlowViewModel
    @ObservedObject var projectViewModel: ProjectViewModel
    
    func body(content: Content) -> some View {
        content
            .onChange(of: flowViewModel.settings.shearAmount) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.shearFrameInfluence) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.rippleDepth) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.ripplePeriodFrames) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.ripplePhaseOffset) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.glitchProbabilityPerFrame) { _, _ in applyFlowTool() }
            .onChange(of: flowViewModel.settings.glitchIntensity) { _, _ in applyFlowTool() }
    }
    
    private func applyFlowTool() {
        guard !projectViewModel.project.generatedFrames.isEmpty else { return }
        projectViewModel.applyFlowTool(
            flowViewModel.settings.selectedTool,
            settings: flowViewModel.settings,
            gradient: flowViewModel.gradient,
            saveToHistory: false
        )
    }
}

