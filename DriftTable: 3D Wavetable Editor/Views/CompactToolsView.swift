//
//  CompactToolsView.swift
//  DriftTable: 3D Wavetable Editor
//
//  Created by Mitchell Cohen on 11/12/25.
//

import SwiftUI

struct CompactToolsView: View {
    @ObservedObject var toolsViewModel: ToolsViewModel
    @ObservedObject var flowViewModel: FlowViewModel
    @ObservedObject var projectViewModel: ProjectViewModel
    @State private var selectedToolCategory: ToolCategory = .shape
    @State private var showToolParameters = false
    
    enum ToolCategory: String, CaseIterable {
        case shape = "Shape"
        case flow = "Flow"
        case morph = "Morph"
        case formula = "Formula"
        
        var icon: String {
            switch self {
            case .shape: return "waveform.path"
            case .flow: return "wind"
            case .morph: return "sparkles"
            case .formula: return "function"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category selector - compact horizontal
            HStack(spacing: 8) {
                ForEach(ToolCategory.allCases, id: \.self) { category in
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            selectedToolCategory = category
                            showToolParameters = true
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 14))
                            Text(category.rawValue)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedToolCategory == category ? Color.accentColor.opacity(0.2) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            // Tool selection - compact horizontal scroll (not shown for morph or formula tabs)
            if selectedToolCategory != .morph && selectedToolCategory != .formula {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if selectedToolCategory == .shape {
                            ForEach(Tool.allCases) { tool in
                                CompactToolButton(
                                    title: tool.rawValue,
                                    isSelected: toolsViewModel.selectedTool == tool,
                                    icon: tool.icon
                                ) {
                                    withAnimation(.spring(response: 0.2)) {
                                        toolsViewModel.selectedTool = tool
                                        showToolParameters = true
                                    }
                                }
                            }
                        } else {
                            ForEach(FlowTool.allCases) { tool in
                                CompactToolButton(
                                    title: tool.rawValue,
                                    isSelected: flowViewModel.settings.selectedTool == tool,
                                    icon: tool.icon
                                ) {
                                    withAnimation(.spring(response: 0.2)) {
                                        flowViewModel.settings.selectedTool = tool
                                        showToolParameters = true
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
            
            // Tool parameters - collapsible with animation (except Morph and Formula tabs which are always shown)
            if showToolParameters || selectedToolCategory == .morph || selectedToolCategory == .formula {
                VStack(spacing: 0) {
                    Divider()
                    
                    // Collapse button (only for Shape and Flow tabs)
                    if selectedToolCategory != .morph && selectedToolCategory != .formula {
                        Button(action: {
                            withAnimation(.spring(response: 0.2)) {
                                showToolParameters = false
                            }
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            if selectedToolCategory == .shape {
                                ToolSidebarView(
                                    toolsViewModel: toolsViewModel,
                                    projectViewModel: projectViewModel
                                )
                            } else if selectedToolCategory == .flow {
                                FlowSidebarView(
                                    flowViewModel: flowViewModel,
                                    projectViewModel: projectViewModel
                                )
                            } else if selectedToolCategory == .morph {
                                // Morph tab
                                morphControlsView
                            } else {
                                // Formula tab
                                formulaControlsView
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .padding(.bottom, 10)
                    }
                    .frame(maxHeight: selectedToolCategory == .morph ? 280 : (selectedToolCategory == .formula ? 400 : 200))
                    .scrollIndicators(.hidden)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // Morph controls view
    private var morphControlsView: some View {
        VStack(spacing: 12) {
            // Key shapes mini list
            VStack(spacing: 6) {
                HStack {
                    Text("Key Shapes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: { projectViewModel.addKeyShape() }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(projectViewModel.project.keyShapes) { keyShape in
                            Button(action: {
                                projectViewModel.selectKeyShape(keyShape.id)
                            }) {
                                Text(keyShape.id)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundColor(projectViewModel.selectedKeyShapeId == keyShape.id ? .white : .primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(projectViewModel.selectedKeyShapeId == keyShape.id ? Color.accentColor : Color(UIColor.tertiarySystemBackground))
                                    )
                            }
                            .contextMenu {
                                Button(action: { projectViewModel.duplicateKeyShape(keyShape.id) }) {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }
                                Button(role: .destructive, action: { projectViewModel.deleteKeyShape(keyShape.id) }) {
                                    Label("Delete", systemImage: "trash")
                                }
                                .disabled(projectViewModel.project.keyShapes.count <= 1)
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Morph Settings
            VStack(alignment: .leading, spacing: 10) {
                Text("Morph Settings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Frame Count
                HStack {
                    Text("Frames")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .leading)
                    Picker("", selection: Binding(
                        get: { projectViewModel.project.morphSettings.frameCount },
                        set: { projectViewModel.project.morphSettings.frameCount = $0 }
                    )) {
                        ForEach(MorphSettings.frameCountOptions, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Morph Style
                HStack {
                    Text("Style")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .leading)
                    Picker("", selection: Binding(
                        get: { projectViewModel.project.morphSettings.morphStyle },
                        set: { projectViewModel.project.morphSettings.morphStyle = $0 }
                    )) {
                        ForEach(MorphStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            Divider()
            
            // Action buttons
            VStack(spacing: 8) {
                Button(action: {
                    projectViewModel.generateFrames()
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate Frames")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(projectViewModel.project.keyShapes.count < 2)
                
                Button(action: {
                    projectViewModel.normalizeFrames()
                }) {
                    HStack {
                        Image(systemName: "waveform")
                        Text("Normalize")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(projectViewModel.project.generatedFrames.isEmpty)
            }
        }
    }
    
    // Formula controls view
    private var formulaControlsView: some View {
        VStack(spacing: 12) {
            // Work on current key shape only
            if let currentShape = projectViewModel.currentKeyShape,
               let selectedId = projectViewModel.selectedKeyShapeId {
                ExpressionPanelView(
                    frames: Binding(
                        get: { [currentShape.samples] },
                        set: { newFrames in
                            if let firstFrame = newFrames.first {
                                var updatedShape = currentShape
                                updatedShape.samples = firstFrame
                                projectViewModel.updateCurrentKeyShape(updatedShape)
                                projectViewModel.updateOriginalKeyShape(id: selectedId, shape: updatedShape)
                            }
                        }
                    ),
                    selectedFrameIndex: .constant(0),
                    sampleCount: projectViewModel.project.samplesPerFrame
                )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Label("No key shape selected", systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Text("Select or create a key shape to use formulas.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
            }
        }
    }
}

struct CompactToolButton: View {
    let title: String
    let isSelected: Bool
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
            }
            .frame(width: 70, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(UIColor.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

