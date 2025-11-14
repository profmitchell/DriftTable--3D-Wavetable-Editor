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
    @State private var activeSlider: SliderType?
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if showExpandedControls {
                    expandedControlsView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                compactDockView
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 8)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 80)
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
        VStack(spacing: 8) {
            // Top row: Play, Note selector, and MIDI
            HStack(spacing: 10) {
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
                        .frame(width: 54, height: 54)
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
                    HStack(spacing: 4) {
                        Text(midiNoteName(droneNote))
                            .font(.system(size: 15, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .frame(minWidth: 70)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                
                // Position control button
                Button {
                    activeSlider = .position
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .font(.system(size: 11))
                        Text(String(format: "%.0f%%", audioEngine.wavetablePosition * 100))
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.accentColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                // Volume control button
                Button {
                    activeSlider = .volume
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 11))
                        Text(String(format: "%.0f%%", audioEngine.volume * 100))
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.accentColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
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
                        Image(systemName: "pianokeys")
                            .font(.system(size: 14))
                            .foregroundColor(audioEngine.currentMIDINote != nil ? .accentColor : .secondary)
                        Text("MIDI")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 50, height: 50)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            // Modern glass morphism effect
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 0)
        .overlay {
            if let slider = activeSlider {
                ZStack {
                    Color.black.opacity(0.001)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: dismissSlider)
                    SliderOverlayCard(
                        slider: slider,
                        value: binding(for: slider),
                        formattedValue: { value in String(format: "%.0f%%", value * 100) },
                        onClose: dismissSlider
                    )
                    .offset(y: -120)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
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
    
    private func binding(for slider: SliderType) -> Binding<Double> {
        switch slider {
        case .position:
            return Binding(
                get: { Double(audioEngine.wavetablePosition) },
                set: { audioEngine.wavetablePosition = Float($0) }
            )
        case .volume:
            return Binding(
                get: { Double(audioEngine.volume) },
                set: { audioEngine.setVolume(Float($0)) }
            )
        }
    }
    
    private func dismissSlider() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            activeSlider = nil
        }
    }
}

private enum SliderType: Identifiable {
    case position
    case volume
    
    var id: Int {
        switch self {
        case .position: return 0
        case .volume: return 1
        }
    }
    
    var title: String {
        switch self {
        case .position: return "Wavetable Position"
        case .volume: return "Volume"
        }
    }
    
    var icon: String {
        switch self {
        case .position: return "waveform"
        case .volume: return "speaker.wave.2.fill"
        }
    }
}

private struct SliderOverlayCard: View {
    let slider: SliderType
    @Binding var value: Double
    var formattedValue: (Double) -> String
    var onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label(slider.title, systemImage: slider.icon)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Slider(value: $value, in: 0...1)
                .tint(.accentColor)
            
            Text(formattedValue(value))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.2))
        )
    }
}
