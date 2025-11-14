//
//  HarmonicsPanelView.swift
//  DriftTable: 3D Wavetable Editor
//
//  Created by Codex on 11/12/25.
//

import SwiftUI

struct HarmonicsPanelView: View {
    @ObservedObject var projectViewModel: ProjectViewModel
    @State private var harmonics: [HarmonicComponent] = [
        HarmonicComponent(order: 1, amplitude: 1.0)
    ]
    @State private var selectedOrder: Int = 1
    @State private var selectedAmplitude: Double = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            addHarmonicRow
            harmonicsList
            actionButtons
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Harmonics Designer")
                .font(.headline)
            Text("Pick musical partials and we’ll synthesize the waveform for you.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var addHarmonicRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Stepper("Harmonic \(selectedOrder)", value: $selectedOrder, in: 1...32)
                Spacer()
                Text(String(format: "× %.2f", selectedAmplitude))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Slider(value: $selectedAmplitude, in: 0...1)
            Button {
                addOrUpdateComponent(order: selectedOrder, amplitude: Float(selectedAmplitude))
            } label: {
                Label("Add / Update Harmonic", systemImage: "plus.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var harmonicsList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Active Harmonics")
                .font(.subheadline)
            if harmonics.isEmpty {
                Text("Add a harmonic to begin.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(harmonics.sorted(by: { $0.order < $1.order })) { component in
                    HStack {
                        Text("H\(component.order)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 40, alignment: .leading)
                        Slider(value: Binding(
                            get: { Double(component.amplitude) },
                            set: { updateComponent(order: component.order, amplitude: Float($0)) }
                        ), in: 0...1)
                        Text(String(format: "%.2f", component.amplitude))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button(role: .destructive) {
                            removeComponent(order: component.order)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: applyToCurrentShape) {
                Label("Render Harmonics", systemImage: "waveform.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(projectViewModel.currentKeyShape == nil || harmonics.isEmpty)
            
            Button(role: .destructive) {
                harmonics.removeAll()
            } label: {
                Label("Clear", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
    
    private func addOrUpdateComponent(order: Int, amplitude: Float) {
        if let index = harmonics.firstIndex(where: { $0.order == order }) {
            harmonics[index].amplitude = amplitude
        } else {
            harmonics.append(HarmonicComponent(order: order, amplitude: amplitude))
        }
    }
    
    private func updateComponent(order: Int, amplitude: Float) {
        if let index = harmonics.firstIndex(where: { $0.order == order }) {
            harmonics[index].amplitude = amplitude
        }
    }
    
    private func removeComponent(order: Int) {
        harmonics.removeAll { $0.order == order }
    }
    
    private func applyToCurrentShape() {
        guard var shape = projectViewModel.currentKeyShape,
              !harmonics.isEmpty else { return }
        let sampleCount = projectViewModel.project.samplesPerFrame
        var samples = [Float](repeating: 0.0, count: sampleCount)
        let sorted = harmonics.sorted(by: { $0.order < $1.order })
        for (index, _) in samples.enumerated() {
            let phase = Float(index) / Float(sampleCount)
            var value: Float = 0.0
            for component in sorted {
                value += sinf(2 * Float.pi * Float(component.order) * phase) * component.amplitude
            }
            samples[index] = value
        }
        let processed = WaveformUtilities.sanitize(samples)
        shape.samples = processed
        projectViewModel.updateCurrentKeyShape(shape)
    }
}

private struct HarmonicComponent: Identifiable {
    let id = UUID()
    let order: Int
    var amplitude: Float
}
