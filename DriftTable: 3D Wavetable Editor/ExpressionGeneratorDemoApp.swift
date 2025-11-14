//
//  ExpressionGeneratorDemoApp.swift
//  DriftTable
//
//  Standalone demo app for the Math Expression Generator
//  To use this as the main app, replace @main in DriftTable__3D_Wavetable_EditorApp.swift
//  with this file, or simply run WavetableEditorDemoView from your existing app.
//

import SwiftUI

// Uncomment @main below to use this as the standalone demo app
// (Remember to remove @main from DriftTable__3D_Wavetable_EditorApp.swift)
/*
@main
struct ExpressionGeneratorDemoApp: App {
    var body: some Scene {
        WindowGroup {
            WavetableEditorDemoView()
        }
    }
}
*/

// MARK: - Example: How to integrate into existing views

struct ExpressionGeneratorIntegrationExample: View {
    @State private var frames: [[Float]] = Array(
        repeating: Array(repeating: 0.0, count: 256),
        count: 8
    )
    @State private var selectedFrameIndex = 0
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Your existing wavetable editor content here")
                    .font(.headline)
                    .padding()
                
                // Simply embed the ExpressionPanelView
                ExpressionPanelView(
                    frames: $frames,
                    selectedFrameIndex: $selectedFrameIndex,
                    sampleCount: 256
                )
            }
            .navigationTitle("Wavetable Editor")
        }
    }
}

// MARK: - Quick Usage Examples

/// Example 1: Standalone expression panel in a sheet/modal
struct ExpressionSheetExample: View {
    @State private var showExpressionPanel = false
    @State private var frames: [[Float]] = Array(
        repeating: Array(repeating: 0.0, count: 256),
        count: 8
    )
    @State private var selectedFrameIndex = 0
    
    var body: some View {
        VStack {
            Button("Open Expression Generator") {
                showExpressionPanel = true
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $showExpressionPanel) {
            NavigationView {
                ExpressionPanelView(
                    frames: $frames,
                    selectedFrameIndex: $selectedFrameIndex,
                    sampleCount: 256
                )
                .navigationTitle("Expression Generator")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showExpressionPanel = false
                        }
                    }
                }
            }
        }
    }
}

/// Example 2: Programmatic usage without UI
struct ProgrammaticExpressionExample {
    func generateWaveform() {
        let engine = FormulaEngine()
        
        // Compile expression
        do {
            let compiled = try engine.compile("sin(2 * pi * x)")
            
            // Create frames
            var frames = Array(
                repeating: Array(repeating: Float(0.0), count: 256),
                count: 8
            )
            
            // Apply to single frame
            try applyExpressionSingleFrame(
                compiled: compiled,
                engine: engine,
                frames: &frames,
                selectedFrameIndex: 0,
                sampleCount: 256
            )
            
            print("Generated waveform with \(frames[0].count) samples")
            
            // Or apply to all frames with a multi-frame expression
            let multiFrameCompiled = try engine.compile("sin(2*pi*x) * (1 - y) + sign(sin(2*pi*x)) * y")
            
            try applyExpressionMultiFrame(
                compiled: multiFrameCompiled,
                engine: engine,
                frames: &frames,
                selectedFrameIndex: 0,
                sampleCount: 256
            )
            
            print("Applied multi-frame expression to \(frames.count) frames")
            
        } catch {
            print("Error: \(error)")
        }
    }
}

// MARK: - Preview

#Preview("Standalone Demo") {
    WavetableEditorDemoView()
}

#Preview("Integration Example") {
    ExpressionGeneratorIntegrationExample()
}

#Preview("Sheet Example") {
    ExpressionSheetExample()
}

