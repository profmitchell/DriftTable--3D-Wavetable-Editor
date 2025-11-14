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
        VStack(spacing: 12) {
            // Main controls row
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
                        .font(.title3)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!audioEngine.hasFrames)
                
                // Drone note
                HStack(spacing: 8) {
                    Picker("", selection: $droneNote) {
                        ForEach(36..<84) { note in
                            Text(midiNoteName(note)).tag(note)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 70)
                    
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
                            .font(.caption)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!audioEngine.hasFrames)
                }
                
                Spacer()
                
                // MIDI indicator
                if let note = audioEngine.currentMIDINote {
                    Text(midiNoteName(note))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(6)
                }
            }
            
            // Sliders - compact layout
            VStack(spacing: 8) {
                // Position
                HStack(spacing: 8) {
                    Text("Pos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 32, alignment: .leading)
                    Slider(value: $audioEngine.wavetablePosition, in: 0.0...1.0)
                    Text(String(format: "%.0f%%", audioEngine.wavetablePosition * 100))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 35, alignment: .trailing)
                }
                
                // Volume
                HStack(spacing: 8) {
                    Text("Vol")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 32, alignment: .leading)
                    Slider(value: Binding(
                        get: { Double(audioEngine.volume) },
                        set: { audioEngine.setVolume(Float($0)) }
                    ), in: 0.0...1.0)
                    Text(String(format: "%.0f%%", audioEngine.volume * 100))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 35, alignment: .trailing)
                }
            }
            
            // MIDI input (compact)
            HStack(spacing: 8) {
                Text("MIDI")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("", selection: Binding(
                    get: { midiManager.selectedDevice },
                    set: { midiManager.selectDevice($0) }
                )) {
                    Text("None").tag(nil as MIDIManager.MIDIDeviceInfo?)
                    ForEach(midiManager.availableDevices) { device in
                        Text(device.name).tag(device as MIDIManager.MIDIDeviceInfo?)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
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
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private func midiNoteName(_ note: Int) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = (note / 12) - 1
        let noteIndex = note % 12
        return "\(noteNames[noteIndex])\(octave)"
    }
}

