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
    @State private var activeSlider: SliderControl?
    
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
                    
                    Button {
                        activeSlider = .position
                    } label: {
                        HStack {
                            Text(String(format: "%.0f%%", audioEngine.wavetablePosition * 100))
                                .font(.caption)
                            Spacer()
                            Image(systemName: "slider.horizontal.3")
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .frame(height: 30)
                    }
                    .buttonStyle(.bordered)
                }
                
                // Volume
                HStack(spacing: 8) {
                    Text("Vol")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 32, alignment: .leading)
                    
                    Button {
                        activeSlider = .volume
                    } label: {
                        HStack {
                            Text(String(format: "%.0f%%", audioEngine.volume * 100))
                                .font(.caption)
                            Spacer()
                            Image(systemName: "slider.horizontal.3")
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .frame(height: 30)
                    }
                    .buttonStyle(.bordered)
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
        .sheet(item: $activeSlider) { slider in
            switch slider {
            case .position:
                SliderSheet(
                    title: "Wavetable Position",
                    value: Binding(
                        get: { Double(audioEngine.wavetablePosition) },
                        set: { audioEngine.wavetablePosition = Float($0) }
                    ),
                    formattedValue: { value in
                        String(format: "%.0f%%", value * 100)
                    }
                )
            case .volume:
                SliderSheet(
                    title: "Volume",
                    value: Binding(
                        get: { Double(audioEngine.volume) },
                        set: { audioEngine.setVolume(Float($0)) }
                    ),
                    formattedValue: { value in
                        String(format: "%.0f%%", value * 100)
                    }
                )
            }
        }
    }
    
    private func midiNoteName(_ note: Int) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = (note / 12) - 1
        let noteIndex = note % 12
        return "\(noteNames[noteIndex])\(octave)"
    }
}

private enum SliderControl: Identifiable {
    case position
    case volume
    
    var id: Int {
        switch self {
        case .position: return 0
        case .volume: return 1
        }
    }
}

private struct SliderSheet: View {
    let title: String
    @Binding var value: Double
    var formattedValue: (Double) -> String
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.title3)
                    .bold()
                
                Slider(value: $value, in: 0...1)
                
                Text(formattedValue(value))
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
