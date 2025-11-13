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
    @State private var isImporting = false
    @State private var importError: Error?
    @State private var showImportError = false
    @State private var isDragOver = false
    
    // File picker states
    @State private var showOpenProjectPicker = false
    @State private var showSaveProjectPicker = false
    @State private var showExportWavetablePicker = false
    @State private var showImportAudioPicker = false
    
    // Inspector/sidebar visibility
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .automatic
    @State private var inspectorVisibility: NavigationSplitViewVisibility = .automatic
    @State private var selectedSidebarItem: SidebarItem? = .keyShapes
    
    enum SidebarItem: String, Identifiable {
        case keyShapes = "Key Shapes"
        case morphSettings = "Morph Settings"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationSplitView(
            columnVisibility: $sidebarVisibility,
            sidebar: {
                sidebarView
            },
            content: {
                mainContentView
            },
            detail: {
                inspectorView
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
                NavigationLink(value: SidebarItem.morphSettings) {
                    Label("Morph Settings", systemImage: "slider.horizontal.3")
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
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Compact toolbar for mobile
            compactToolbar
            
            // Main editor/preview area
            GeometryReader { geometry in
                if !projectViewModel.project.generatedFrames.isEmpty {
                    // Show wavetable preview when frames are generated
                    WavetablePreviewView(
                        frames: projectViewModel.project.generatedFrames,
                        samplesPerFrame: projectViewModel.project.samplesPerFrame,
                        position: $audioEngine.wavetablePosition
                    )
                } else if let currentShape = projectViewModel.currentKeyShape {
                    // Show single waveform editor
                    WaveEditorView(
                        samples: currentShape.samples,
                        samplesPerFrame: projectViewModel.project.samplesPerFrame,
                        selectedTool: toolsViewModel.selectedTool,
                        toolsViewModel: toolsViewModel,
                        onSamplesChanged: { newSamples in
                            if var shape = projectViewModel.currentKeyShape {
                                shape.samples = newSamples
                                projectViewModel.updateCurrentKeyShape(shape)
                                if toolsViewModel.selectedTool == .smoothBrush,
                                   let id = projectViewModel.selectedKeyShapeId {
                                    projectViewModel.updateOriginalKeyShape(id: id, shape: shape)
                                }
                            }
                        }
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
                } else {
                    emptyStateView
                }
            }
            
            // Audio Preview - compact on mobile
            AudioPreviewView(audioEngine: audioEngine)
                .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 120 : 150)
        }
        .navigationTitle(selectedSidebarItem == .keyShapes ? "Key Shapes" : "Morph Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { inspectorVisibility = inspectorVisibility == .visible ? .hidden : .visible }) {
                    Image(systemName: inspectorVisibility == .visible ? "sidebar.right" : "sidebar.right")
                }
            }
        }
        .onChange(of: selectedSidebarItem) { oldValue, newValue in
            // Handle sidebar selection changes
        }
        .onChange(of: projectViewModel.project.generatedFrames) { _, newFrames in
            audioEngine.updateWavetable(
                frames: newFrames,
                sampleRate: projectViewModel.project.sampleRate,
                samplesPerFrame: projectViewModel.project.samplesPerFrame
            )
        }
        .onAppear {
            audioEngine.updateWavetable(
                frames: projectViewModel.project.generatedFrames,
                sampleRate: projectViewModel.project.sampleRate,
                samplesPerFrame: projectViewModel.project.samplesPerFrame
            )
        }
    }
    
    // MARK: - Inspector (Right Sidebar)
    private var inspectorView: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedToolTab) {
                Text("Shape").tag(0)
                Text("Flow").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if selectedToolTab == 0 {
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
            } else {
                FlowSidebarView(flowViewModel: flowViewModel, projectViewModel: projectViewModel)
            }
        }
        .navigationTitle("Inspector")
        .navigationBarTitleDisplayMode(.inline)
        .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
    }
    
    // MARK: - Compact Toolbar
    private var compactToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Button(action: { newProject() }) {
                    Label("New", systemImage: "doc.badge.plus")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                
                Button(action: { showOpenProjectPicker = true }) {
                    Label("Open", systemImage: "folder")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                
                Button(action: { showSaveProjectPicker = true }) {
                    Label("Save", systemImage: "square.and.arrow.down")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                
                Divider()
                    .frame(height: 20)
                
                Button(action: { showImportAudioPicker = true }) {
                    if isImporting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Label("Import", systemImage: "square.and.arrow.down")
                            .labelStyle(.iconOnly)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isImporting)
                
                Button(action: { showExportWavetablePicker = true }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .disabled(projectViewModel.project.generatedFrames.isEmpty)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
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
    }
    
    private func newProject() {
        projectViewModel.project = WavetableProject.defaultProject()
        projectViewModel.selectedKeyShapeId = projectViewModel.project.keyShapes.first?.id
        audioEngine.updateWavetable(
            frames: [],
            sampleRate: projectViewModel.project.sampleRate,
            samplesPerFrame: projectViewModel.project.samplesPerFrame
        )
    }
    
    private func loadProject(from url: URL) {
        do {
            let project = try ProjectPersistence.load(from: url)
            projectViewModel.loadProject(project)
            audioEngine.updateWavetable(
                frames: project.generatedFrames,
                sampleRate: project.sampleRate,
                samplesPerFrame: project.samplesPerFrame
            )
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
