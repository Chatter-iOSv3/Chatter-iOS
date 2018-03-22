//
//  LandingRecord.swift
//  Chatter
//
//  Created by Austen Ma on 2/27/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AudioToolbox

class LandingRecord: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate, TrashRecordingDelegate{
    
    @IBOutlet weak var recordProgress: UIProgressView!
    @IBOutlet weak var recordButton: UIButton!
    
    var isRecording = false
    var audioRecorder: AVAudioRecorder?
    var player : AVAudioPlayer?
    
    var finishedRecording = false
    var recordProgressValue = 0.00
    var recordedURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Changing progress bar height
        recordProgress.transform = recordProgress.transform.scaledBy(x: 1, y: 5)
        recordProgress.alpha = 0.0
        
        // Set the rounded edge for the outer bar
        recordProgress.layer.cornerRadius = 2.5
        recordProgress.clipsToBounds = true
        
        // Set the rounded edge for the inner bar
        recordProgress.layer.sublayers![1].cornerRadius = 2.5
        recordProgress.subviews[1].clipsToBounds = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Present modal for loading
        DispatchQueue.main.asyncAfter(deadline: .now()) { // change 2 to desired number of seconds
            self.presentLoadingModal()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? RecordEditModal {
            destination.trashDelegate = self
            destination.recordedUrl = self.recordedURL
        }
    }

    @IBAction func startRecord(_ sender: AnyObject) {
        if (!finishedRecording) {
            if sender.state == UIGestureRecognizerState.began
            {
                // Start the progress view
                self.startRecordProgress()
                
                // Background darkening
                UIView.animate(withDuration: 0.5, delay: 0.0, options:.curveLinear, animations: {
                    self.recordButton.backgroundColor = UIColor(red: 68/255, green: 14/255, blue: 112/255, alpha: 1.0)
                    self.recordProgress.alpha = 1.0
                }, completion:nil)
                
                // Start recording
                startRecording()
            }
            else if (sender.state == UIGestureRecognizerState.ended)
            {
                // Stop recording
                self.stopRecordProgress()
            }
        }
    }
    
    //    Audio Recording ---------------------------------------
    
    func startRecording() {
        //1. create the session
        let session = AVAudioSession.sharedInstance()
        
        do {
            // 2. configure the session for recording and playback
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            try session.setActive(true)
            // 3. set up a high-quality recording session
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            // 4. create the audio recording, and assign ourselves as the delegate
            audioRecorder = try AVAudioRecorder(url: getAudioFileUrl(), settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        }
        catch let error {
            print("Failed to record!!!")
        }
    }
    
    func getAudioFileUrl() -> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDirect = paths[0]
        let audioUrl = docsDirect.appendingPathComponent("currentRecording.m4a")
        return audioUrl
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            // Code
        }else {
            // Recording interrupted by other reasons like call coming, reached time limit.
        }
    }
    
    @IBAction func unwindToLandingRecord(segue: UIStoryboardSegue) {}
    
    // Audio Playback ------------------------------------------------
    
    func playSound(){
        let url = getAudioFileUrl()
        do {
            // AVAudioPlayer setting up with the saved file URL
            let sound = try AVAudioPlayer(contentsOf: url)
            self.player = sound
            
            // Here conforming to AVAudioPlayerDelegate
            sound.delegate = self
            sound.prepareToPlay()
            sound.numberOfLoops = -1
            sound.play()
        } catch {
            print("error loading file")
            // couldn't load file :(
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            
        }else {
            // Playing interrupted by other reasons like call coming, the sound has not finished playing.
        }
    }
    
    // Recording Methods ---------------------------------------------------------
    
    func trashRecording() {

        // Stop the looping
        self.player?.stop()
        
        // Reset recording
        finishedRecording = false
        
        // Return screen to bright background
        self.recordProgress.alpha = 0.0
        UIView.animate(withDuration: 0.5, delay: 0.0, options:.curveLinear, animations: {
            self.recordButton.backgroundColor = UIColor(red: 151/255, green: 19/255, blue: 232/255, alpha: 1.0)
        }, completion:nil)
    }
    
    @objc func startRecordProgress() {
        
        if (self.recordProgressValue < 1.0 && !finishedRecording) {
            self.recordProgressValue = self.recordProgressValue + 0.05
            
            UIView.animate(withDuration: 1, delay: 0, options: .curveLinear, animations: {
                self.recordProgress.setProgress(Float(self.recordProgressValue), animated: true)
            }, completion: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.startRecordProgress()
            }
        }
        else if (finishedRecording) {
            print("ALREADY FINISHED RECORDING")
        }
        else {
            print("TIME LIMIT REACHED")
            self.recordProgressValue = 0.0
            self.stopRecordProgress()
        }
        
    }
    
    func stopRecordProgress() {
        print("STOPPING")
        self.recordProgressValue = 0.00
        self.finishedRecording = true
        audioRecorder?.stop()
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear, animations: {
            self.recordProgress.setProgress(0.0, animated: true)
        }, completion: nil)
        
        // Send recorded URL to modal and show modal
        self.recordedURL = getAudioFileUrl()
        performSegue(withIdentifier: "showRecordEdit", sender: nil)
    }
    
    func presentLoadingModal() {
        print("LOADING MODALLLLLL")
        performSegue(withIdentifier: "showLoadingModal", sender: nil)
    }
}

extension Notification.Name {
    // When invitation is accepted, updates Followers list
    static let invitationAcceptedRerenderFollowers = Notification.Name("invitationAcceptedRerenderFollowers")
}
