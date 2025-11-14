//
//  ToolSidebarView.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import SwiftUI

struct ToolSidebarView: View {
    @ObservedObject var toolsViewModel: ToolsViewModel
    @ObservedObject var projectViewModel: ProjectViewModel
    
    init(toolsViewModel: ToolsViewModel, projectViewModel: ProjectViewModel) {
        self.toolsViewModel = toolsViewModel
        self.projectViewModel = projectViewModel
        // Set up global apply callback
        toolsViewModel.applyGlobally = {
            projectViewModel.applyShapeToolGlobally(toolsViewModel.selectedTool, toolsViewModel: toolsViewModel)
        }
    }
    
    private var hasGeneratedFrames: Bool {
        !projectViewModel.project.generatedFrames.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Tool parameters only - tool selection is handled by CompactToolsView
            toolParametersView
            
            // Global apply button (only show when frames are generated)
            if hasGeneratedFrames {
                Divider()
                    .padding(.vertical, 4)
                
                Button(action: {
                    toolsViewModel.applyGlobally?()
                }) {
                    HStack {
                        Image(systemName: "square.stack.3d.up")
                        Text("Apply Globally")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 20) // Extra padding for scrolling
            // Real-time global application when parameters change
            .onChange(of: toolsViewModel.selectedTool) { _, _ in
                if hasGeneratedFrames {
                    toolsViewModel.applyGlobally?()
                }
            }
            .onChange(of: toolsViewModel.liftDropAmount) { _, _ in
                if hasGeneratedFrames {
                    toolsViewModel.applyGlobally?()
                }
            }
            .onChange(of: toolsViewModel.verticalStretchAmount) { _, _ in
                if hasGeneratedFrames {
                    toolsViewModel.applyGlobally?()
                }
            }
            .onChange(of: toolsViewModel.horizontalStretchAmount) { _, _ in
                if hasGeneratedFrames {
                    toolsViewModel.applyGlobally?()
                }
            }
            .onChange(of: toolsViewModel.pinchPosition) { _, _ in
                if hasGeneratedFrames {
                    toolsViewModel.applyGlobally?()
                }
            }
            .onChange(of: toolsViewModel.pinchStrength) { _, _ in
                if hasGeneratedFrames {
                    toolsViewModel.applyGlobally?()
                }
            }
            .onChange(of: toolsViewModel.tiltAmount) { _, _ in
                if hasGeneratedFrames {
                    toolsViewModel.applyGlobally?()
                }
            }
            .onChange(of: toolsViewModel.symmetryAmount) { _, _ in
                if hasGeneratedFrames {
                    toolsViewModel.applyGlobally?()
                }
            }
            .onChange(of: toolsViewModel.arcStartPosition) { _, _ in
                if hasGeneratedFrames {
                    toolsViewModel.applyGlobally?()
                }
            }
            .onChange(of: toolsViewModel.arcEndPosition) { _, _ in
                if hasGeneratedFrames {
                    toolsViewModel.applyGlobally?()
                }
            }
            .onChange(of: toolsViewModel.arcCurvature) { _, _ in
                if hasGeneratedFrames {
                    toolsViewModel.applyGlobally?()
                }
            }
    }
    
    @ViewBuilder
    private var toolParametersView: some View {
        switch toolsViewModel.selectedTool {
        case .liftDrop:
            liftDropParameters
        case .verticalStretch:
            verticalStretchParameters
        case .horizontalStretch:
            horizontalStretchParameters
        case .pinch:
            pinchParameters
        case .arc:
            arcParameters
        case .tilt:
            tiltParameters
        case .symmetry:
            symmetryParameters
        case .smoothBrush:
            smoothBrushParameters
        case .gritBrush:
            gritBrushParameters
        }
    }
    
    private var liftDropParameters: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("Amount")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .leading)
                Slider(value: Binding(
                    get: { Double(toolsViewModel.liftDropAmount) },
                    set: { toolsViewModel.liftDropAmount = Float($0) }
                ), in: -1.0...1.0)
                Text(String(format: "%.2f", toolsViewModel.liftDropAmount))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
        }
    }
    
    private var verticalStretchParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: Binding(
                get: { Double(toolsViewModel.verticalStretchAmount) },
                set: { toolsViewModel.verticalStretchAmount = Float($0) }
            ), in: 0.1...3.0)
            Text(String(format: "%.2f", toolsViewModel.verticalStretchAmount))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var horizontalStretchParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: Binding(
                get: { Double(toolsViewModel.horizontalStretchAmount) },
                set: { toolsViewModel.horizontalStretchAmount = Float($0) }
            ), in: 0.1...3.0)
            Text(String(format: "%.2f", toolsViewModel.horizontalStretchAmount))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var pinchParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Position")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: Binding(
                get: { Double(toolsViewModel.pinchPosition) },
                set: { toolsViewModel.pinchPosition = Float($0) }
            ), in: 0.0...1.0)
            
            Text("Strength")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: Binding(
                get: { Double(toolsViewModel.pinchStrength) },
                set: { toolsViewModel.pinchStrength = Float($0) }
            ), in: 0.0...1.0)
        }
    }
    
    private var tiltParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: Binding(
                get: { Double(toolsViewModel.tiltAmount) },
                set: { toolsViewModel.tiltAmount = Float($0) }
            ), in: -1.0...1.0)
            Text(String(format: "%.2f", toolsViewModel.tiltAmount))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var symmetryParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: Binding(
                get: { Double(toolsViewModel.symmetryAmount) },
                set: { toolsViewModel.symmetryAmount = Float($0) }
            ), in: 0.0...1.0)
            Text(String(format: "%.0f%%", toolsViewModel.symmetryAmount * 100))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var smoothBrushParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Brush Size")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: Binding(
                get: { Double(toolsViewModel.smoothBrushSize) },
                set: { toolsViewModel.smoothBrushSize = Float($0) }
            ), in: 0.01...0.5)
            
            Text("Strength")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: Binding(
                get: { Double(toolsViewModel.smoothBrushStrength) },
                set: { toolsViewModel.smoothBrushStrength = Float($0) }
            ), in: 0.0...1.0)
            
            Text("Drag on waveform to smooth")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
    }
    
    private var arcParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Start Position")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: Binding(
                get: { Double(toolsViewModel.arcStartPosition) },
                set: { toolsViewModel.arcStartPosition = Float($0) }
            ), in: 0.0...1.0)
            
            Text("End Position")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: Binding(
                get: { Double(toolsViewModel.arcEndPosition) },
                set: { toolsViewModel.arcEndPosition = Float($0) }
            ), in: 0.0...1.0)
            
            Text("Curvature")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: Binding(
                get: { Double(toolsViewModel.arcCurvature) },
                set: { toolsViewModel.arcCurvature = Float($0) }
            ), in: -1.0...1.0)
            Text(String(format: "%.2f", toolsViewModel.arcCurvature))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var gritBrushParameters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Brush Size")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: Binding(
                get: { Double(toolsViewModel.gritBrushSize) },
                set: { toolsViewModel.gritBrushSize = Float($0) }
            ), in: 0.01...0.5)
            
            Text("Intensity")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Slider(value: Binding(
                get: { Double(toolsViewModel.gritBrushIntensity) },
                set: { toolsViewModel.gritBrushIntensity = Float($0) }
            ), in: 0.0...1.0)
            
            Text("Drag on waveform to add texture")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
    }
}

struct ToolButton: View {
    let tool: Tool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: tool.icon)
                    .frame(width: 20)
                Text(tool.rawValue)
                    .font(.subheadline)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

