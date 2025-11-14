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
        
        var icon: String {
            switch self {
            case .shape: return "waveform.path"
            case .flow: return "wind"
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
            
            // Tool selection - compact horizontal scroll
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
            
            // Tool parameters - collapsible with animation
            if showToolParameters {
                VStack(spacing: 0) {
                    Divider()
                    
                    // Collapse button
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
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            if selectedToolCategory == .shape {
                                ToolSidebarView(
                                    toolsViewModel: toolsViewModel,
                                    projectViewModel: projectViewModel
                                )
                            } else {
                                FlowSidebarView(
                                    flowViewModel: flowViewModel,
                                    projectViewModel: projectViewModel
                                )
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: 220)
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

