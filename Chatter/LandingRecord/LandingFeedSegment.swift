//
//  LandingFeedSegment.swift
//  Chatter
//
//  Created by Austen Ma on 3/28/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import AudioToolbox
import Firebase

protocol QueueNextDelegate
{
    func queueNext()
}

class LandingFeedSegmentView: UIView, AVAudioPlayerDelegate {
    var shouldSetupConstraints = true
    var recordingURL: URL!
    var player: AVAudioPlayer?
    
    var queueNextDelegate:QueueNextDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let playGesture = UITapGestureRecognizer(target: self, action:  #selector(self.playAudio (_:)))
        self.addGestureRecognizer(playGesture)
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
        
        player?.prepareToPlay()
        player?.currentTime = 0
        //            player?.volume = 10.0
        player?.play()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        queueNextDelegate?.queueNext()
    }

    
    func playAudio() {
        print("playing \(self.recordingURL)")
        
        self.player?.prepareToPlay()
        self.player?.currentTime = 0
        //            player?.volume = 10.0
        self.player?.play()
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
                    self.player?.delegate = self
                } catch let error as NSError {
                    //self.player = nil
                    print(error.localizedDescription)
                } catch {
                    print("AVAudioPlayer init failed")
                }
                
            }
        }
    }
}
