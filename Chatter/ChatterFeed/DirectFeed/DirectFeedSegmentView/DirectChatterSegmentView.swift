//
//  DirectChatterSegmentView.swift
//  Chatter
//
//  Created by Austen Ma on 4/13/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import AudioToolbox
import Firebase

protocol QueueDirectChatterDelegate {
    func queueDirectChatter(index: Int)
}

class DirectChatterSegmentView: UIView, AVAudioPlayerDelegate {
    var shouldSetupConstraints = true
    var recordingURL: URL!
    var player: AVAudioPlayer?
    var multiplier: Float?
    var audioPathURL: URL!
    var audioLength: Float!
    var position: Int!
    var imageWidth: CGFloat!
    
    var queueDirectChatterDelegate : QueueDirectChatterDelegate?
    
    var chatterRoomID: String!
    var chatterRoomTimestamp: String!
    var chatterSegmentUser: String!
    
    var ref: DatabaseReference!
    var userID: String!
    
    var readStatus: String!
    var waveView: UIView?
    var waveColor: UIColor?
    var waveForm: DrawDirectWaveForm!
    
    var sliderView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        ref = Database.database().reference()
        userID = Auth.auth().currentUser?.uid
        
        let playGesture = UITapGestureRecognizer(target: self, action:  #selector(self.playAudio (_:)))
        self.addGestureRecognizer(playGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(stopChatterFeedAudio(notification:)), name: .stopChatterFeedAudio, object: nil)
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
    
    @objc func playAudio(_ sender:UITapGestureRecognizer) {
        print("playing \(self.recordingURL)")
        
        if (self.player?.isPlaying)! {
            self.stopAudio()
        }   else {
            self.playAudio()
        }
    }
    
    func playAudio() {
        // Notifies other players to stop playing
        NotificationCenter.default.post(name: .stopChatterFeedAudio, object: nil)
        
        player?.prepareToPlay()
        player?.currentTime = 0
        //            player?.volume = 10.0
        player?.play()
        
        // When finished playing, it should notify the Direct parent
        player?.delegate = self as? AVAudioPlayerDelegate
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Starts slider
            self.sliderView?.alpha = 1.0
            self.playSlider()
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("SEGMENT DONE PLAYING")
        if (self.readStatus == "unread" && self.chatterSegmentUser != self.userID) {
            self.ref.child("chatterRooms").child(self.chatterRoomID).child("chatterRoomSegments").child(self.chatterRoomTimestamp).child("readStatus").setValue("read")
            
            // Send notification to Parent to update badge count
            NotificationCenter.default.post(name: .directChatterInboxChanged, object: nil, userInfo: ["readStatus": "read", "chatterSegmentID": self.chatterRoomTimestamp])
        }
        
        // Queue next Direct Chatter
        self.queueDirectChatterDelegate?.queueDirectChatter(index: self.position)
    }
    
    @objc func stopChatterFeedAudio(notification:NSNotification) {
        self.stopAudio()
    }
    
    func stopAudio() {
        player?.stop()
        self.sliderView?.alpha = 0.0
        self.sliderView?.center = CGPoint(x: 2.5, y: (self.sliderView?.center.y)!)
        self.sliderView?.layer.removeAllAnimations()
    }
    
    func generateAudioFile(audioURL: URL, id: String) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        self.audioPathURL = audioURL
        
        let audioRef = storageRef.child("audio/\(id)")
        audioRef.write(toFile: audioURL) { url, error in
            if let error = error {
                print("****** \(error)")
            } else {
                self.recordingURL = url
                
                do {
                    self.player = try AVAudioPlayer(contentsOf: self.recordingURL)
                    self.multiplier = self.calculateMultiplierWithAudio(audioUrl: self.recordingURL)
                    
                    // Generate wave form
                    self.generateWaveForm(audioURL: self.recordingURL)
                } catch let error as NSError {
                    //self.player = nil
                    print(error.localizedDescription)
                } catch {
                    print("AVAudioPlayer init failed")
                }
                
            }
        }
    }
    
    func calculateMultiplierWithAudio(audioUrl: URL) -> Float {
        let asset = AVURLAsset(url: audioUrl)
        let audioDuration = asset.duration
        let audioDurationSeconds = Float(CMTimeGetSeconds(audioDuration))
        
        self.audioLength = audioDurationSeconds
        
        return Float((audioDurationSeconds * 9.5) / (audioDurationSeconds / 20))
    }
    
    func generateWaveForm(audioURL: URL) {
        let file = try! AVAudioFile(forReading: audioURL)//Read File into AVAudioFile
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false)//Format of the file
        
        let buf = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: UInt32(file.length))//Buffer
        try! file.read(into: buf!)//Read Floats
        
        self.waveForm = DrawDirectWaveForm()
        self.waveForm.frame.size.width = CGFloat(300 * (self.audioLength / 20))
        self.waveForm.frame.size.height = 65
        self.waveForm.backgroundColor = UIColor(white: 1, alpha: 0.0)
        
        // Set multiplier
        self.waveForm.multiplier = self.multiplier
        self.waveForm.waveColor = self.waveColor
        
        //Store the array of floats in the struct
        self.waveForm.arrayFloatValues = Array(UnsafeBufferPointer(start: buf?.floatChannelData?[0], count:Int(buf!.frameLength)))
        
        UIView.transition(with: self, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.addSubview(self.waveForm)
        }, completion: nil)
    }
}

