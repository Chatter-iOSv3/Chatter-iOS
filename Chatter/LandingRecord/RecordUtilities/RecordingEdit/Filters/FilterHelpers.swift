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
        switch filterID {
        case "Robot":
            self.handleRobotFilter()
        case "BadMouth":
            self.handleBadMouthFilter()
        case "Studio":
            self.handleStudioFilter()
        case "Poop":
            self.handlePoopFilter()
        case "Running":
            self.handleRunningManFilter()
        default:
            print("Filter malfunction")
        }
    }
    
    func handleRobotFilter() {
        print("Robot Filter")
        
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
        
        // Schedule playerA and playerB to play the buffer on a loop
        self.filterPlayer.scheduleBuffer(filterBuffer, at: nil, options: AVAudioPlayerNodeBufferOptions.interrupts, completionHandler: nil)
        
        // Start the audio engine
        self.engine.prepare()
        do {
            try self.engine.start()
        } catch {
            fatalError("Couldn't start audio engine, \(error.localizedDescription)")
        }
    }
    
    func handlePoopFilter() {
        print("Poop Filter")
        
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
        
        let lowPitch = AVAudioUnitTimePitch()
        lowPitch.pitch = -650
        
        // Attach the nodes to the audio engine
        self.engine.attach(self.filterPlayer)
        self.engine.attach(lowPitch)
        
        // Connect filterPlayer to the reverb
        let mainMixer = self.engine.mainMixerNode
        self.engine.connect(self.filterPlayer, to: lowPitch, format: filterBuffer.format)
        self.engine.connect(lowPitch, to: mainMixer, fromBus: 0, toBus: 0, format: filterBuffer.format)
        
        // Schedule playerA and playerB to play the buffer on a loop
        self.filterPlayer.scheduleBuffer(filterBuffer, at: nil, options: AVAudioPlayerNodeBufferOptions.interrupts, completionHandler: nil)
        
        // Start the audio engine
        self.engine.prepare()
        do {
            try self.engine.start()
        } catch {
            fatalError("Couldn't start audio engine, \(error.localizedDescription)")
        }
    }
    
    func handleStudioFilter() {
        print("Studio Filter")
        
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
        
        // Schedule playerA and playerB to play the buffer on a loop
        self.filterPlayer.scheduleBuffer(filterBuffer, at: nil, options: AVAudioPlayerNodeBufferOptions.interrupts, completionHandler: nil)
        
        // Start the audio engine
        self.engine.prepare()
        do {
           try self.engine.start()
        } catch {
            fatalError("Couldn't start audio engine, \(error.localizedDescription)")
        }
    }
    
    func handleRunningManFilter() {
        print("Running man Filter")
        
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
        
        let fastSpeed = AVAudioUnitVarispeed()
        fastSpeed.rate = 2.0
        
        // Attach the nodes to the audio engine
        self.engine.attach(self.filterPlayer)
        self.engine.attach(fastSpeed)
        
        // Connect filterPlayer to the reverb
        let mainMixer = self.engine.mainMixerNode
        self.engine.connect(self.filterPlayer, to: fastSpeed, format: filterBuffer.format)
        self.engine.connect(fastSpeed, to: mainMixer, fromBus: 0, toBus: 0, format: filterBuffer.format)
        
        // Schedule playerA and playerB to play the buffer on a loop
        self.filterPlayer.scheduleBuffer(filterBuffer, at: nil, options: AVAudioPlayerNodeBufferOptions.interrupts, completionHandler: nil)
        
        // Start the audio engine
        self.engine.prepare()
        do {
            try self.engine.start()
        } catch {
            fatalError("Couldn't start audio engine, \(error.localizedDescription)")
        }
    }
    
    func handleBadMouthFilter() {
        print("Bad Mouth Filter")
        
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
        
        let highPitch = AVAudioUnitTimePitch()
        highPitch.pitch = 800
        
        // Attach the nodes to the audio engine
        self.engine.attach(self.filterPlayer)
        self.engine.attach(highPitch)
        
        // Connect filterPlayer to the reverb
        let mainMixer = self.engine.mainMixerNode
        self.engine.connect(self.filterPlayer, to: highPitch, format: filterBuffer.format)
        self.engine.connect(highPitch, to: mainMixer, fromBus: 0, toBus: 0, format: filterBuffer.format)
        
        // Schedule playerA and playerB to play the buffer on a loop
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
