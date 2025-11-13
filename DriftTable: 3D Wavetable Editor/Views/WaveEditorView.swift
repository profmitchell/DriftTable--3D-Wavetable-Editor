//
//  WaveEditorView.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import SwiftUI
import UIKit

struct WaveEditorView: View {
    let samples: [Float]
    let samplesPerFrame: Int
    let selectedTool: Tool
    let toolsViewModel: ToolsViewModel
    let onSamplesChanged: ([Float]) -> Void
    
    @State private var isDragging = false
    @State private var dragLocation: CGPoint?
    
    init(samples: [Float], 
         samplesPerFrame: Int = 2048,
         selectedTool: Tool,
         toolsViewModel: ToolsViewModel,
         onSamplesChanged: @escaping ([Float]) -> Void) {
        self.samples = samples
        self.samplesPerFrame = samplesPerFrame
        self.selectedTool = selectedTool
        self.toolsViewModel = toolsViewModel
        self.onSamplesChanged = onSamplesChanged
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(UIColor.systemBackground)
                
                // Grid and waveform
                WaveformCanvas(
                    samples: samples,
                    size: geometry.size,
                    selectedTool: selectedTool,
                    dragLocation: dragLocation,
                    isDragging: isDragging
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            dragLocation = value.location
                            handleDrag(at: value.location, in: geometry.size)
                        }
                        .onEnded { _ in
                            isDragging = false
                            dragLocation = nil
                        }
                )
                .onTapGesture { location in
                    handleTap(at: location, in: geometry.size)
                }
            }
        }
    }
    
    private func handleTap(at location: CGPoint, in size: CGSize) {
        guard selectedTool == .pinch else { return }
        
        let normalizedX = Float(location.x / size.width)
        let clampedX = max(0.0, min(1.0, normalizedX))
        toolsViewModel.pinchPosition = clampedX
        
        // Apply pinch tool
        let modified = toolsViewModel.applyPinch(
            to: KeyShape(id: "temp", samples: samples),
            position: clampedX,
            strength: toolsViewModel.pinchStrength
        )
        onSamplesChanged(modified.samples)
    }
    
    private func handleDrag(at location: CGPoint, in size: CGSize) {
        let normalizedX = Float(location.x / size.width)
        let clampedX = max(0.0, min(1.0, normalizedX))
        
        let modified: KeyShape
        if selectedTool == .smoothBrush {
            modified = toolsViewModel.applySmoothBrush(
                to: KeyShape(id: "temp", samples: samples),
                at: clampedX,
                size: toolsViewModel.smoothBrushSize,
                strength: toolsViewModel.smoothBrushStrength
            )
        } else if selectedTool == .gritBrush {
            modified = toolsViewModel.applyGritBrush(
                to: KeyShape(id: "temp", samples: samples),
                at: clampedX,
                size: toolsViewModel.gritBrushSize,
                intensity: toolsViewModel.gritBrushIntensity
            )
        } else {
            return
        }
        
        onSamplesChanged(modified.samples)
    }
}

struct WaveformCanvas: UIViewRepresentable {
    let samples: [Float]
    let size: CGSize
    let selectedTool: Tool
    let dragLocation: CGPoint?
    let isDragging: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = WaveformUIView()
        view.samples = samples
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let waveformView = uiView as? WaveformUIView else { return }
        waveformView.samples = samples
        waveformView.selectedTool = selectedTool
        waveformView.dragLocation = dragLocation
        waveformView.isDragging = isDragging
        waveformView.setNeedsDisplay()
    }
}

class WaveformUIView: UIView {
    var samples: [Float] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var selectedTool: Tool = .liftDrop
    var dragLocation: CGPoint?
    var isDragging: Bool = false
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard !samples.isEmpty else { return }
        
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        let width = bounds.width
        let height = bounds.height
        let centerY = height / 2.0
        
        // Draw background
        UIColor.systemBackground.setFill()
        ctx.fill(bounds)
        
        // Draw grid
        drawGrid(in: ctx, width: width, height: height, centerY: centerY)
        
        // Draw zero line
        drawZeroLine(in: ctx, width: width, centerY: centerY)
        
        // Draw waveform
        drawWaveform(in: ctx, width: width, height: height, centerY: centerY)
        
        // Draw tool-specific overlays
        drawToolOverlays(in: ctx, width: width, height: height, centerY: centerY)
    }
    
    private func drawGrid(in context: CGContext, width: CGFloat, height: CGFloat, centerY: CGFloat) {
        context.setStrokeColor(UIColor.gridColor.withAlphaComponent(0.2).cgColor)
        context.setLineWidth(0.5)
        
        // Horizontal grid lines
        let horizontalLines = 5
        for i in 0..<horizontalLines {
            let y = height * CGFloat(i) / CGFloat(horizontalLines - 1)
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: width, y: y))
            context.strokePath()
        }
        
        // Vertical grid lines
        let verticalLines = 9
        for i in 0..<verticalLines {
            let x = width * CGFloat(i) / CGFloat(verticalLines - 1)
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: height))
            context.strokePath()
        }
    }
    
    private func drawZeroLine(in context: CGContext, width: CGFloat, centerY: CGFloat) {
        context.setStrokeColor(UIColor.separator.cgColor)
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: 0, y: centerY))
        context.addLine(to: CGPoint(x: width, y: centerY))
        context.strokePath()
    }
    
    private func drawWaveform(in context: CGContext, width: CGFloat, height: CGFloat, centerY: CGFloat) {
        guard samples.count > 1 else { return }
        
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(2.0)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        let sampleCount = samples.count
        let amplitude = height * 0.4 // Use 40% of height for waveform amplitude
        
        let path = CGMutablePath()
        var firstPoint = true
        
        for (index, sample) in samples.enumerated() {
            let x = width * CGFloat(index) / CGFloat(sampleCount - 1)
            let y = centerY - CGFloat(sample) * amplitude
            
            if firstPoint {
                path.move(to: CGPoint(x: x, y: y))
                firstPoint = false
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        context.addPath(path)
        context.strokePath()
    }
    
    private func drawToolOverlays(in context: CGContext, width: CGFloat, height: CGFloat, centerY: CGFloat) {
        // Draw pinch handle
        if selectedTool == .pinch {
            // This will be updated when we have access to pinch position
            // For now, draw a vertical line indicator
        }
        
        // Draw smooth brush indicator
        if selectedTool == .smoothBrush, let dragLoc = dragLocation, isDragging {
            let brushRadius = CGFloat(50.0) // Visual indicator size
            context.setFillColor(UIColor.systemBlue.withAlphaComponent(0.2).cgColor)
            context.fillEllipse(in: CGRect(
                x: dragLoc.x - brushRadius,
                y: dragLoc.y - brushRadius,
                width: brushRadius * 2,
                height: brushRadius * 2
            ))
        }
    }
}

// Helper extension for grid color
extension UIColor {
    static var gridColor: UIColor {
        return UIColor.separator
    }
}

