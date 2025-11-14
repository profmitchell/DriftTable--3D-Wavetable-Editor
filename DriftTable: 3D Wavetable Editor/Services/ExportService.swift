//
//  ExportService.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import Foundation
import AVFoundation

struct ExportService {
    /// Export wavetable frames as a Serum-compatible WAV file
    static func exportWavetable(frames: [[Float]], sampleRate: Double, to url: URL) throws {
        guard !frames.isEmpty else {
            throw ExportError.noFrames
        }
        
        // Normalize frames before export to ensure they're audible and within bounds
        let normalizedFrames = NormalizationService.normalizeWavetable(frames)
        
        let samplesPerFrame = normalizedFrames.first?.count ?? 2048
        
        // Create audio format
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        guard let audioFormat = format else {
            throw ExportError.invalidFormat
        }
        
        // Create audio file
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsBigEndianKey: false
        ]
        
        guard let audioFile = try? AVAudioFile(forWriting: url, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false) else {
            throw ExportError.fileCreationFailed
        }
        
        // Write frames sequentially
        for frame in normalizedFrames {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(samplesPerFrame)) else {
                continue
            }
            
            buffer.frameLength = AVAudioFrameCount(samplesPerFrame)
            
            guard let channelData = buffer.floatChannelData else {
                continue
            }
            
            let channelPointer = channelData[0]
            for (index, sample) in frame.enumerated() {
                if index < samplesPerFrame {
                    channelPointer[index] = sample
                }
            }
            
            do {
                try audioFile.write(from: buffer)
            } catch {
                throw ExportError.writeFailed(error)
            }
        }
    }
}

enum ExportError: LocalizedError {
    case noFrames
    case invalidFormat
    case fileCreationFailed
    case writeFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .noFrames:
            return "No frames to export"
        case .invalidFormat:
            return "Invalid audio format"
        case .fileCreationFailed:
            return "Failed to create audio file"
        case .writeFailed(let error):
            return "Failed to write audio data: \(error.localizedDescription)"
        }
    }
}
