//
//  DirectChatterRoomView.swift
//  Chatter
//
//  Created by Austen Ma on 4/6/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox
import UICircularProgressRing
import Firebase

protocol RecordEditDelegate {
    func performSegueToRecordEdit(recordedURL: URL, chatterRoom: DirectChatterRoomView, chatterRoomID: String)
}

class DirectChatterRoomView: UIView, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    var shouldSetupConstraints = true
    var recordingURLDict: NSDictionary!
    var chatterRoomView: UIView?
    
    var chatterRoomID: String!
    var recordEditDelegate : RecordEditDelegate?
    
    var recordProgressRing: UICircularProgressRingView!
    var finishedRecording: Bool!
    
    var audioRecorder: AVAudioRecorder?
    var player : AVAudioPlayer?
    var recordedURL: URL!
    
    var userID: String = (Auth.auth().currentUser?.uid)!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.finishedRecording = false
    }
    
    func initializeChatterRoomScrollView() {
        let imageWidth:CGFloat = 100
        var imageHeight:CGFloat = 60
        var xPosition:CGFloat = 0
        var scrollViewContentSize:CGFloat=0;
        
        let chatterRoomView = UIView()
        chatterRoomView.frame.size.height = 65
        chatterRoomView.frame.size.width = 300
        chatterRoomView.backgroundColor = UIColor(red: 119/255, green: 211/255, blue: 239/255, alpha: 1.0)
        chatterRoomView.layer.cornerRadius = 20
        
        let chatterRoomScrollView = UIScrollView()
        chatterRoomScrollView.frame.size.height = 65
        chatterRoomScrollView.frame.size.width = 300
        chatterRoomScrollView.backgroundColor = .clear
        
        let chatterRoomSegmentTupleArr = self.recordingURLDict.sorted{
            guard let d1 = $0.key as? String, let d2 = $1.key as? String else { return false }
            return d1 < d2
        }
        
        for chatterRoomSegment in chatterRoomSegmentTupleArr {
            let chatterRoomSegment = chatterRoomSegment.value as! String
            let chatterRoomData = chatterRoomSegment.components(separatedBy: " | ")
            
            let chatterSegmentUser = chatterRoomData.first
            let chatterSegmentID = chatterRoomData.last
            
            let chatterRoomSegmentView = DirectChatterSegmentView()
            chatterRoomSegmentView.frame.size.height = 65
            chatterRoomSegmentView.frame.size.width = 100
            chatterRoomSegmentView.backgroundColor = .clear
            
            // Decides what color the wave forms are based on user
            if (chatterSegmentUser! != self.userID) {
                chatterRoomSegmentView.waveColor = UIColor(red: 151/255, green: 19/255, blue: 232/255, alpha: 1.0)
            } else {
                chatterRoomSegmentView.waveColor = UIColor.white
            }
            
            chatterRoomSegmentView.frame.origin.x = xPosition
            
            chatterRoomScrollView.addSubview(chatterRoomSegmentView)
            xPosition+=imageWidth
            scrollViewContentSize+=imageWidth
            
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let localURL = documentsURL.appendingPathComponent("\(chatterSegmentID).m4a")
            chatterRoomSegmentView.generateAudioFile(audioURL: localURL, id: chatterRoomSegment)
            
            // Calculates running total of how long the scrollView needs to be with the variables
            chatterRoomScrollView.contentSize = CGSize(width: scrollViewContentSize, height: imageHeight)
        }
        
        let longRecordGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTapRecord))
        chatterRoomScrollView.addGestureRecognizer(longRecordGesture)
        
        self.addSubview(chatterRoomView)
        self.addSubview(chatterRoomScrollView)
    }
    
    @objc func longTapRecord(_ sender: AnyObject) {
        if (!finishedRecording) {
            if sender.state == UIGestureRecognizerState.began
            {
                // Code to start recording
                startRecording()
                
                self.recordProgressRing.setProgress(value: 100, animationDuration: 20.0) {
                    if (self.recordProgressRing.currentValue == 100) {
                        //Code to stop recording
                        self.finishedRecording = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // change 1 to desired number of seconds
                            self.recordProgressRing.setProgress(value: 0, animationDuration: 0.6) {print("CLOSING")}
                        }
                    }
                }
            }
            else if (sender.state == UIGestureRecognizerState.ended)
            {
                // Case if recording ends before time limit
                self.recordProgressRing.setProgress(value: 0, animationDuration: 0.5) {
                    print("FINISHED RECORDING.")
                    
                    //Code to stop recording
                    self.finishedRecording = true
                    self.stopRecordProgress()
                }
            }
        }
    }
    
    // Recording Utilities -------------------------------------------------------
    
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
    
    func stopRecordProgress() {
        print("STOPPING")
        self.finishedRecording = true
        audioRecorder?.stop()
        
        // Send recorded URL to modal and show modal
        self.recordedURL = getAudioFileUrl()
        
        // Bring up the recordEdit modal
        self.recordEditDelegate?.performSegueToRecordEdit(recordedURL: self.recordedURL, chatterRoom: self, chatterRoomID: self.chatterRoomID)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

