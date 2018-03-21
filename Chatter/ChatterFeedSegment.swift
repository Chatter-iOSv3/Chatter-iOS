//
//  ChatterFeedSegment.swift
//  Chatter
//
//  Created by Austen Ma on 3/1/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import AudioToolbox
import Firebase

class ChatterFeedSegmentView: UIView, AVAudioPlayerDelegate {
    var shouldSetupConstraints = true
    var recordingURL: URL!
    var playButton: UIButton!
    var player: AVAudioPlayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func updateConstraints() {
        if(shouldSetupConstraints) {
            // AutoLayout constraints
            shouldSetupConstraints = false
        }
        super.updateConstraints()
    }
    
    @objc func playAudio() {
        print("playing \(self.recordingURL)")
        
        player?.prepareToPlay()
        player?.currentTime = 0
        //            player?.volume = 10.0
        player?.play()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("FINISHED PLAYING")
        NotificationCenter.default.post(name: .chatterFinishedAndQueue, object: nil)
    }
    
    @objc func changeChatter() {
        let currPlayer: [String:ChatterFeedSegmentView] = ["player": self]
        
        NotificationCenter.default.post(name: .chatterChangedAndQueue, object: nil, userInfo: currPlayer)
    }
    
    func generateAudioFile(audioURL: URL, id: String) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        let audioRef = storageRef.child("audio/\(id)")
        audioRef.write(toFile: audioURL) { url, error in
            if let error = error {
                print("****** \(error)")
            } else {
                self.recordingURL = url
                
                do {
                    self.player = try AVAudioPlayer(contentsOf: self.recordingURL)
                } catch let error as NSError {
                    //self.player = nil
                    print(error.localizedDescription)
                } catch {
                    print("AVAudioPlayer init failed")
                }

            }
        }
    }
    
    func generateWaveForm(audioURL: URL, multiplier: Float) {
        let file = try! AVAudioFile(forReading: audioURL)//Read File into AVAudioFile
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false)//Format of the file
        
        let buf = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: UInt32(file.length))//Buffer
        try! file.read(into: buf!)//Read Floats
        
        let waveForm = DrawWaveform()
        waveForm.frame.size.width = 300
        waveForm.frame.size.height = 300
        waveForm.backgroundColor = UIColor(white: 1, alpha: 0.0)
        
        // Set multiplier
        waveForm.multiplier = multiplier
        
        //Store the array of floats in the struct
        waveForm.arrayFloatValues = Array(UnsafeBufferPointer(start: buf?.floatChannelData?[0], count:Int(buf!.frameLength)))
        
        self.addSubview(waveForm)
        
        // Then add button to be on outer subview layer
        // Add play button
        let playButton = UIButton(frame: CGRect(x: 10, y: 10, width: 300, height: 400))
        playButton.addTarget(self, action: #selector(changeChatter), for: .touchUpInside)
        playButton.backgroundColor = UIColor(white: 1, alpha: 0.0)
        self.addSubview(playButton)
    }
}
