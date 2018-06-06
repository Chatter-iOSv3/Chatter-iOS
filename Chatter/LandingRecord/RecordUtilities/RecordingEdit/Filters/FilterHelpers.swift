//
//  FilterHelpers.swift
//  Chatter
//
//  Created by Austen Ma on 6/1/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import AVFoundation

extension RecordEditModal {
    func handleFilterSelected(filterID: String) {
        // Reset any previous filters
        self.resetFilterPlayer()
        
        // Create new filter files
        var filterFile = AVAudioFile()
        var filterBuffer = AVAudioPCMBuffer()
        
        // Here you are creating an AVAudioFile from the sound file, preparing a buffer of the correct format and length and loading the file into the buffer.
        do {
            filterFile = try AVAudioFile(forReading: self.recordedUrl!)
            filterBuffer = AVAudioPCMBuffer(pcmFormat: filterFile.processingFormat, frameCapacity: AVAudioFrameCount(filterFile.length))!
            try filterFile.read(into: filterBuffer)
        } catch {
            fatalError("Couldn't read filter into buffer, \(error.localizedDescription)")
        }
        
        switch filterID {
        case "Robot":
            self.handleRobotFilter(filterFile: filterFile, filterBuffer: filterBuffer)
        case "BadMouth":
            self.handleBadMouthFilter(filterFile: filterFile, filterBuffer: filterBuffer)
        case "Studio":
            self.handleStudioFilter(filterFile: filterFile, filterBuffer: filterBuffer)
        case "Poop":
            self.handlePoopFilter(filterFile: filterFile, filterBuffer: filterBuffer)
        case "Running":
            self.handleRunningManFilter(filterFile: filterFile, filterBuffer: filterBuffer)
        default:
            print("Filter malfunction")
        }
    }
    
    func handleRobotFilter(filterFile: AVAudioFile, filterBuffer: AVAudioPCMBuffer) {
        print("Robot Filter")
        
        let distortion = AVAudioUnitDistortion()
        distortion.loadFactoryPreset(AVAudioUnitDistortionPreset.speechCosmicInterference)
        distortion.wetDryMix = 50
        
        // Attach the nodes to the audio engine
        self.engine.attach(self.filterPlayer)
        self.engine.attach(distortion)
        
        // Connect filterPlayer to the reverb
        let mainMixer = self.engine.mainMixerNode
        self.engine.connect(self.filterPlayer, to: distortion, format: filterBuffer.format)
        self.engine.connect(distortion, to: mainMixer, fromBus: 0, toBus: 0, format: filterBuffer.format)
        
        // Schedule to play the buffer
        self.filterPlayer.scheduleBuffer(filterBuffer, at: nil, options: AVAudioPlayerNodeBufferOptions.interrupts, completionHandler: nil)
        
        // Start the audio engine
        self.engine.prepare()
        do {
            try self.engine.start()
        } catch {
            fatalError("Couldn't start audio engine, \(error.localizedDescription)")
        }
    }
    
    func handlePoopFilter(filterFile: AVAudioFile, filterBuffer: AVAudioPCMBuffer) {
        print("Poop Filter")
        
        let lowPitch = AVAudioUnitTimePitch()
        lowPitch.pitch = -650
        
        // Attach the nodes to the audio engine
        self.engine.attach(self.filterPlayer)
        self.engine.attach(lowPitch)
        
        // Connect filterPlayer to the reverb
        let mainMixer = self.engine.mainMixerNode
        self.engine.connect(self.filterPlayer, to: lowPitch, format: filterBuffer.format)
        self.engine.connect(lowPitch, to: mainMixer, fromBus: 0, toBus: 0, format: filterBuffer.format)
        
        // Schedule to play the buffer
        self.filterPlayer.scheduleBuffer(filterBuffer, at: nil, options: AVAudioPlayerNodeBufferOptions.interrupts, completionHandler: nil)
        
        // Start the audio engine
        self.engine.prepare()
        do {
            try self.engine.start()
        } catch {
            fatalError("Couldn't start audio engine, \(error.localizedDescription)")
        }
    }
    
    func handleStudioFilter(filterFile: AVAudioFile, filterBuffer: AVAudioPCMBuffer) {
        print("Studio Filter")
        
        // Create reverb component
        let reverb = AVAudioUnitReverb()
        reverb.loadFactoryPreset(AVAudioUnitReverbPreset.cathedral)
        reverb.wetDryMix = 50
        
        // Attach the nodes to the audio engine
        print(self.filterPlayer)
        self.engine.attach(self.filterPlayer)
        self.engine.attach(reverb)
        
        // Connect filterPlayer to the reverb
        let mainMixer = self.engine.mainMixerNode
        self.engine.connect(self.filterPlayer, to: reverb, format: filterBuffer.format)
        self.engine.connect(reverb, to: mainMixer, fromBus: 0, toBus: 0, format: filterBuffer.format)
        
        // Schedule to play the buffer
        self.filterPlayer.scheduleBuffer(filterBuffer, at: nil, options: AVAudioPlayerNodeBufferOptions.interrupts, completionHandler: nil)
        
        // Start the audio engine
        self.engine.prepare()
        do {
            try self.engine.start()
        } catch {
            fatalError("Couldn't start audio engine, \(error.localizedDescription)")
        }
    }
    
    func handleRunningManFilter(filterFile: AVAudioFile, filterBuffer: AVAudioPCMBuffer) {
        print("Running man Filter")
        
        let fastSpeed = AVAudioUnitVarispeed()
        fastSpeed.rate = 2.0
        
        // Attach the nodes to the audio engine
        self.engine.attach(self.filterPlayer)
        self.engine.attach(fastSpeed)
        
        // Connect filterPlayer to the reverb
        let mainMixer = self.engine.mainMixerNode
        self.engine.connect(self.filterPlayer, to: fastSpeed, format: filterBuffer.format)
        self.engine.connect(fastSpeed, to: mainMixer, fromBus: 0, toBus: 0, format: filterBuffer.format)
        
        // Schedule to play the buffer
        self.filterPlayer.scheduleBuffer(filterBuffer, at: nil, options: AVAudioPlayerNodeBufferOptions.interrupts, completionHandler: nil)
        
        // Start the audio engine
        self.engine.prepare()
        do {
            try self.engine.start()
        } catch {
            fatalError("Couldn't start audio engine, \(error.localizedDescription)")
        }
    }
    
    func handleBadMouthFilter(filterFile: AVAudioFile, filterBuffer: AVAudioPCMBuffer) {
        print("Bad Mouth Filter")
        
        let highPitch = AVAudioUnitTimePitch()
        highPitch.pitch = 800
        
        // Attach the nodes to the audio engine
        self.engine.attach(self.filterPlayer)
        self.engine.attach(highPitch)
        
        // Connect filterPlayer to the reverb
        let mainMixer = self.engine.mainMixerNode
        self.engine.connect(self.filterPlayer, to: highPitch, format: filterBuffer.format)
        self.engine.connect(highPitch, to: mainMixer, fromBus: 0, toBus: 0, format: filterBuffer.format)
        
        // Schedule to play the buffer
        self.filterPlayer.scheduleBuffer(filterBuffer, at: nil, options: AVAudioPlayerNodeBufferOptions.interrupts, completionHandler: nil)
        
        // Start the audio engine
        self.engine.prepare()
        do {
            try self.engine.start()
        } catch {
            fatalError("Couldn't start audio engine, \(error.localizedDescription)")
        }
    }
}
