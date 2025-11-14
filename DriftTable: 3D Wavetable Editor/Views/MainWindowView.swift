//
//  MainWindowView.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct MainWindowView: View {
    @StateObject private var projectViewModel = ProjectViewModel()
    @StateObject private var toolsViewModel = ToolsViewModel()
    @StateObject private var flowViewModel = FlowViewModel()
    @StateObject private var audioEngine = AudioEngine()
    @State private var toolApplicationTask: Task<Void, Never>?
    @State private var selectedToolTab = 0
    @State private var selectedFormulaFrameIndex = 0
    @State private var isImporting = false
    @State private var importError: Error?
    @State private var showImportError = false
    @State private var isDragOver = false
    @State private var formulaTargetMode: FormulaTargetMode = .keyShape
    
    enum FormulaTargetMode {
        case keyShape
        case generatedFrames
    }
    
    // File picker states
    @State private var showOpenProjectPicker = false
    @State private var showSaveProjectPicker = false
    @State private var showExportWavetablePicker = false
    @State private var showImportAudioPicker = false
    
    // Inspector/sidebar visibility
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .automatic
    @State private var showInspector: Bool = true
    @State private var selectedSidebarItem: SidebarItem? = .keyShapes
    @State private var showToolsSheet: Bool = false // For portrait mode tools overlay
    
    enum SidebarItem: String, Identifiable {
        case keyShapes = "Key Shapes"
        
        var id: String { rawValue }
    }
    
    private var formulaToolsPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Mode selector
                VStack(alignment: .leading, spacing: 6) {
                    Text("Target")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Picker("Mode", selection: $formulaTargetMode) {
                        Text("Current Key Shape").tag(FormulaTargetMode.keyShape)
                        Text("Generated Frames").tag(FormulaTargetMode.generatedFrames)
                    }
                    .pickerStyle(.segmented)
                    .disabled(projectViewModel.project.generatedFrames.isEmpty && formulaTargetMode == .generatedFrames)
                }
                
                if formulaTargetMode == .keyShape {
                    // Work on current key shape
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
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(10)
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
                } else {
                    // Work on generated frames
                    if projectViewModel.project.generatedFrames.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("No generated frames", systemImage: "exclamationmark.triangle")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Text("Generate frames in the Morph tab to use formulas on the full wavetable.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                    } else {
                        let frameCount = projectViewModel.project.generatedFrames.count
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Target Frame")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Picker("Frame", selection: formulaFrameSelectionBinding) {
                                    ForEach(0..<frameCount, id: \.self) { index in
                                        Text("Frame \(index + 1)")
                                            .tag(index)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                            }
                        }
                        
                        ExpressionPanelView(
                            frames: generatedFramesBinding,
                            selectedFrameIndex: formulaFrameSelectionBinding,
                            sampleCount: projectViewModel.project.samplesPerFrame
                        )
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
    
    var body: some View {
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        
        NavigationSplitView(
            columnVisibility: $sidebarVisibility,
            sidebar: {
                sidebarView
            },
            content: {
                mainContentView
                    .inspector(isPresented: isPhone ? .constant(false) : $showInspector) {
                        if !isPhone {
                            inspectorView
                                .inspectorColumnWidth(min: 280, ideal: 320, max: 400)
                        }
                    }
            },
            detail: {
                // Empty detail - inspector is handled by modifier
                EmptyView()
            }
        )
        .navigationSplitViewStyle(.balanced)
        .fileImporter(
            isPresented: $showOpenProjectPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    loadProject(from: url)
                }
            case .failure(let error):
                print("Failed to open project: \(error)")
            }
        }
        .fileExporter(
            isPresented: $showSaveProjectPicker,
            document: ProjectDocument(project: projectViewModel.project),
            contentType: .json,
            defaultFilename: projectViewModel.project.name + ".drifttable"
        ) { result in
            switch result {
            case .success(let url):
                do {
                    try ProjectPersistence.save(project: projectViewModel.project, to: url)
                } catch {
                    print("Failed to save project: \(error)")
                }
            case .failure(let error):
                print("Failed to save project: \(error)")
            }
        }
        .fileExporter(
            isPresented: $showExportWavetablePicker,
            document: WavetableDocument(
                frames: projectViewModel.project.generatedFrames,
                sampleRate: projectViewModel.project.sampleRate
            ),
            contentType: .wav,
            defaultFilename: projectViewModel.project.name + ".wav"
        ) { result in
            switch result {
            case .success(let url):
                do {
                    try ExportService.exportWavetable(
                        frames: projectViewModel.project.generatedFrames,
                        sampleRate: projectViewModel.project.sampleRate,
                        to: url
                    )
                } catch {
                    print("Failed to export wavetable: \(error)")
                }
            case .failure(let error):
                print("Failed to export wavetable: \(error)")
            }
        }
        .fileImporter(
            isPresented: $showImportAudioPicker,
            allowedContentTypes: [.audio, .wav, .aiff, .mp3, .mpeg4Audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importAudioFromURL(url)
                }
            case .failure(let error):
                print("Failed to import audio: \(error)")
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ImportAudio"))) { _ in
            showImportAudioPicker = true
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ExportWavetable"))) { _ in
            showExportWavetablePicker = true
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("Undo"))) { _ in
            projectViewModel.undo()
            audioEngine.updateWavetable(
                frames: projectViewModel.project.generatedFrames,
                sampleRate: projectViewModel.project.sampleRate,
                samplesPerFrame: projectViewModel.project.samplesPerFrame
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("Redo"))) { _ in
            projectViewModel.redo()
            audioEngine.updateWavetable(
                frames: projectViewModel.project.generatedFrames,
                sampleRate: projectViewModel.project.sampleRate,
                samplesPerFrame: projectViewModel.project.samplesPerFrame
            )
        }
        .alert("Import Error", isPresented: $showImportError, presenting: importError) { error in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
    
    // MARK: - Sidebar
    private var sidebarView: some View {
        List(selection: $selectedSidebarItem) {
            Section("Project") {
                NavigationLink(value: SidebarItem.keyShapes) {
                    Label("Key Shapes", systemImage: "waveform.path")
                }
            }
        }
        .navigationTitle("DriftTable")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { newProject() }) {
                        Label("New Project", systemImage: "doc.badge.plus")
                    }
                    Button(action: { showOpenProjectPicker = true }) {
                        Label("Open...", systemImage: "folder")
                    }
                    Button(action: { showSaveProjectPicker = true }) {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    Divider()
                    Button(action: { showImportAudioPicker = true }) {
                        Label("Import Audio", systemImage: "square.and.arrow.down")
                    }
                    .disabled(isImporting)
                    Button(action: { showExportWavetablePicker = true }) {
                        Label("Export Wavetable", systemImage: "square.and.arrow.up")
                    }
                    .disabled(projectViewModel.project.generatedFrames.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private var mainContentView: some View {
        // Always show key shapes - on iPhone everything is in compact tools, on iPad use inspector
        keyShapesContentView
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Only show inspector toggle on iPad
            if UIDevice.current.userInterfaceIdiom != .phone {
                inspectorToggleToolbar
            }
        }
        .onChange(of: projectViewModel.project.generatedFrames) { _, newFrames in
            updateAudioEngine(frames: newFrames)
            clampFormulaFrameSelection(for: newFrames)
        }
        .onChange(of: projectViewModel.selectedKeyShapeId) { _, _ in
            // Update audio when key shape selection changes
            updateAudioEngine(frames: projectViewModel.project.generatedFrames)
        }
        .onChange(of: selectedSidebarItem) { _, newItem in
            // When navigating back to key shapes, ensure audio is updated
            if newItem == .keyShapes {
                updateAudioEngine(frames: projectViewModel.project.generatedFrames)
            }
        }
        .onAppear {
            updateAudioEngine(frames: projectViewModel.project.generatedFrames)
            clampFormulaFrameSelection(for: projectViewModel.project.generatedFrames)
        }
    }
    
    private var navigationTitle: String {
        "Key Shapes"
    }
    
    @ToolbarContentBuilder
    private var inspectorToggleToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: toggleInspector) {
                Label("Inspector", systemImage: "sidebar.right")
                    .labelStyle(.iconOnly)
                    .symbolVariant(showInspector ? .fill : .none)
            }
        }
    }
    
    private func toggleInspector() {
        showInspector.toggle()
    }
    
    private var formulaFrameSelectionBinding: Binding<Int> {
        Binding(
            get: {
                guard !projectViewModel.project.generatedFrames.isEmpty else {
                    return 0
                }
                return min(max(0, selectedFormulaFrameIndex), projectViewModel.project.generatedFrames.count - 1)
            },
            set: { newValue in
                guard !projectViewModel.project.generatedFrames.isEmpty else {
                    selectedFormulaFrameIndex = 0
                    return
                }
                let clamped = min(max(0, newValue), projectViewModel.project.generatedFrames.count - 1)
                selectedFormulaFrameIndex = clamped
            }
        )
    }
    
    private var generatedFramesBinding: Binding<[[Float]]> {
        Binding(
            get: { projectViewModel.project.generatedFrames },
            set: { newFrames in
                projectViewModel.project.generatedFrames = newFrames
                projectViewModel.project.frameCount = newFrames.count
                // Update audio engine when frames change via expression generator
                updateAudioEngine(frames: newFrames)
            }
        )
    }
    
    private func updateAudioEngine(frames: [[Float]]) {
        if frames.isEmpty {
            // If no frames, try to use current key shape for single cycle preview
            if let currentShape = projectViewModel.currentKeyShape {
                audioEngine.updateSingleCycle(
                    currentShape.samples,
                    sampleRate: projectViewModel.project.sampleRate
                )
            } else {
                audioEngine.updateWavetable(
                    frames: [],
                    sampleRate: projectViewModel.project.sampleRate,
                    samplesPerFrame: projectViewModel.project.samplesPerFrame
                )
            }
        } else {
            audioEngine.updateWavetable(
                frames: frames,
                sampleRate: projectViewModel.project.sampleRate,
                samplesPerFrame: projectViewModel.project.samplesPerFrame
            )
        }
    }
    
    private var keyShapesContentView: some View {
        GeometryReader { geometry in
            let isPortrait = geometry.size.height > geometry.size.width
            let isPhone = UIDevice.current.userInterfaceIdiom == .phone
            
            if isPhone && isPortrait {
                portraitLayout
            } else {
                landscapeLayout
            }
        }
    }
    
    private func clampFormulaFrameSelection(for frames: [[Float]]) {
        guard !frames.isEmpty else {
            selectedFormulaFrameIndex = 0
            return
        }
        let maxIndex = frames.count - 1
        if selectedFormulaFrameIndex > maxIndex {
            selectedFormulaFrameIndex = maxIndex
        }
    }
    
    private var portraitLayout: some View {
        GeometryReader { geometry in
            let bottomInset = geometry.safeAreaInsets.bottom
            
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    compactToolbar
                    waveformArea
                        .frame(maxHeight: .infinity)
                    
                    // Tools view - will handle its own scrolling
                    CompactToolsView(
                        toolsViewModel: toolsViewModel,
                        flowViewModel: flowViewModel,
                        projectViewModel: projectViewModel
                    )
                    
                    // Add spacer to prevent overlap with floating dock
                    Spacer()
                        .frame(height: 90 + bottomInset)
                }
                
                // Floating control dock at bottom - overlays content
                VStack {
                    Spacer()
                    FloatingControlDock(audioEngine: audioEngine)
                        .padding(.bottom, bottomInset > 0 ? bottomInset - 8 : 8)
                }
                .ignoresSafeArea(.keyboard)
            }
        }
    }
    
    private var landscapeLayout: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                compactToolbar
                GeometryReader { geometry in
                    ZStack {
                        waveformContent
                        if UIDevice.current.userInterfaceIdiom == .phone {
                            inspectorOverlayButton
                        }
                    }
                    .padding(.bottom, 100) // Space for floating dock
                }
            }
            
            // Floating control dock at bottom - overlays content
            FloatingControlDock(audioEngine: audioEngine)
                .padding(.bottom, 8)
        }
    }
    
    @ViewBuilder
    private var waveformArea: some View {
        if !projectViewModel.project.generatedFrames.isEmpty {
            WavetablePreviewView(
                frames: projectViewModel.project.generatedFrames,
                samplesPerFrame: projectViewModel.project.samplesPerFrame,
                position: $audioEngine.wavetablePosition
            )
        } else if let currentShape = projectViewModel.currentKeyShape {
            waveformEditorView(for: currentShape)
        } else {
            emptyStateView
        }
    }
    
    @ViewBuilder
    private var waveformContent: some View {
        if !projectViewModel.project.generatedFrames.isEmpty {
            WavetablePreviewView(
                frames: projectViewModel.project.generatedFrames,
                samplesPerFrame: projectViewModel.project.samplesPerFrame,
                position: $audioEngine.wavetablePosition
            )
        } else if let currentShape = projectViewModel.currentKeyShape {
            waveformEditorView(for: currentShape)
        } else {
            emptyStateView
        }
    }
    
    private func waveformEditorView(for shape: KeyShape) -> some View {
        WaveEditorView(
            samples: shape.samples,
            samplesPerFrame: projectViewModel.project.samplesPerFrame,
            selectedTool: toolsViewModel.selectedTool,
            toolsViewModel: toolsViewModel,
            onSamplesChanged: handleSamplesChanged
        )
        .onChange(of: toolsViewModel.liftDropAmount) { _, _ in debouncedApplyTool() }
        .onChange(of: toolsViewModel.verticalStretchAmount) { _, _ in debouncedApplyTool() }
        .onChange(of: toolsViewModel.horizontalStretchAmount) { _, _ in debouncedApplyTool() }
        .onChange(of: toolsViewModel.pinchPosition) { _, _ in debouncedApplyTool() }
        .onChange(of: toolsViewModel.pinchStrength) { _, _ in debouncedApplyTool() }
        .onChange(of: toolsViewModel.arcStartPosition) { _, _ in debouncedApplyTool() }
        .onChange(of: toolsViewModel.arcEndPosition) { _, _ in debouncedApplyTool() }
        .onChange(of: toolsViewModel.arcCurvature) { _, _ in debouncedApplyTool() }
        .onChange(of: toolsViewModel.tiltAmount) { _, _ in debouncedApplyTool() }
        .onChange(of: toolsViewModel.symmetryAmount) { _, _ in debouncedApplyTool() }
    }
    
    private var portraitToolsPanel: some View {
        VStack(spacing: 0) {
            Divider()
            
            Picker("", selection: $selectedToolTab) {
                Text("Shape").tag(0)
                Text("Flow").tag(1)
                Text("Formula").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemBackground))
            
            toolsContent
                .frame(height: 180)
                .background(Color(UIColor.secondarySystemBackground))
        }
    }
    
    @ViewBuilder
    private var toolsContent: some View {
        switch selectedToolTab {
        case 0:
            ToolSidebarView(
                toolsViewModel: toolsViewModel,
                projectViewModel: projectViewModel
            )
            .onChange(of: toolsViewModel.selectedTool) { oldTool, newTool in
                toolApplicationTask?.cancel()
                if newTool != .smoothBrush,
                   let currentShapeId = projectViewModel.selectedKeyShapeId {
                    if let current = projectViewModel.currentKeyShape {
                        projectViewModel.updateOriginalKeyShape(id: currentShapeId, shape: current)
                    }
                }
            }
        case 1:
            FlowSidebarView(flowViewModel: flowViewModel, projectViewModel: projectViewModel)
        default:
            formulaToolsPanel
        }
    }
    
    private var inspectorOverlayButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: toggleInspector) {
                    HStack(spacing: 6) {
                        Image(systemName: "sidebar.right")
                            .symbolVariant(showInspector ? .fill : .none)
                        Text("Inspector")
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(showInspector ? Color.accentColor : Color(UIColor.secondarySystemBackground))
                    .foregroundColor(showInspector ? .white : .primary)
                    .cornerRadius(8)
                    .shadow(radius: 4)
                }
                .padding(.trailing, 16)
                .padding(.top, 16)
            }
            Spacer()
        }
    }
    
    private func handleSamplesChanged(_ newSamples: [Float]) {
        if var shape = projectViewModel.currentKeyShape {
            shape.samples = newSamples
            projectViewModel.updateCurrentKeyShape(shape)
            if toolsViewModel.selectedTool == .smoothBrush,
               let id = projectViewModel.selectedKeyShapeId {
                projectViewModel.updateOriginalKeyShape(id: id, shape: shape)
            }
            // Update audio preview with new samples
            if projectViewModel.project.generatedFrames.isEmpty {
                audioEngine.updateSingleCycle(
                    newSamples,
                    sampleRate: projectViewModel.project.sampleRate
                )
            }
        }
    }
    
    
    // MARK: - Inspector (Right Sidebar)
    private var inspectorView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Key Shapes Section - Modern prioritized design
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label("Key Shapes", systemImage: "waveform.path")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: { projectViewModel.addKeyShape() }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                    .padding(.horizontal)
                    
                    // Compact key shape cards
                    VStack(spacing: 8) {
                        ForEach(projectViewModel.project.keyShapes) { keyShape in
                            HStack(spacing: 12) {
                                // Selection indicator
                                Circle()
                                    .fill(projectViewModel.selectedKeyShapeId == keyShape.id ? Color.accentColor : Color.clear)
                                    .frame(width: 8, height: 8)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.accentColor, lineWidth: projectViewModel.selectedKeyShapeId == keyShape.id ? 0 : 2)
                                    )
                                
                                // Shape ID
                                Text(keyShape.id)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(projectViewModel.selectedKeyShapeId == keyShape.id ? .accentColor : .primary)
                                    .frame(width: 40, alignment: .leading)
                                
                                Spacer()
                                
                                // Actions
                                HStack(spacing: 6) {
                                    Button(action: { projectViewModel.duplicateKeyShape(keyShape.id) }) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 14))
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.secondary)
                                    
                                    Button(action: { projectViewModel.deleteKeyShape(keyShape.id) }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14))
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.red)
                                    .disabled(projectViewModel.project.keyShapes.count <= 1)
                                    .opacity(projectViewModel.project.keyShapes.count <= 1 ? 0.3 : 1.0)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(projectViewModel.selectedKeyShapeId == keyShape.id ? 
                                          Color.accentColor.opacity(0.15) : 
                                          Color(UIColor.secondarySystemBackground))
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.2)) {
                                    projectViewModel.selectKeyShape(keyShape.id)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                
                Divider()
                
                // Morph Settings Section - Compact modern design
                VStack(alignment: .leading, spacing: 16) {
                    Label("Morph Settings", systemImage: "slider.horizontal.3")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Frame Count - Compact segmented control
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Frame Count")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        Picker("", selection: Binding(
                            get: { projectViewModel.project.morphSettings.frameCount },
                            set: { projectViewModel.project.morphSettings.frameCount = $0 }
                        )) {
                            ForEach(MorphSettings.frameCountOptions, id: \.self) { count in
                                Text("\(count)").tag(count)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                    }
                    
                    // Morph Style - Compact menu
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Morph Style")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        Picker("", selection: Binding(
                            get: { projectViewModel.project.morphSettings.morphStyle },
                            set: { projectViewModel.project.morphSettings.morphStyle = $0 }
                        )) {
                            ForEach(MorphStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Inspector")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Compact Toolbar - Modern iOS design
    private var compactToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Project actions
                Menu {
                    Button(action: { newProject() }) {
                        Label("New Project", systemImage: "doc.badge.plus")
                    }
                    Button(action: { showOpenProjectPicker = true }) {
                        Label("Open...", systemImage: "folder")
                    }
                    Button(action: { showSaveProjectPicker = true }) {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .frame(width: 44, height: 36)
                }
                .buttonStyle(.bordered)
                
                Divider()
                    .frame(height: 24)
                
                // Import/Export
                Button(action: { showImportAudioPicker = true }) {
                    if isImporting {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 36, height: 36)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isImporting)
                
                Button(action: { showExportWavetablePicker = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
                .disabled(projectViewModel.project.generatedFrames.isEmpty)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background {
            // Modern glass effect
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.path")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No waveform selected")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Select a key shape or import audio to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { showImportAudioPicker = true }) {
                Label("Import Audio", systemImage: "square.and.arrow.down")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isImporting)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods
    private func debouncedApplyTool() {
        toolApplicationTask?.cancel()
        applyNonInteractiveTool()
        
        toolApplicationTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                applyNonInteractiveTool()
            }
        }
    }
    
    private func applyNonInteractiveTool() {
        guard let currentShapeId = projectViewModel.selectedKeyShapeId,
              let originalShape = projectViewModel.getOriginalKeyShape(id: currentShapeId) else { return }
        
        guard toolsViewModel.selectedTool != .smoothBrush else { return }
        
        let modified = toolsViewModel.applyCurrentTool(to: originalShape)
        projectViewModel.updateCurrentKeyShape(modified)
        
        // Update audio preview with modified shape if no frames are generated
        if projectViewModel.project.generatedFrames.isEmpty {
            audioEngine.updateSingleCycle(
                modified.samples,
                sampleRate: projectViewModel.project.sampleRate
            )
        }
    }
    
    private func newProject() {
        projectViewModel.project = WavetableProject.defaultProject()
        projectViewModel.selectedKeyShapeId = projectViewModel.project.keyShapes.first?.id
        if let firstShape = projectViewModel.project.keyShapes.first {
            audioEngine.updateSingleCycle(
                firstShape.samples,
                sampleRate: projectViewModel.project.sampleRate
            )
        } else {
            audioEngine.updateWavetable(
                frames: [],
                sampleRate: projectViewModel.project.sampleRate,
                samplesPerFrame: projectViewModel.project.samplesPerFrame
            )
        }
    }
    
    private func loadProject(from url: URL) {
        do {
            let project = try ProjectPersistence.load(from: url)
            projectViewModel.loadProject(project)
            if project.generatedFrames.isEmpty,
               let firstShape = project.keyShapes.first {
                audioEngine.updateSingleCycle(
                    firstShape.samples,
                    sampleRate: project.sampleRate
                )
            } else {
                audioEngine.updateWavetable(
                    frames: project.generatedFrames,
                    sampleRate: project.sampleRate,
                    samplesPerFrame: project.samplesPerFrame
                )
            }
        } catch {
            print("Failed to load project: \(error)")
        }
    }
    
    private func importAudioFromURL(_ url: URL) {
        guard !isImporting else { return }
        isImporting = true
        importError = nil
        
        projectViewModel.importAudioFromURL(url) { result in
            isImporting = false
            
            switch result {
            case .success:
                audioEngine.updateWavetable(
                    frames: projectViewModel.project.generatedFrames,
                    sampleRate: projectViewModel.project.sampleRate,
                    samplesPerFrame: projectViewModel.project.samplesPerFrame
                )
            case .failure(let error):
                importError = error
                showImportError = true
                print("Import failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        _ = provider.loadObject(ofClass: URL.self) { url, error in
            guard let url = url, error == nil else { return }
            
            let pathExtension = url.pathExtension.lowercased()
            let audioExtensions = ["wav", "aiff", "aif", "mp3", "m4a", "aac", "caf", "m4a"]
            
            let isAudioFile = audioExtensions.contains(pathExtension) ||
                UTType(filenameExtension: pathExtension)?.conforms(to: .audio) == true
            
            guard isAudioFile else { return }
            
            DispatchQueue.main.async {
                importAudioFromURL(url)
            }
        }
        
        return true
    }
}

// Document types for file exporter
struct ProjectDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    private var projectData: Data
    
    @MainActor init(project: WavetableProject) {
        self.projectData = (try? JSONEncoder().encode(project)) ?? Data()
    }
    
    nonisolated init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        projectData = data
    }
    
    nonisolated func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: projectData)
    }
}

struct WavetableDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.wav] }
    
    var frames: [[Float]]
    var sampleRate: Double
    
    init(frames: [[Float]], sampleRate: Double) {
        self.frames = frames
        self.sampleRate = sampleRate
    }
    
    nonisolated init(configuration: ReadConfiguration) throws {
        throw CocoaError(.fileReadUnsupportedScheme)
    }
    
    nonisolated func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".wav")
        let framesCopy = frames
        let sampleRateCopy = sampleRate
        try ExportService.exportWavetable(frames: framesCopy, sampleRate: sampleRateCopy, to: tempURL)
        let data = try Data(contentsOf: tempURL)
        try? FileManager.default.removeItem(at: tempURL)
        return FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    MainWindowView()
}
