//
//  FloatingControlDock.swift
//  DriftTable: 3D Wavetable Editor
//
//  Created by Mitchell Cohen on 11/12/25.
//

import SwiftUI

struct FloatingControlDock: View {
    @ObservedObject var audioEngine: AudioEngine
    @StateObject private var midiManager = MIDIManager()
    @State private var droneNote: Int = 60 // C4
    @State private var isDronePlaying = false
    @State private var showExpandedControls = false
    
    var body: some View {
        VStack(spacing: 0) {
            if showExpandedControls {
                expandedControlsView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            compactDockView
        }
        .onAppear {
            midiManager.setNoteHandlers(
                onNoteOn: { note, velocity in
                    audioEngine.noteOn(note: note, velocity: velocity)
                },
                onNoteOff: { note in
                    audioEngine.noteOff(note: note)
                }
            )
        }
    }
    
    private var compactDockView: some View {
        HStack(spacing: 12) {
            // Play button
            Button(action: {
                if audioEngine.isPlaying {
                    audioEngine.stop()
                } else {
                    audioEngine.play()
                }
            }) {
                Image(systemName: audioEngine.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!audioEngine.hasFrames)
            
            // Note selector
            Menu {
                ForEach(36..<84) { note in
                    Button(action: {
                        droneNote = note
                    }) {
                        HStack {
                            Text(midiNoteName(note))
                            if droneNote == note {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(midiNoteName(droneNote))
                        .font(.system(size: 15, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                }
                .frame(width: 60)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            
            // Position slider (compact)
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Slider(value: $audioEngine.wavetablePosition, in: 0.0...1.0)
                    .tint(.accentColor)
                Text(String(format: "%.0f%%", audioEngine.wavetablePosition * 100))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 38, alignment: .trailing)
            }
            
            // Volume slider (compact)
            HStack(spacing: 6) {
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Slider(value: Binding(
                    get: { Double(audioEngine.volume) },
                    set: { audioEngine.setVolume(Float($0)) }
                ), in: 0.0...1.0)
                    .tint(.accentColor)
                Text(String(format: "%.0f%%", audioEngine.volume * 100))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 38, alignment: .trailing)
            }
            
            // MIDI indicator/selector
            Menu {
                Text("MIDI Input")
                    .font(.headline)
                Divider()
                Button(action: {
                    midiManager.selectDevice(nil)
                }) {
                    HStack {
                        Text("None")
                        if midiManager.selectedDevice == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                ForEach(midiManager.availableDevices) { device in
                    Button(action: {
                        midiManager.selectDevice(device)
                    }) {
                        HStack {
                            Text(device.name)
                            if midiManager.selectedDevice?.id == device.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                VStack(spacing: 2) {
                    if let note = audioEngine.currentMIDINote {
                        Text(midiNoteName(note))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.accentColor)
                    } else {
                        Image(systemName: "pianokeys")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    Text("MIDI")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            
            // Expand/collapse button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showExpandedControls.toggle()
                }
            }) {
                Image(systemName: showExpandedControls ? "chevron.down" : "chevron.up")
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            // Modern glass morphism effect
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private var expandedControlsView: some View {
        VStack(spacing: 12) {
            Divider()
            
            // Drone play button
            HStack {
                Text("Drone")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    if isDronePlaying {
                        audioEngine.noteOff(note: droneNote)
                        isDronePlaying = false
                    } else {
                        audioEngine.noteOn(note: droneNote, velocity: 0.7)
                        isDronePlaying = true
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isDronePlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 12))
                        Text(isDronePlaying ? "Stop" : "Play")
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .disabled(!audioEngine.hasFrames)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .padding(.horizontal, 16)
    }
    
    private func midiNoteName(_ note: Int) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = (note / 12) - 1
        let noteIndex = note % 12
        return "\(noteNames[noteIndex])\(octave)"
    }
}

