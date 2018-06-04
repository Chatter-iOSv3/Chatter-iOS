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
        case "Poop":
            self.handlePoopFilter()
        case "Studio":
            self.handleStudioFilter()
        default:
            print("Filter malfunction")
        }
    }
    
    func handleRobotFilter() {
        print("Robot Filter")
    }
    
    func handlePoopFilter() {
        print("Poop Filter")
    }
    
    func handleStudioFilter() {
        print("Studio Filter")
        
        var filterFile = AVAudioFile()
        var filterBuffer = AVAudioPCMBuffer()
        
        // Here you are creating an AVAudioFile from the sound file, preparing a buffer of the correct format and length and loading the file into the buffer.
        // load drumloop into a buffer for the playernode
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
        self.filterPlayer.scheduleBuffer(filterBuffer, at: nil, options: AVAudioPlayerNodeBufferOptions.loops, completionHandler: nil)
        
        // Start the audio engine
        self.engine.prepare()
        do {
           try self.engine.start()
        } catch {
            fatalError("Couldn't start audio engine, \(error.localizedDescription)")
        }
    }
}
