//
//  KeyShapesSidebarView.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import SwiftUI

struct KeyShapesSidebarView: View {
    @ObservedObject var projectViewModel: ProjectViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Key Shapes")
                    .font(.headline)
                Spacer()
                Button(action: { projectViewModel.addKeyShape() }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            // Key Shapes List
            List {
                ForEach(projectViewModel.project.keyShapes) { keyShape in
                    HStack {
                        Text(keyShape.id)
                            .font(.title2)
                            .foregroundColor(projectViewModel.selectedKeyShapeId == keyShape.id ? .accentColor : .primary)
                        Spacer()
                        
                        // Actions
                        HStack(spacing: 8) {
                            Button(action: { projectViewModel.duplicateKeyShape(keyShape.id) }) {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.plain)
                            .help("Duplicate")
                            
                            Button(action: { projectViewModel.deleteKeyShape(keyShape.id) }) {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                            .help("Delete")
                            .disabled(projectViewModel.project.keyShapes.count <= 1)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        projectViewModel.selectKeyShape(keyShape.id)
                    }
                }
            }
            .listStyle(.sidebar)
            
            Divider()
            
            // Morph Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("Morph Settings")
                    .font(.headline)
                    .padding(.horizontal)
                
                // Frame Count
                VStack(alignment: .leading, spacing: 4) {
                    Text("Frame Count")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                .padding(.horizontal)
                
                // Morph Style
                VStack(alignment: .leading, spacing: 4) {
                    Text("Morph Style")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                .padding(.horizontal)
                
                // Generate Button
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
                .padding(.horizontal)
                .disabled(projectViewModel.project.keyShapes.count < 2)
                
                // Normalize Button
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
                .padding(.horizontal)
                .disabled(projectViewModel.project.generatedFrames.isEmpty)
            }
            .padding(.vertical)
        }
        .frame(minWidth: 200, idealWidth: 250)
    }
}

