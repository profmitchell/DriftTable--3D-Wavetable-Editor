//
//  WarpPanelView.swift
//  DriftTable: 3D Wavetable Editor
//
//  Created by Codex on 11/12/25.
//

import SwiftUI

struct WarpPanelView: View {
    @ObservedObject var projectViewModel: ProjectViewModel
    @State private var bendAmount: Double = 0
    @State private var baseSamples: [Float] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            
            if projectViewModel.currentKeyShape != nil {
                warpControls
            } else {
                Text("Select a key shape to start warping.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear(perform: captureBaseSamples)
        .onChange(of: projectViewModel.selectedKeyShapeId) { _, _ in
            captureBaseSamples()
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Warp Modes")
                .font(.headline)
            Text("Bend the waveform phase like the warp knobs in Vital/Serum without breaking zero crossings.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var warpControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Bend Warp", systemImage: "waveform")
                    Spacer()
                    Text(amountLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: Binding(
                    get: { bendAmount },
                    set: { value in
                        bendAmount = value
                        applyWarp()
                    }
                ), in: -1.0...1.0)
            }
            
            HStack(spacing: 10) {
                Button(action: applyWarp) {
                    Label("Apply", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: resetWarp) {
                    Label("Reset", systemImage: "arrow.uturn.backward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(baseSamples.isEmpty)
            }
            
            Button(action: captureBaseSamples) {
                Label("Capture Base Shape", systemImage: "camera.metering.center.weighted")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .disabled(projectViewModel.currentKeyShape == nil)
            
            Text("Capture a base shape, then automate Bend for evolving timbres.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    private var amountLabel: String {
        bendAmount == 0 ? "Neutral" : String(format: "%+.2f", bendAmount)
    }
    
    private func captureBaseSamples() {
        if let samples = projectViewModel.currentKeyShape?.samples {
            baseSamples = samples
        } else {
            baseSamples.removeAll()
        }
        bendAmount = 0
    }
    
    private func resetWarp() {
        guard var shape = projectViewModel.currentKeyShape else { return }
        if !baseSamples.isEmpty {
            shape.samples = baseSamples
            projectViewModel.updateCurrentKeyShape(shape)
        }
        bendAmount = 0
    }
    
    private func applyWarp() {
        guard var shape = projectViewModel.currentKeyShape else { return }
        let source = baseSamples.isEmpty ? shape.samples : baseSamples
        let warped = WaveformUtilities.bendWarp(samples: source, amount: Float(bendAmount))
        shape.samples = WaveformUtilities.sanitize(warped)
        projectViewModel.updateCurrentKeyShape(shape)
    }
}
