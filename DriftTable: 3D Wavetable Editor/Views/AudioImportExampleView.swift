//
//  AudioImportExampleView.swift
//  DriftTable
//
//  Example view showing how to use AudioImportService
//  This is a reference implementation - integrate into your main UI as needed
//

import SwiftUI

struct AudioImportExampleView: View {
    @ObservedObject var projectViewModel: ProjectViewModel
    @State private var isImporting = false
    @State private var importError: Error?
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
                importAudio()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import Audio as Wavetable")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isImporting)
            
            if isImporting {
                ProgressView()
                    .progressViewStyle(.circular)
            }
            
            if !projectViewModel.project.generatedFrames.isEmpty {
                Text("Imported: \(projectViewModel.project.frameCount) frames")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .alert("Import Error", isPresented: $showError, presenting: importError) { error in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
    
    private func importAudio() {
        isImporting = true
        importError = nil
        
        projectViewModel.importAudioAsWavetable { result in
            isImporting = false
            
            switch result {
            case .success:
                // Import successful - wavetable is now in projectViewModel.project.generatedFrames
                print("Successfully imported \(projectViewModel.project.frameCount) frames")
                
            case .failure(let error):
                importError = error
                showError = true
                print("Import failed: \(error.localizedDescription)")
            }
        }
    }
}

// Alternative: Direct URL import (e.g., from drag & drop)
extension ProjectViewModel {
    /// Example: Import from a dropped file URL
    func handleDroppedAudioURL(_ url: URL) {
        importAudioFromURL(url) { result in
            switch result {
            case .success:
                print("Successfully imported from URL")
            case .failure(let error):
                print("Import failed: \(error.localizedDescription)")
            }
        }
    }
}

