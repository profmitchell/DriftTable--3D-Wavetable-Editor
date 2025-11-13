//
//  AudioImportService.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import Foundation
import AVFoundation
import UniformTypeIdentifiers

typealias Wavetable = [[Float]] // frames[frameIndex][sampleIndex]

struct AudioImportService {
    /// Import a wavetable from an audio file URL
    /// - Parameters:
    ///   - url: The URL of the audio file to import
    ///   - samplesPerFrame: Number of samples per frame (default: 2048)
    ///   - targetSampleRate: Target sample rate for conversion (default: 44100)
    /// - Returns: A Wavetable (array of frames, each frame is an array of Float samples)
    /// - Throws: AudioImportError if the import fails
    static func importWavetableFromAudioURL(
        url: URL,
        samplesPerFrame: Int = 2048,
        targetSampleRate: Double = 44100.0
    ) throws -> Wavetable {
        // Open the audio file - let AVAudioFile handle format conversion automatically
        let audioFile: AVAudioFile
        do {
            // First try opening with common format for automatic conversion
            audioFile = try AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false)
        } catch {
            // Fallback: try opening without format specification
            do {
                audioFile = try AVAudioFile(forReading: url)
            } catch {
                throw AudioImportError.fileReadFailed(error)
            }
        }
        
        // Get the file format
        let fileFormat = audioFile.fileFormat
        let fileSampleRate = fileFormat.sampleRate
        let fileChannelCount = fileFormat.channelCount
        
        // Ensure we have valid format data
        guard fileSampleRate > 0 && fileChannelCount > 0 else {
            throw AudioImportError.invalidFormat
        }
        
        // Create target format: Mono, Float32, target sample rate
        guard let targetFormat = AVAudioFormat(
            standardFormatWithSampleRate: targetSampleRate,
            channels: 1
        ) else {
            throw AudioImportError.invalidFormat
        }
        
        // Check if sample rate conversion is needed
        let needsSampleRateConversion = abs(fileSampleRate - targetSampleRate) > 0.1
        
        // Get file length
        let fileLength = audioFile.length
        guard fileLength > 0 else {
            throw AudioImportError.insufficientSamples
        }
        
        // Read file in chunks to avoid buffer issues
        // Use a reasonable chunk size (64k frames)
        let chunkSize: AVAudioFrameCount = 65536
        var allSamples: [Float] = []
        
        // Create a format for reading chunks
        guard let readFormat = AVAudioFormat(
            standardFormatWithSampleRate: fileSampleRate,
            channels: fileChannelCount
        ) else {
            throw AudioImportError.invalidFormat
        }
        
        audioFile.framePosition = 0
        
        // Read file in chunks
        while audioFile.framePosition < fileLength {
            let remainingFrames = fileLength - audioFile.framePosition
            let framesToRead = AVAudioFrameCount(min(Int(chunkSize), Int(remainingFrames)))
            
            guard let chunkBuffer = AVAudioPCMBuffer(
                pcmFormat: readFormat,
                frameCapacity: framesToRead
            ) else {
                throw AudioImportError.bufferCreationFailed
            }
            
            chunkBuffer.frameLength = framesToRead
            
            do {
                try audioFile.read(into: chunkBuffer, frameCount: framesToRead)
            } catch {
                // If reading fails, try reading what's available
                if chunkBuffer.frameLength == 0 {
                    break
                }
            }
            
            // Extract samples from chunk
            guard let channelData = chunkBuffer.floatChannelData else {
                continue
            }
            
            let actualFrames = Int(chunkBuffer.frameLength)
            if actualFrames > 0 {
                // Mix to mono if multi-channel
                if fileChannelCount > 1 {
                    for frame in 0..<actualFrames {
                        var sum: Float = 0.0
                        for channel in 0..<Int(fileChannelCount) {
                            sum += channelData[channel][frame]
                        }
                        allSamples.append(sum / Float(fileChannelCount))
                    }
                } else {
                    // Mono - copy directly
                    let samples = Array<Float>(UnsafeBufferPointer(start: channelData[0], count: actualFrames))
                    allSamples.append(contentsOf: samples)
                }
            }
            
            // Break if we didn't read anything
            if chunkBuffer.frameLength == 0 {
                break
            }
        }
        
        guard !allSamples.isEmpty else {
            throw AudioImportError.insufficientSamples
        }
        
        // Step 2: Convert sample rate if needed
        let finalSamples: [Float]
        if needsSampleRateConversion {
            // Need sample rate conversion
            // Create mono format at file sample rate for converter input
            guard let sourceFormat = AVAudioFormat(
                standardFormatWithSampleRate: fileSampleRate,
                channels: 1
            ) else {
                throw AudioImportError.invalidFormat
            }
            
            // Create converter from source format to target format
            guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
                throw AudioImportError.conversionFailed
            }
            
            // Convert samples using converter
            let inputFrameCount = allSamples.count
            let outputFrameCount = Int(Double(inputFrameCount) * targetSampleRate / fileSampleRate)
            
            guard let inputBuffer = AVAudioPCMBuffer(
                pcmFormat: sourceFormat,
                frameCapacity: AVAudioFrameCount(inputFrameCount)
            ) else {
                throw AudioImportError.bufferCreationFailed
            }
            
            inputBuffer.frameLength = AVAudioFrameCount(inputFrameCount)
            guard let inputData = inputBuffer.floatChannelData else {
                throw AudioImportError.bufferCreationFailed
            }
            
            // Copy samples to input buffer
            for i in 0..<inputFrameCount {
                inputData[0][i] = allSamples[i]
            }
            
            guard let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: AVAudioFrameCount(outputFrameCount)
            ) else {
                throw AudioImportError.bufferCreationFailed
            }
            
            var error: NSError?
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = .haveData
                return inputBuffer
            }
            
            converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
            
            if error != nil {
                throw AudioImportError.conversionFailed
            }
            
            guard let outputData = outputBuffer.floatChannelData else {
                throw AudioImportError.bufferCreationFailed
            }
            
            let convertedCount = Int(outputBuffer.frameLength)
            finalSamples = Array(UnsafeBufferPointer(start: outputData[0], count: convertedCount))
        } else {
            // No sample rate conversion needed
            finalSamples = allSamples
        }
        
        // Extract single-cycle waveforms from the audio
        // Find cycles and create smoothly interpolated wavetable (up to 256 frames)
        let totalSamples = finalSamples.count
        let maxFrames = 256
        
        // Detect cycles by finding zero crossings
        func findZeroCrossings() -> [Int] {
            var crossings: [Int] = [0] // Start at beginning
            var lastSign: Float = finalSamples[0] >= 0 ? 1.0 : -1.0
            
            for i in 1..<totalSamples {
                let currentSign: Float = finalSamples[i] >= 0 ? 1.0 : -1.0
                if currentSign != lastSign {
                    // Found zero crossing
                    crossings.append(i)
                    lastSign = currentSign
                }
            }
            
            return crossings
        }
        
        let zeroCrossings = findZeroCrossings()
        
        // Extract cycles - each cycle is between two zero crossings
        var cycles: [[Float]] = []
        
        for i in 0..<(zeroCrossings.count - 1) {
            let start = zeroCrossings[i]
            let end = zeroCrossings[i + 1]
            let cycleLength = end - start
            
            // Only use cycles that are reasonable length (not too short, not too long)
            if cycleLength >= samplesPerFrame / 4 && cycleLength <= samplesPerFrame * 4 {
                let cycleSamples = Array(finalSamples[start..<end])
                cycles.append(cycleSamples)
            }
        }
        
        // If we didn't find enough cycles, fall back to simple slicing
        if cycles.isEmpty {
            // Simple fallback: slice into frames
            let numberOfFrames = min(totalSamples / samplesPerFrame, maxFrames)
            guard numberOfFrames > 0 else {
                throw AudioImportError.insufficientSamples
            }
            
            for frameIndex in 0..<numberOfFrames {
                let startIndex = frameIndex * samplesPerFrame
                let endIndex = min(startIndex + samplesPerFrame, totalSamples)
                var frame = Array(finalSamples[startIndex..<endIndex])
                
                if frame.count < samplesPerFrame {
                    frame.append(contentsOf: [Float](repeating: 0.0, count: samplesPerFrame - frame.count))
                }
                
                // Remove DC offset
                let dcOffset = frame.reduce(0.0, +) / Float(frame.count)
                frame = frame.map { $0 - dcOffset }
                
                // Normalize
                let maxAbs = frame.map { abs($0) }.max() ?? 0.0
                if maxAbs > 0.0 {
                    let scale = 0.95 / maxAbs
                    frame = frame.map { $0 * scale }
                }
                
                cycles.append(frame)
            }
        }
        
        // Limit to maxFrames and resample cycles to exactly samplesPerFrame
        let cyclesToUse = min(cycles.count, maxFrames)
        var wavetable: Wavetable = []
        
        for i in 0..<cyclesToUse {
            let cycle = cycles[i]
            var resampledFrame = [Float](repeating: 0.0, count: samplesPerFrame)
            
            // Resample cycle to exactly samplesPerFrame using linear interpolation
            for j in 0..<samplesPerFrame {
                let t = Float(j) / Float(samplesPerFrame - 1)
                let sourceIndex = t * Float(cycle.count - 1)
                let index0 = Int(floor(sourceIndex))
                let index1 = min(index0 + 1, cycle.count - 1)
                let fraction = sourceIndex - Float(index0)
                
                resampledFrame[j] = cycle[index0] * (1.0 - fraction) + cycle[index1] * fraction
            }
            
            // Remove DC offset
            let dcOffset = resampledFrame.reduce(0.0, +) / Float(resampledFrame.count)
            resampledFrame = resampledFrame.map { $0 - dcOffset }
            
            // Normalize
            let maxAbs = resampledFrame.map { abs($0) }.max() ?? 0.0
            if maxAbs > 0.0 {
                let scale = 0.95 / maxAbs
                resampledFrame = resampledFrame.map { $0 * scale }
            }
            
            wavetable.append(resampledFrame)
        }
        
        // Ensure we created at least one frame
        guard wavetable.count > 0 else {
            throw AudioImportError.insufficientSamples
        }
        
        return wavetable
    }
    
}

enum AudioImportError: LocalizedError {
    case fileReadFailed(Error)
    case invalidFormat
    case conversionFailed
    case bufferCreationFailed
    case insufficientSamples
    case noFileSelected
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .fileReadFailed(let error):
            return "Failed to read audio file: \(error.localizedDescription)"
        case .invalidFormat:
            return "Invalid audio format"
        case .conversionFailed:
            return "Failed to convert audio format"
        case .bufferCreationFailed:
            return "Failed to create audio buffer"
        case .insufficientSamples:
            return "Audio file is too short to create at least one frame"
        case .noFileSelected:
            return "No file was selected"
        case .userCancelled:
            return "Import cancelled by user"
        }
    }
}

