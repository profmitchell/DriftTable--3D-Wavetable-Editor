//
//  WavetableSceneView.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import SwiftUI
import SceneKit
import UIKit

struct WavetableSceneView: UIViewRepresentable {
    let frames: [[Float]]
    let currentFrameIndex: Int
    let frameSpacing: Float
    
    init(frames: [[Float]], currentFrameIndex: Int = 0, frameSpacing: Float = 0.1) {
        self.frames = frames
        self.currentFrameIndex = currentFrameIndex
        self.frameSpacing = frameSpacing
    }
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        let scene = createScene()
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.backgroundColor = UIColor.black // Black background
        scnView.antialiasingMode = .multisampling4X
        scnView.autoenablesDefaultLighting = true
        
        // Set up camera controls
        setupCamera(scnView, scene: scene)
        
        return scnView
    }
    
    func updateUIView(_ scnView: SCNView, context: Context) {
        guard let scene = scnView.scene else { return }
        
        // Update the wavetable geometry
        updateWavetableGeometry(in: scene)
    }
    
    private func createScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.black // Black background
        
        // Add ambient light (darker for better contrast)
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor.white.withAlphaComponent(0.3)
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        
        // Add directional light
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.color = UIColor.white
        directionalLight.intensity = 1500
        let directionalNode = SCNNode()
        directionalNode.light = directionalLight
        directionalNode.position = SCNVector3(x: 5, y: 10, z: 5)
        directionalNode.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(directionalNode)
        
        // Create wavetable container node
        let wavetableNode = SCNNode()
        wavetableNode.name = "wavetable"
        scene.rootNode.addChildNode(wavetableNode)
        
        // Build wavetable geometry
        buildWavetableGeometry(parent: wavetableNode)
        
        return scene
    }
    
    private func setupCamera(_ scnView: SCNView, scene: SCNScene) {
        // Create camera
        let camera = SCNCamera()
        camera.usesOrthographicProjection = false
        camera.fieldOfView = 50 // Slightly narrower for better framing
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        
        // Position camera closer and at better angle
        let frameCount = Float(frames.count)
        let totalDepth = frameCount * frameSpacing
        let distance: Float = max(totalDepth * 1.5, 3.0) // Closer to the wavetable
        
        // Better viewing angle - centered view
        cameraNode.position = SCNVector3(
            x: Float(distance * 0.7),
            y: Float(distance * 0.5),
            z: Float(distance * 0.5)
        )
        
        // Look at center of wavetable
        let centerZ = Float(totalDepth * 0.5)
        cameraNode.look(at: SCNVector3(
            x: 0,
            y: 0,
            z: centerZ
        ))
        
        // Create pivot node at center for orbiting
        let pivotNode = SCNNode()
        pivotNode.name = "cameraPivot"
        pivotNode.position = SCNVector3(
            x: 0,
            y: 0,
            z: centerZ
        )
        pivotNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(pivotNode)
        
        // Set camera as point of view
        scnView.pointOfView = cameraNode
    }
    
    private func buildWavetableGeometry(parent: SCNNode) {
        guard !frames.isEmpty else { return }
        
        let sampleCount = frames[0].count
        let frameCount = frames.count
        
        // Clear existing children
        parent.childNodes.forEach { $0.removeFromParentNode() }
        
        for (frameIndex, frame) in frames.enumerated() {
            guard frame.count == sampleCount else { continue }
            
            // Create geometry for this frame
            let geometry = createFrameGeometry(frame: frame, frameIndex: frameIndex)
            
            // Create material with emissive glow
            let material = SCNMaterial()
            let isCurrentFrame = frameIndex == currentFrameIndex
            
            if isCurrentFrame {
                // Current frame: bright with strong emission
                material.diffuse.contents = UIColor.systemBlue
                material.emission.contents = UIColor.systemBlue.withAlphaComponent(0.8)
                material.emission.intensity = 1.5
                material.transparency = 0.05
            } else {
                // Other frames: fade with depth but still emissive
                let depthFactor = Float(frameIndex) / Float(frameCount)
                let opacity = 1.0 - (depthFactor * 0.6) // Fade from 1.0 to 0.4
                let emissionIntensity = 1.0 - (depthFactor * 0.5) // Fade emission
                
                material.diffuse.contents = UIColor.systemBlue.withAlphaComponent(CGFloat(opacity))
                material.emission.contents = UIColor.systemBlue.withAlphaComponent(CGFloat(opacity * 0.6))
                material.emission.intensity = CGFloat(emissionIntensity)
                material.transparency = CGFloat(1.0 - opacity)
            }
            
            material.isDoubleSided = true
            geometry.materials = [material]
            
            // Create node
            let frameNode = SCNNode(geometry: geometry)
            frameNode.position = SCNVector3(
                x: 0,
                y: 0,
                z: Float(frameIndex) * frameSpacing
            )
            frameNode.name = "frame_\(frameIndex)"
            
            parent.addChildNode(frameNode)
        }
    }
    
    private func createFrameGeometry(frame: [Float], frameIndex: Int) -> SCNGeometry {
        guard frame.count > 1 else {
            return SCNGeometry()
        }
        
        let sampleCount = frame.count
        let width: Float = 3.0 // Larger X extent - takes up more screen
        let heightScale: Float = 0.8 // Larger Y amplitude - takes up more screen
        
        // Create vertices for ribbon
        var vertices: [SCNVector3] = []
        var indices: [Int32] = []
        
        // Generate vertices along the waveform
        for i in 0..<sampleCount {
            let t = Float(i) / Float(sampleCount - 1)
            let x = (t - 0.5) * width
            let y = frame[i] * heightScale
            
            // Create two vertices (top and bottom of ribbon) for thickness - thicker lines
            let ribbonThickness: Float = 0.05 // Thicker ribbons
            vertices.append(SCNVector3(x: x, y: y + ribbonThickness, z: 0))
            vertices.append(SCNVector3(x: x, y: y - ribbonThickness, z: 0))
        }
        
        // Create triangle strip indices
        for i in 0..<(sampleCount - 1) {
            let base = i * 2
            // First triangle
            indices.append(Int32(base))
            indices.append(Int32(base + 1))
            indices.append(Int32(base + 2))
            // Second triangle
            indices.append(Int32(base + 1))
            indices.append(Int32(base + 3))
            indices.append(Int32(base + 2))
        }
        
        // Create geometry source
        let vertexSource = SCNGeometrySource(vertices: vertices)
        let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<Int32>.size)
        let indexSource = SCNGeometryElement(
            data: indexData,
            primitiveType: .triangles,
            primitiveCount: indices.count / 3,
            bytesPerIndex: MemoryLayout<Int32>.size
        )
        
        return SCNGeometry(sources: [vertexSource], elements: [indexSource])
    }
    
    private func updateWavetableGeometry(in scene: SCNScene) {
        guard let wavetableNode = scene.rootNode.childNode(withName: "wavetable", recursively: false) else {
            return
        }
        
        // Rebuild geometry with updated current frame
        buildWavetableGeometry(parent: wavetableNode)
    }
}

