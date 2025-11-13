//
//  AudioPreviewView.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import SwiftUI

struct AudioPreviewView: View {
    @ObservedObject var audioEngine: AudioEngine
    @StateObject private var midiManager = MIDIManager()
    @State private var holdNote = false
    @State private var droneNote: Int = 60 // C4
    @State private var isDronePlaying = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Audio Preview")
                .font(.headline)
            
            // MIDI Device Selector
            VStack(alignment: .leading, spacing: 4) {
                Text("MIDI Input")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: Binding(
                    get: { midiManager.selectedDevice },
                    set: { if let device = $0 { midiManager.selectDevice(device) } }
                )) {
                    Text("None").tag(nil as MIDIManager.MIDIDeviceInfo?)
                    ForEach(midiManager.availableDevices) { device in
                        Text(device.name).tag(device as MIDIManager.MIDIDeviceInfo?)
                    }
                }
                .pickerStyle(.menu)
                
                if let note = audioEngine.currentMIDINote {
                    Text("Note: \(midiNoteName(note))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Drone Note Control
            HStack {
                Text("Drone Note:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $droneNote) {
                    ForEach(36..<84) { note in // C2 to C6
                        Text(midiNoteName(note)).tag(note)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 80)
                
                Button(action: {
                    if isDronePlaying {
                        audioEngine.noteOff(note: droneNote)
                        isDronePlaying = false
                    } else {
                        audioEngine.noteOn(note: droneNote, velocity: 0.7)
                        isDronePlaying = true
                    }
                }) {
                    Image(systemName: isDronePlaying ? "stop.fill" : "play.fill")
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.bordered)
            }
            
            // Play/Stop controls
            HStack {
                Button(action: {
                    if audioEngine.isPlaying {
                        audioEngine.stop()
                    } else {
                        audioEngine.play()
                    }
                }) {
                    Image(systemName: audioEngine.isPlaying ? "stop.fill" : "play.fill")
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.borderedProminent)
                
                Toggle("Hold Note", isOn: $holdNote)
                    .onChange(of: holdNote) { _, newValue in
                        if newValue {
                            audioEngine.play()
                        } else {
                            audioEngine.stop()
                        }
                    }
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
            
            // Wavetable Position
            VStack(alignment: .leading, spacing: 4) {
                Text("Position")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Slider(value: $audioEngine.wavetablePosition, in: 0.0...1.0)
                Text(String(format: "%.0f%%", audioEngine.wavetablePosition * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Volume
            VStack(alignment: .leading, spacing: 4) {
                Text("Volume")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Slider(value: Binding(
                    get: { Double(audioEngine.volume) },
                    set: { audioEngine.setVolume(Float($0)) }
                ), in: 0.0...1.0)
                Text(String(format: "%.0f%%", audioEngine.volume * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Tone (simplified)
            VStack(alignment: .leading, spacing: 4) {
                Text("Tone")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Slider(value: $audioEngine.tone, in: 0.0...1.0)
            }
        }
        .padding()
        .frame(height: 250)
    }
    
    private func midiNoteName(_ note: Int) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = (note / 12) - 1
        let noteIndex = note % 12
        return "\(noteNames[noteIndex])\(octave)"
    }
}

