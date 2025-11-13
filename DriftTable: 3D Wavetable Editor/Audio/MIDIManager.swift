//
//  MIDIManager.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import Foundation
import CoreMIDI
import Combine

class MIDIManager: ObservableObject {
    @Published var availableDevices: [MIDIDeviceInfo] = []
    @Published var selectedDevice: MIDIDeviceInfo?
    @Published var currentNote: Int? // MIDI note number (0-127)
    
    private var midiClient: MIDIClientRef = 0
    private var inputPort: MIDIPortRef = 0
    private var onNoteOn: ((Int, Float) -> Void)? // note, velocity
    private var onNoteOff: ((Int) -> Void)?
    
    struct MIDIDeviceInfo: Identifiable, Hashable {
        let id: Int
        let name: String
        let endpointRef: MIDIEndpointRef
    }
    
    init() {
        setupMIDI()
    }
    
    private func setupMIDI() {
        var status = MIDIClientCreateWithBlock("DriftTableMIDI" as CFString, &midiClient) { notification in
            // Handle MIDI notifications
        }
        
        guard status == noErr else {
            print("Failed to create MIDI client: \(status)")
            return
        }
        
        status = MIDIInputPortCreateWithBlock(midiClient, "DriftTableInput" as CFString, &inputPort) { packetList, _ in
            self.handleMIDIPacket(packetList)
        }
        
        guard status == noErr else {
            print("Failed to create MIDI input port: \(status)")
            return
        }
        
        refreshDevices()
    }
    
    func refreshDevices() {
        var devices: [MIDIDeviceInfo] = []
        let sourceCount = MIDIGetNumberOfSources()
        
        for i in 0..<sourceCount {
            let source = MIDIGetSource(i)
            var name: Unmanaged<CFString>?
            let status = MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name)
            
            if status == noErr, let cfName = name?.takeRetainedValue() {
                let deviceName = cfName as String
                devices.append(MIDIDeviceInfo(id: i, name: deviceName, endpointRef: source))
            }
        }
        
        DispatchQueue.main.async {
            self.availableDevices = devices
            if self.selectedDevice == nil && !devices.isEmpty {
                self.selectedDevice = devices.first
                self.connectToDevice(devices.first!)
            }
        }
    }
    
    func selectDevice(_ device: MIDIDeviceInfo) {
        disconnectCurrentDevice()
        selectedDevice = device
        connectToDevice(device)
    }
    
    private func connectToDevice(_ device: MIDIDeviceInfo) {
        let status = MIDIPortConnectSource(inputPort, device.endpointRef, nil)
        if status != noErr {
            print("Failed to connect to MIDI device: \(status)")
        }
    }
    
    private func disconnectCurrentDevice() {
        if let device = selectedDevice {
            MIDIPortDisconnectSource(inputPort, device.endpointRef)
        }
    }
    
    private func handleMIDIPacket(_ packetList: UnsafePointer<MIDIPacketList>) {
        var packet = packetList.pointee.packet
        
        for _ in 0..<packetList.pointee.numPackets {
            let data = withUnsafePointer(to: &packet.data) {
                $0.withMemoryRebound(to: UInt8.self, capacity: Int(packet.length)) {
                    Array(UnsafeBufferPointer(start: $0, count: Int(packet.length)))
                }
            }
            
            if !data.isEmpty {
                let status = data[0]
                let messageType = status & 0xF0
                
                if messageType == 0x90 { // Note On
                    if data.count >= 3 {
                        let note = Int(data[1])
                        let velocity = Float(data[2]) / 127.0
                        if velocity > 0 {
                            DispatchQueue.main.async {
                                self.currentNote = note
                                self.onNoteOn?(note, velocity)
                            }
                        } else {
                            // Note off (velocity 0)
                            DispatchQueue.main.async {
                                self.currentNote = nil
                                self.onNoteOff?(note)
                            }
                        }
                    }
                } else if messageType == 0x80 { // Note Off
                    if data.count >= 2 {
                        let note = Int(data[1])
                        DispatchQueue.main.async {
                            self.currentNote = nil
                            self.onNoteOff?(note)
                        }
                    }
                }
            }
            
            packet = MIDIPacketNext(&packet).pointee
        }
    }
    
    func setNoteHandlers(onNoteOn: @escaping (Int, Float) -> Void, onNoteOff: @escaping (Int) -> Void) {
        self.onNoteOn = onNoteOn
        self.onNoteOff = onNoteOff
    }
    
    deinit {
        disconnectCurrentDevice()
        if midiClient != 0 {
            MIDIClientDispose(midiClient)
        }
    }
}

