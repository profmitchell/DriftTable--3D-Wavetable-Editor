//
//  ProjectViewModel.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import Foundation
import SwiftUI
import Combine

class ProjectViewModel: ObservableObject {
    @Published var project: WavetableProject
    @Published var selectedKeyShapeId: String?
    @Published var canUndo = false
    @Published var canRedo = false
    
    // Store original shape for tool application
    private var originalKeyShapes: [String: KeyShape] = [:]
    
    // Store base frames for real-time flow tool application
    private var baseFrames: [[Float]] = []
    
    // Undo/Redo history
    private var undoStack: [WavetableProject] = []
    private var redoStack: [WavetableProject] = []
    private let maxHistorySize = 50
    
    init(project: WavetableProject = .defaultProject()) {
        self.project = project
        self.selectedKeyShapeId = project.keyShapes.first?.id
        // Store originals
        for shape in project.keyShapes {
            originalKeyShapes[shape.id] = shape
        }
        // Store base frames for real-time flow tools
        baseFrames = project.generatedFrames
        // Save initial state (but don't include it in undo stack if it's empty)
        if !project.generatedFrames.isEmpty {
            saveState()
        }
    }
    
    // Undo/Redo
    private func saveState() {
        // Encode project to save state
        if let encoded = try? JSONEncoder().encode(project),
           let decoded = try? JSONDecoder().decode(WavetableProject.self, from: encoded) {
            undoStack.append(decoded)
            if undoStack.count > maxHistorySize {
                undoStack.removeFirst()
            }
            redoStack.removeAll()
            updateUndoRedoState()
        }
    }
    
    private func updateUndoRedoState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
    
    func undo() {
        guard !undoStack.isEmpty else { return }
        
        // Save current state to redo stack
        if let encoded = try? JSONEncoder().encode(project),
           let decoded = try? JSONDecoder().decode(WavetableProject.self, from: encoded) {
            redoStack.append(decoded)
        }
        
        // Restore previous state
        let previousState = undoStack.removeLast()
        project = previousState
        // Update base frames for real-time flow tools
        baseFrames = project.generatedFrames
        updateUndoRedoState()
    }
    
    func redo() {
        guard !redoStack.isEmpty else { return }
        
        // Save current state to undo stack
        if let encoded = try? JSONEncoder().encode(project),
           let decoded = try? JSONDecoder().decode(WavetableProject.self, from: encoded) {
            undoStack.append(decoded)
        }
        
        // Restore next state
        let nextState = redoStack.removeLast()
        project = nextState
        // Update base frames for real-time flow tools
        baseFrames = project.generatedFrames
        updateUndoRedoState()
    }
    
    private func performChange(_ change: () -> Void) {
        change()
        // Ensure baseFrames is updated if frames changed
        if baseFrames.isEmpty && !project.generatedFrames.isEmpty {
            baseFrames = project.generatedFrames
        }
        saveState()
    }
    
    // Load a project (used when opening a file)
    func loadProject(_ project: WavetableProject) {
        self.project = project
        self.selectedKeyShapeId = project.keyShapes.first?.id
        // Store originals
        originalKeyShapes.removeAll()
        for shape in project.keyShapes {
            originalKeyShapes[shape.id] = shape
        }
        // Store base frames for real-time flow tools
        baseFrames = project.generatedFrames
        // Reset undo/redo stacks
        undoStack.removeAll()
        redoStack.removeAll()
        updateUndoRedoState()
        // Save initial state if there are frames
        if !project.generatedFrames.isEmpty {
            saveState()
        }
    }
    
    var currentKeyShape: KeyShape? {
        if let selectedId = selectedKeyShapeId {
            return project.keyShapes.first { $0.id == selectedId }
        }
        return project.keyShapes.first
    }
    
    func selectKeyShape(_ id: String) {
        selectedKeyShapeId = id
        // Store original when selecting
        if let shape = project.keyShapes.first(where: { $0.id == id }) {
            originalKeyShapes[id] = shape
        }
    }
    
    func updateCurrentKeyShape(_ updatedShape: KeyShape) {
        guard let index = project.keyShapes.firstIndex(where: { $0.id == updatedShape.id }) else {
            return
        }
        performChange {
            project.keyShapes[index] = updatedShape
        }
    }
    
    func getOriginalKeyShape(id: String) -> KeyShape? {
        return originalKeyShapes[id]
    }
    
    func resetKeyShape(id: String) {
        guard let original = originalKeyShapes[id],
              let index = project.keyShapes.firstIndex(where: { $0.id == id }) else {
            return
        }
        project.keyShapes[index] = original
        originalKeyShapes[id] = original // Update stored original
    }
    
    func updateOriginalKeyShape(id: String, shape: KeyShape) {
        originalKeyShapes[id] = shape
    }
    
    // Key Shape management
    func addKeyShape() {
        let nextId = nextAvailableKeyShapeId()
        let newShape = KeyShape.sine(id: nextId)
        performChange {
            project.keyShapes.append(newShape)
        }
        originalKeyShapes[nextId] = newShape
        selectedKeyShapeId = nextId
    }
    
    func duplicateKeyShape(_ id: String) {
        guard let shape = project.keyShapes.first(where: { $0.id == id }) else { return }
        let newId = nextAvailableKeyShapeId()
        var duplicated = shape
        duplicated = KeyShape(id: newId, samples: shape.samples)
        performChange {
            project.keyShapes.append(duplicated)
        }
        originalKeyShapes[newId] = duplicated
        selectedKeyShapeId = newId
    }
    
    func deleteKeyShape(_ id: String) {
        performChange {
            project.keyShapes.removeAll { $0.id == id }
        }
        originalKeyShapes.removeValue(forKey: id)
        if selectedKeyShapeId == id {
            selectedKeyShapeId = project.keyShapes.first?.id
        }
    }
    
    private func nextAvailableKeyShapeId() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        for letter in letters {
            let id = String(letter)
            if !project.keyShapes.contains(where: { $0.id == id }) {
                return id
            }
        }
        return "\(project.keyShapes.count + 1)"
    }
    
    // Morphing
    func generateFrames() {
        guard project.keyShapes.count >= 2 else { return }
        
        performChange {
            var frames = MorphService.generateFrames(
                from: project.keyShapes,
                settings: project.morphSettings,
                samplesPerFrame: project.samplesPerFrame
            )
            
            // Normalize frames to ensure they're audible and within bounds
            frames = NormalizationService.normalizeWavetable(frames)
            
            project.generatedFrames = frames
            project.frameCount = frames.count
            // Store as base frames for real-time flow tools
            baseFrames = frames
        }
    }
    
    // Normalize frames manually
    func normalizeFrames() {
        guard !project.generatedFrames.isEmpty else { return }
        performChange {
            project.generatedFrames = NormalizationService.normalizeWavetable(project.generatedFrames)
        }
    }
    
    // Flow tools
    func applyFlowTool(_ tool: FlowTool, settings: FlowToolSettings, gradient: FrameGradient, seed: UInt64 = 12345, saveToHistory: Bool = true) {
        guard !project.generatedFrames.isEmpty else { return }
        
        let changeBlock = {
            // For real-time updates, use base frames if available; otherwise use current frames
            let sourceFrames = self.baseFrames.isEmpty ? self.project.generatedFrames : self.baseFrames
            
            var modifiedFrames = FlowService.applyFlow(
                to: sourceFrames,
                tool: tool,
                settings: settings,
                gradient: gradient,
                seed: seed
            )
            
            // Normalize after flow tool to ensure frames stay audible and within bounds
            modifiedFrames = NormalizationService.normalizeWavetable(modifiedFrames)
            
            self.project.generatedFrames = modifiedFrames
            
            // Update base frames when saving to history (commit the change)
            if saveToHistory {
                self.baseFrames = modifiedFrames
            }
        }
        
        if saveToHistory {
            performChange(changeBlock)
        } else {
            changeBlock()
        }
    }
    
    // Apply shape tool globally to all frames
    func applyShapeToolGlobally(_ tool: Tool, toolsViewModel: ToolsViewModel, saveToHistory: Bool = true) {
        guard !project.generatedFrames.isEmpty else { return }
        
        let changeBlock = {
            // For real-time updates, use base frames if available
            let sourceFrames = self.baseFrames.isEmpty ? self.project.generatedFrames : self.baseFrames
            
            var modifiedFrames: [[Float]] = []
            
            for frame in sourceFrames {
                // Convert frame to KeyShape temporarily
                let tempShape = KeyShape(id: "temp", samples: frame)
                let modifiedShape = toolsViewModel.applyCurrentTool(to: tempShape)
                modifiedFrames.append(modifiedShape.samples)
            }
            
            // Normalize after global shape tool application
            modifiedFrames = NormalizationService.normalizeWavetable(modifiedFrames)
            
            self.project.generatedFrames = modifiedFrames
            
            // Update base frames when saving to history (commit the change)
            if saveToHistory {
                self.baseFrames = modifiedFrames
            }
        }
        
        if saveToHistory {
            performChange(changeBlock)
        } else {
            changeBlock()
        }
    }
    
    // Audio import
    /// Import audio file as wavetable and update the project
    /// - Parameters:
    ///   - samplesPerFrame: Number of samples per frame (defaults to project's samplesPerFrame)
    ///   - targetSampleRate: Target sample rate (defaults to project's sampleRate)
    ///   - completion: Completion handler called with Result<Void, Error>
    func importAudioAsWavetable(
        samplesPerFrame: Int? = nil,
        targetSampleRate: Double? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // This function is deprecated - use importAudioFromURL instead
        // File picker is handled in MainWindowView
        completion(.failure(NSError(domain: "ProjectViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Use importAudioFromURL instead"])))
    }
    
    /// Import audio file from URL as wavetable and update the project
    /// - Parameters:
    ///   - url: The URL of the audio file to import
    ///   - samplesPerFrame: Number of samples per frame (defaults to project's samplesPerFrame)
    ///   - targetSampleRate: Target sample rate (defaults to project's sampleRate)
    ///   - completion: Completion handler called with Result<Void, Error>
    func importAudioFromURL(
        _ url: URL,
        samplesPerFrame: Int? = nil,
        targetSampleRate: Double? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let frameSize = samplesPerFrame ?? project.samplesPerFrame
        let sampleRate = targetSampleRate ?? project.sampleRate
        
        do {
            let wavetable = try AudioImportService.importWavetableFromAudioURL(
                url: url,
                samplesPerFrame: frameSize,
                targetSampleRate: sampleRate
            )
            
            // Update project with imported wavetable
            performChange {
                self.project.generatedFrames = wavetable
                self.project.frameCount = wavetable.count
                self.project.samplesPerFrame = frameSize
                self.project.sampleRate = sampleRate
                // Store as base frames for real-time flow tools
                self.baseFrames = wavetable
            }
            completion(.success(()))
            
        } catch {
            completion(.failure(error))
        }
    }
}

