//
//  FlowToolParameterViews.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import SwiftUI

struct FlowToolParameterViews {
    let settings: Binding<FlowToolSettings>
    
    var driftParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Direction")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Picker("", selection: settings.driftDirection) {
                Text("Left").tag(false)
                Text("Right").tag(true)
            }
            .pickerStyle(.segmented)
            
            Text("Amount")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.driftAmount, in: 0.0...2.0)
            Text(String(format: "%.2f", settings.wrappedValue.driftAmount))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    var taperParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Start Intensity")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.taperStartIntensity, in: 0.0...2.0)
            
            Text("End Intensity")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.taperEndIntensity, in: 0.0...2.0)
        }
        .padding(.horizontal)
    }
    
    var windParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Direction")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Picker("", selection: settings.windDirection) {
                Text("Right to Left").tag(false)
                Text("Left to Right").tag(true)
            }
            .pickerStyle(.segmented)
            
            Text("Strength")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.windStrength, in: 0.0...2.0)
            Text(String(format: "%.2f", settings.wrappedValue.windStrength))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Falloff")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.windFalloff, in: 0.0...1.0)
            Text(String(format: "%.2f", settings.wrappedValue.windFalloff))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    var turbulenceNoiseParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Noise Amount")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.turbulenceNoiseAmount, in: 0.0...0.2)
            Text(String(format: "%.3f", settings.wrappedValue.turbulenceNoiseAmount))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Frame Frequency")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.turbulenceNoiseFreqFrames, in: 0.1...5.0)
            Text(String(format: "%.2f", settings.wrappedValue.turbulenceNoiseFreqFrames))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Sample Frequency")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.turbulenceNoiseFreqSamples, in: 0.1...5.0)
            Text(String(format: "%.2f", settings.wrappedValue.turbulenceNoiseFreqSamples))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    var gravityWellParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Target Amplitude")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.gravityWellTargetAmplitude, in: -1.0...1.0)
            Text(String(format: "%.2f", settings.wrappedValue.gravityWellTargetAmplitude))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Strength")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.gravityWellStrength, in: 0.0...1.0)
            Text(String(format: "%.2f", settings.wrappedValue.gravityWellStrength))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    var swirlParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Swirl Amount")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.swirlAmount, in: -3.14...3.14)
            Text(String(format: "%.2f rad", settings.wrappedValue.swirlAmount))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Center X")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.swirlCenterX, in: 0.0...1.0)
            Text(String(format: "%.2f", settings.wrappedValue.swirlCenterX))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Center Y")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.swirlCenterY, in: 0.0...1.0)
            Text(String(format: "%.2f", settings.wrappedValue.swirlCenterY))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    var shearParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shear Amount")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.shearAmount, in: -0.5...0.5)
            Text(String(format: "%.2f", settings.wrappedValue.shearAmount))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Frame Influence")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.shearFrameInfluence, in: 0.0...1.0)
            Text(String(format: "%.2f", settings.wrappedValue.shearFrameInfluence))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    var rippleAlongFramesParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ripple Depth")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.rippleDepth, in: 0.0...1.0)
            Text(String(format: "%.2f", settings.wrappedValue.rippleDepth))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Period (Frames)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.ripplePeriodFrames, in: 4.0...128.0)
            Text(String(format: "%.0f", settings.wrappedValue.ripplePeriodFrames))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Phase Offset")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.ripplePhaseOffset, in: 0.0...(2.0 * Float.pi))
            Text(String(format: "%.2f rad", settings.wrappedValue.ripplePhaseOffset))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    var glitchSprinkleParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Probability per Frame")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.glitchProbabilityPerFrame, in: 0.0...0.2)
            Text(String(format: "%.3f", settings.wrappedValue.glitchProbabilityPerFrame))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Glitch Intensity")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: settings.glitchIntensity, in: 0.0...1.0)
            Text(String(format: "%.2f", settings.wrappedValue.glitchIntensity))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

