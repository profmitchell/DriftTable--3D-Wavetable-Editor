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
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true, options: [])
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
        
        // Don't start engine here - start it when play() is called
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
        guard !samples.isEmpty else {
            print("updateSingleCycle: samples array is empty")
            return
        }
        
        self.currentSingleCycle = samples
        self.currentFrames = [] // Clear wavetable when single cycle is set
        self.sampleRate = sampleRate
        self.samplesPerFrame = samples.count
        
        print("updateSingleCycle: Set \(samples.count) samples at \(sampleRate) Hz")
        
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
              let engine = engine else {
            print("Cannot play: no frames/single cycle or engine not ready")
            return
        }
        
        // Ensure audio session is active
        do {
            let audioSession = AVAudioSession.sharedInstance()
            if !audioSession.isOtherAudioPlaying {
                try audioSession.setActive(true, options: [])
            }
        } catch {
            print("Failed to activate audio session: \(error)")
        }
        
        // Ensure engine is running
        if !engine.isRunning {
            do {
                try engine.start()
                print("Audio engine started successfully")
            } catch {
                print("Failed to start audio engine: \(error)")
                return
            }
        }
        
        stop()
        phase = 0.0
        
        // Reset player node state
        playerNode.reset()
        
        // Use render callback for continuous audio generation
        setupRenderCallback()
        
        // Start playing
        playerNode.play()
        
        isPlaying = true
        print("Playing audio - frames: \(currentFrames.count), single cycle: \(currentSingleCycle.count), frequency: \(frequency) Hz, volume: \(volume)")
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
        // Schedule multiple buffers ahead to prevent gaps
        for _ in 0..<3 {
            scheduleNextBuffer()
        }
    }
    
    private func scheduleNextBuffer() {
        guard let playerNode = playerNode,
              isPlaying else {
            print("scheduleNextBuffer: Not playing or no player node")
            return
        }
        
        let buffer = generateAudioBufferWithPhase()
        
        // Schedule buffer and continue scheduling when it completes
        playerNode.scheduleBuffer(buffer, at: nil, options: []) { [weak self] in
            // Schedule next buffer on main thread
            DispatchQueue.main.async {
                if self?.isPlaying == true {
                    self?.scheduleNextBuffer()
                }
            }
        }
    }
    
    private func generateAudioBufferWithPhase() -> AVAudioPCMBuffer {
        guard let format = renderFormat else {
            print("ERROR: Audio format not initialized")
            fatalError("Audio format not initialized")
        }
        
        let frameCount = AVAudioFrameCount(512) // Smaller buffers for lower latency
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("ERROR: Failed to create audio buffer")
            fatalError("Failed to create audio buffer")
        }
        
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData else {
            print("ERROR: No channel data")
            return buffer
        }
        
        let channelPointer = channelData[0]
        
        guard !currentFrames.isEmpty || !currentSingleCycle.isEmpty else {
            print("WARNING: No frames or single cycle - filling with silence")
            // Fill with silence
            for i in 0..<Int(frameCount) {
                channelPointer[i] = 0.0
            }
            return buffer
        }
        
        // Generate audio using wavetable oscillator or single cycle
        let sampleRateFloat = Float(sampleRate)
        let phaseIncrement = frequency / sampleRateFloat
        
        var maxSample: Float = 0.0
        var minSample: Float = 0.0
        
        for i in 0..<Int(frameCount) {
            // Always generate audio when playing, regardless of note held status
            // (note held only affects whether we continue after release)
            
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
            
            let outputValue = finalValue * volume
            channelPointer[i] = outputValue
            
            maxSample = max(maxSample, abs(outputValue))
            minSample = min(minSample, abs(outputValue))
            
            // Advance phase
            phase += phaseIncrement
            if phase >= 1.0 {
                phase -= 1.0
            }
        }
        
        // Debug: log first buffer to verify audio is being generated
        if phase < phaseIncrement * 2 { // Only log first couple buffers
            print("Buffer generated: max=\(maxSample), min=\(minSample), volume=\(volume), frequency=\(frequency)")
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
