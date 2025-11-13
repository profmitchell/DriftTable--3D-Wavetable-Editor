//
//  FlowSidebarView.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import SwiftUI

struct FlowSidebarView: View {
    @ObservedObject var flowViewModel: FlowViewModel
    @ObservedObject var projectViewModel: ProjectViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Flow Tools")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Tool selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tool")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        // Use menu picker instead of segmented for 3+ options
                        Picker("", selection: $flowViewModel.settings.selectedTool) {
                            ForEach(FlowTool.allCases) { tool in
                                HStack {
                                    Image(systemName: tool.icon)
                                    Text(tool.rawValue)
                                }
                                .tag(tool)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Tool-specific parameters
                    toolParametersView
                    
                    Divider()
                    
                    // Apply button (manual apply - real-time happens automatically)
                    Button(action: {
                        flowViewModel.applyToProject(projectViewModel)
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Apply Flow")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    .disabled(projectViewModel.project.generatedFrames.isEmpty)
                    .help("Manually apply flow tool (auto-applied in real-time)")
                }
            }
            
            Spacer()
        }
        .frame(minWidth: 200, idealWidth: 250)
        .modifier(FlowToolChangeModifier(
            flowViewModel: flowViewModel,
            projectViewModel: projectViewModel
        ))
    }
    
    @ViewBuilder
    private var toolParametersView: some View {
        switch flowViewModel.settings.selectedTool {
        case .drift:
            driftParameters
        case .taper:
            taperParameters
        case .wind:
            windParameters
        case .turbulenceNoise:
            turbulenceNoiseParameters
        case .gravityWell:
            gravityWellParameters
        case .swirl:
            swirlParameters
        case .shear:
            shearParameters
        case .rippleAlongFrames:
            rippleAlongFramesParameters
        case .glitchSprinkle:
            glitchSprinkleParameters
        }
    }
    
    private var driftParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Direction")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Picker("", selection: $flowViewModel.settings.driftDirection) {
                Text("Left").tag(false)
                Text("Right").tag(true)
            }
            .pickerStyle(.segmented)
            
            Text("Amount")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.driftAmount, in: 0.0...2.0)
            Text(String(format: "%.2f", flowViewModel.settings.driftAmount))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    private var taperParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Start Intensity")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.taperStartIntensity, in: 0.0...2.0)
            
            Text("End Intensity")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.taperEndIntensity, in: 0.0...2.0)
        }
        .padding(.horizontal)
    }
    
    private var windParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Direction")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Picker("", selection: $flowViewModel.settings.windDirection) {
                Text("Right to Left").tag(false)
                Text("Left to Right").tag(true)
            }
            .pickerStyle(.segmented)
            
            Text("Strength")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.windStrength, in: 0.0...2.0)
            Text(String(format: "%.2f", flowViewModel.settings.windStrength))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Falloff")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.windFalloff, in: 0.0...1.0)
            Text(String(format: "%.2f", flowViewModel.settings.windFalloff))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    private var turbulenceNoiseParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Noise Amount")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.turbulenceNoiseAmount, in: 0.0...0.2)
            Text(String(format: "%.3f", flowViewModel.settings.turbulenceNoiseAmount))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Frame Frequency")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.turbulenceNoiseFreqFrames, in: 0.1...5.0)
            Text(String(format: "%.2f", flowViewModel.settings.turbulenceNoiseFreqFrames))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Sample Frequency")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.turbulenceNoiseFreqSamples, in: 0.1...5.0)
            Text(String(format: "%.2f", flowViewModel.settings.turbulenceNoiseFreqSamples))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    private var gravityWellParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Target Amplitude")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.gravityWellTargetAmplitude, in: -1.0...1.0)
            Text(String(format: "%.2f", flowViewModel.settings.gravityWellTargetAmplitude))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Strength")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.gravityWellStrength, in: 0.0...1.0)
            Text(String(format: "%.2f", flowViewModel.settings.gravityWellStrength))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    private var swirlParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Swirl Amount")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.swirlAmount, in: -3.14...3.14)
            Text(String(format: "%.2f rad", flowViewModel.settings.swirlAmount))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Center X")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.swirlCenterX, in: 0.0...1.0)
            Text(String(format: "%.2f", flowViewModel.settings.swirlCenterX))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Center Y")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.swirlCenterY, in: 0.0...1.0)
            Text(String(format: "%.2f", flowViewModel.settings.swirlCenterY))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    private var shearParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shear Amount")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.shearAmount, in: -0.5...0.5)
            Text(String(format: "%.2f", flowViewModel.settings.shearAmount))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Frame Influence")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.shearFrameInfluence, in: 0.0...1.0)
            Text(String(format: "%.2f", flowViewModel.settings.shearFrameInfluence))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    private var rippleAlongFramesParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ripple Depth")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.rippleDepth, in: 0.0...1.0)
            Text(String(format: "%.2f", flowViewModel.settings.rippleDepth))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Period (Frames)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.ripplePeriodFrames, in: 4.0...128.0)
            Text(String(format: "%.0f", flowViewModel.settings.ripplePeriodFrames))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Phase Offset")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.ripplePhaseOffset, in: 0.0...(2.0 * Float.pi))
            Text(String(format: "%.2f rad", flowViewModel.settings.ripplePhaseOffset))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    private var glitchSprinkleParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Probability per Frame")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.glitchProbabilityPerFrame, in: 0.0...0.2)
            Text(String(format: "%.3f", flowViewModel.settings.glitchProbabilityPerFrame))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Glitch Intensity")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: $flowViewModel.settings.glitchIntensity, in: 0.0...1.0)
            Text(String(format: "%.2f", flowViewModel.settings.glitchIntensity))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

