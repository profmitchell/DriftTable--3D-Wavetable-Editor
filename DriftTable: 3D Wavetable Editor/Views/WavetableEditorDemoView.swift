//
//  WavetableEditorDemoView.swift
//  DriftTable
//
//  Complete demo view showing math expression generator in action
//

import SwiftUI

struct WavetableEditorDemoView: View {
    @State private var frames: [[Float]]
    @State private var selectedFrameIndex: Int = 0
    let sampleCount: Int = 256
    
    init() {
        // Initialize with 8 silent frames
        let frameCount = 8
        let initialFrames = Array(repeating: Array(repeating: Float(0.0), count: 256), count: frameCount)
        _frames = State(initialValue: initialFrames)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 4) {
                    Text("Wavetable Editor Demo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Math Expression Generator")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Frame selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Frame: \(selectedFrameIndex + 1) of \(frames.count)")
                        .font(.headline)
                    
                    Picker("Frame", selection: $selectedFrameIndex) {
                        ForEach(0..<frames.count, id: \.self) { index in
                            Text("Frame \(index + 1)")
                                .tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)
                
                // Waveform visualization
                VStack(alignment: .leading, spacing: 8) {
                    Text("Waveform Visualization")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    WaveformVisualizationView(
                        samples: frames.indices.contains(selectedFrameIndex) ? frames[selectedFrameIndex] : [],
                        color: .blue
                    )
                    .frame(height: 200)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // All frames grid
                VStack(alignment: .leading, spacing: 8) {
                    Text("All Frames")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(frames.indices, id: \.self) { index in
                            VStack(spacing: 4) {
                                WaveformVisualizationView(
                                    samples: frames[index],
                                    color: index == selectedFrameIndex ? .blue : .gray
                                )
                                .frame(height: 60)
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(index == selectedFrameIndex ? Color.blue : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedFrameIndex = index
                                }
                                
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(index == selectedFrameIndex ? .blue : .secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                    .padding(.horizontal)
                
                // Expression panel
                ExpressionPanelView(
                    frames: $frames,
                    selectedFrameIndex: $selectedFrameIndex,
                    sampleCount: sampleCount
                )
                
                Spacer()
            }
        }
    }
}

// MARK: - Waveform Visualization

struct WaveformVisualizationView: View {
    let samples: [Float]
    let color: Color
    
    var body: some View {
        Canvas { context, size in
            guard !samples.isEmpty else { return }
            
            let width = size.width
            let height = size.height
            let midY = height / 2
            
            // Draw center line
            var centerLine = Path()
            centerLine.move(to: CGPoint(x: 0, y: midY))
            centerLine.addLine(to: CGPoint(x: width, y: midY))
            context.stroke(centerLine, with: .color(.gray.opacity(0.3)), lineWidth: 0.5)
            
            // Draw waveform
            var path = Path()
            
            for (index, sample) in samples.enumerated() {
                let x = width * CGFloat(index) / CGFloat(samples.count - 1)
                let y = midY - (CGFloat(sample) * midY * 0.9) // 0.9 for padding
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            context.stroke(path, with: .color(color), lineWidth: 1.5)
        }
        .padding(4)
    }
}

// MARK: - Preview

#Preview {
    WavetableEditorDemoView()
}

