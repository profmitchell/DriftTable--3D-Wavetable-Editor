//
//  WavetablePreviewView.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import SwiftUI
import UIKit

struct WavetablePreviewView: View {
    let frames: [[Float]]
    let samplesPerFrame: Int
    @Binding var position: Float // Position slider value (0.0 to 1.0)
    @State private var viewMode: ViewMode = .twoD
    
    enum ViewMode {
        case twoD
        case threeD
    }
    
    init(frames: [[Float]], samplesPerFrame: Int = 2048, position: Binding<Float>) {
        self.frames = frames
        self.samplesPerFrame = samplesPerFrame
        self._position = position
    }
    
    private var currentFrameIndex: Int {
        guard !frames.isEmpty else { return 0 }
        let index = Int(position * Float(frames.count - 1))
        return max(0, min(index, frames.count - 1))
    }
    
    private var currentFrame: [Float] {
        guard !frames.isEmpty, currentFrameIndex < frames.count else { return [] }
        return frames[currentFrameIndex]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Mode selector
            HStack {
                Picker("", selection: $viewMode) {
                    Text("2D").tag(ViewMode.twoD)
                    Text("3D").tag(ViewMode.threeD)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
                
                Spacer()
                
                if viewMode == .twoD {
                    Text("Frame \(currentFrameIndex + 1) of \(frames.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Drag to orbit • Scroll to zoom")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
            
            // Content view
            if viewMode == .twoD {
                GeometryReader { geometry in
                    SingleFrameCanvas(
                        samples: currentFrame,
                        size: geometry.size
                    )
                }
            } else {
                WavetableSceneView(
                    frames: frames,
                    currentFrameIndex: currentFrameIndex,
                    frameSpacing: 0.02 // Much closer spacing
                )
            }
        }
    }
}

struct SingleFrameCanvas: UIViewRepresentable {
    let samples: [Float]
    let size: CGSize
    
    func makeUIView(context: Context) -> UIView {
        let view = SingleFrameUIView()
        view.samples = samples
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let frameView = uiView as? SingleFrameUIView else { return }
        frameView.samples = samples
        frameView.setNeedsDisplay()
    }
}

class SingleFrameUIView: UIView {
    var samples: [Float] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard !samples.isEmpty else { return }
        
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        let width = bounds.width
        let height = bounds.height
        
        // Draw black background
        UIColor.black.setFill()
        ctx.fill(bounds)
        
        // Draw waveform
        drawWaveform(in: ctx, width: width, height: height)
    }
    
    private func drawWaveform(in context: CGContext, width: CGFloat, height: CGFloat) {
        guard !samples.isEmpty else { return }
        
        let centerY = height / 2.0
        let amplitude = height * 0.4 // Use more of the screen
        
        // Use bright blue with glow effect
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(2.0) // Thicker lines
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        let path = CGMutablePath()
        var firstPoint = true
        
        for (index, sample) in samples.enumerated() {
            let x = width * CGFloat(index) / CGFloat(samples.count - 1)
            let y = centerY - CGFloat(sample) * amplitude
            
            if firstPoint {
                path.move(to: CGPoint(x: x, y: y))
                firstPoint = false
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        // Draw glow effect (multiple passes with increasing blur)
        context.setShadow(offset: .zero, blur: 8.0, color: UIColor.systemBlue.withAlphaComponent(0.8).cgColor)
        context.addPath(path)
        context.strokePath()
        
        // Draw main line
        context.setShadow(offset: .zero, blur: 0, color: nil)
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(2.0)
        context.addPath(path)
        context.strokePath()
    }
}
