//
//  AudioEngine.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import Foundation
import AVFoundation
import Combine

class AudioEngine: ObservableObject {
    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var mixerNode: AVAudioMixerNode?
    
    @Published var isPlaying = false
    @Published var volume: Float = 0.7
    @Published var wavetablePosition: Float = 0.5
    @Published var tone: Float = 0.5 // Lowpass filter cutoff
    @Published var currentMIDINote: Int?
    
    var hasFrames: Bool {
        !currentFrames.isEmpty || !currentSingleCycle.isEmpty
    }
    
    private var currentFrames: [[Float]] = []
    private var currentSingleCycle: [Float] = [] // For single cycle waveform preview
    private var sampleRate: Double = 44100.0
    private var samplesPerFrame: Int = 2048
    
    private var renderFormat: AVAudioFormat?
    private var phase: Float = 0.0
    private var frequency: Float = 440.0 // A4
    private var isNoteHeld = false
    
    init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        // Configure audio session for iOS
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        
        engine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        mixerNode = AVAudioMixerNode()
        
        guard let engine = engine,
              let playerNode = playerNode,
              let mixerNode = mixerNode else { return }
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        renderFormat = format
        
        engine.attach(playerNode)
        engine.attach(mixerNode)
        
        engine.connect(playerNode, to: mixerNode, format: format)
        engine.connect(mixerNode, to: engine.mainMixerNode, format: format)
        
        mixerNode.volume = volume
        
        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func updateWavetable(frames: [[Float]], sampleRate: Double, samplesPerFrame: Int) {
        self.currentFrames = frames
        self.currentSingleCycle = [] // Clear single cycle when wavetable is set
        self.sampleRate = sampleRate
        self.samplesPerFrame = samplesPerFrame
        
        // Update render format if sample rate changed
        if let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) {
            renderFormat = format
        }
        
        if isPlaying {
            stop()
            play()
        }
    }
    
    func updateSingleCycle(_ samples: [Float], sampleRate: Double) {
        self.currentSingleCycle = samples
        self.currentFrames = [] // Clear wavetable when single cycle is set
        self.sampleRate = sampleRate
        self.samplesPerFrame = samples.count
        
        // Update render format if sample rate changed
        if let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) {
            renderFormat = format
        }
        
        if isPlaying {
            stop()
            play()
        }
    }
    
    func play() {
        guard (!currentFrames.isEmpty || !currentSingleCycle.isEmpty),
              let playerNode = playerNode,
              let engine = engine else { return }
        
        // Ensure engine is running
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("Failed to start audio engine: \(error)")
                return
            }
        }
        
        stop()
        phase = 0.0
        
        // Use render callback for continuous audio generation
        setupRenderCallback()
        playerNode.play()
        
        isPlaying = true
    }
    
    func stop() {
        playerNode?.stop()
        isPlaying = false
        isNoteHeld = false
        currentMIDINote = nil
    }
    
    func noteOn(note: Int, velocity: Float) {
        currentMIDINote = note
        frequency = midiNoteToFrequency(note)
        isNoteHeld = true
        
        if !isPlaying {
            play()
        }
    }
    
    func noteOff(note: Int) {
        if currentMIDINote == note {
            isNoteHeld = false
            currentMIDINote = nil
            // Don't stop immediately - let note release naturally
        }
    }
    
    private func midiNoteToFrequency(_ note: Int) -> Float {
        return 440.0 * pow(2.0, Float(note - 69) / 12.0)
    }
    
    private func setupRenderCallback() {
        // Schedule buffers continuously
        scheduleNextBuffer()
    }
    
    private func scheduleNextBuffer() {
        guard let playerNode = playerNode,
              isPlaying else { return }
        
        let buffer = generateAudioBufferWithPhase()
        playerNode.scheduleBuffer(buffer, at: nil, options: []) { [weak self] in
            if self?.isPlaying == true {
                self?.scheduleNextBuffer()
            }
        }
    }
    
    private func generateAudioBufferWithPhase() -> AVAudioPCMBuffer {
        guard let format = renderFormat else {
            fatalError("Audio format not initialized")
        }
        
        let frameCount = AVAudioFrameCount(512) // Smaller buffers for lower latency
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            fatalError("Failed to create audio buffer")
        }
        
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData else {
            return buffer
        }
        
        let channelPointer = channelData[0]
        
        guard !currentFrames.isEmpty || !currentSingleCycle.isEmpty else {
            return buffer
        }
        
        // Generate audio using wavetable oscillator or single cycle
        let sampleRateFloat = Float(sampleRate)
        let phaseIncrement = frequency / sampleRateFloat
        
        for i in 0..<Int(frameCount) {
            if !isNoteHeld && !isPlaying {
                channelPointer[i] = 0.0
                continue
            }
            
            let finalValue: Float
            
            if !currentSingleCycle.isEmpty {
                // Single cycle waveform playback
                let sampleIndex = Int(phase * Float(currentSingleCycle.count)) % currentSingleCycle.count
                let sampleIndex1 = (sampleIndex + 1) % currentSingleCycle.count
                let sampleT = (phase * Float(currentSingleCycle.count)) - Float(sampleIndex)
                
                let sample0 = currentSingleCycle[sampleIndex]
                let sample1 = currentSingleCycle[sampleIndex1]
                finalValue = sample0 + (sample1 - sample0) * sampleT
            } else {
                // Wavetable playback
                // Select frame based on wavetable position
                let frameIndex = wavetablePosition * Float(currentFrames.count - 1)
                let frameIndex0 = Int(floor(frameIndex))
                let frameIndex1 = min(frameIndex0 + 1, currentFrames.count - 1)
                let frameT = frameIndex - Float(frameIndex0)
                
                // Get samples from current frame
                let frame0 = currentFrames[frameIndex0]
                let frame1 = currentFrames[frameIndex1]
                
                // Interpolate within frame based on phase
                let sampleIndex = Int(phase * Float(frame0.count)) % frame0.count
                let sampleIndex1 = (sampleIndex + 1) % frame0.count
                
                let sample0 = frame0[sampleIndex]
                let sample1 = frame0[sampleIndex1]
                let sampleT = (phase * Float(frame0.count)) - Float(sampleIndex)
                
                // Interpolate between frames
                let value0 = sample0 + (sample1 - sample0) * sampleT
                let value1 = frame1[sampleIndex] + (frame1[sampleIndex1] - frame1[sampleIndex]) * sampleT
                finalValue = value0 + (value1 - value0) * frameT
            }
            
            channelPointer[i] = finalValue * volume
            
            // Advance phase
            phase += phaseIncrement
            if phase >= 1.0 {
                phase -= 1.0
            }
        }
        
        return buffer
    }
    
    func setVolume(_ value: Float) {
        volume = value
        mixerNode?.volume = value
    }
    
    deinit {
        stop()
        engine?.stop()
    }
}
