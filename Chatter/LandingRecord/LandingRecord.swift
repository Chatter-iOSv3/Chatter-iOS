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
import Firebase

class LandingRecord: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate, TrashRecordingDelegate, UITableViewDataSource, QueueNextDelegate{
    // Firebase Variables
    var ref: DatabaseReference!
    let storage = Storage.storage()
    var storageRef: Any?
    var userID: String!
    
    // Recording Outlets
    @IBOutlet weak var recordProgress: UIProgressView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var landingRecordLabel: UILabel!
    
    // Bubble list outlets
    @IBOutlet weak var bubbleListButton: UIButton!
    @IBOutlet weak var bubbleListTableView: UITableView!
    
    // Recording variables
    var isRecording = false
    var audioRecorder: AVAudioRecorder?
    var player : AVAudioPlayer?
    
    var finishedRecording = false
    var recordProgressValue = 0.00
    var recordedURL: URL?
    var labelAlpha = 1.0
    
    // Player Variables
    var isPlaying = false
    
    // Bubble list variables
    var expanded = false
    
    // *** TEMP
//    var landingFeedViewArray: [UIColor] = [UIColor(red: 1, green: 0.8, blue: 0, alpha: 1.0), UIColor(red: 0, green: 0.1216, blue: 0.6784, alpha: 1.0), UIColor(red: 0.3373, green: 0, blue: 0.2745, alpha: 1.0), UIColor(red: 0, green: 0.8, blue: 0.1725, alpha: 1.0), UIColor(red: 0, green: 0.3804, blue: 0.5569, alpha: 1.0), UIColor(red: 0.3373, green: 0.1451, blue: 0, alpha: 1.0), UIColor(red: 1, green: 0.8, blue: 0, alpha: 1.0), UIColor(red: 0, green: 0.1216, blue: 0.6784, alpha: 1.0), UIColor(red: 0.3373, green: 0, blue: 0.2745, alpha: 1.0), UIColor(red: 0, green: 0.8, blue: 0.1725, alpha: 1.0), UIColor(red: 0, green: 0.3804, blue: 0.5569, alpha: 1.0), UIColor(red: 0.3373, green: 0.1451, blue: 0, alpha: 1.0)]
    
    var landingFeedViewArray: [LandingFeedSegmentView] = []
    var landingFeedAudioArray: [AVAudioPlayer] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide landing views initially
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.landingRecordLabel.alpha = 0.0
            self.bubbleListButton.alpha = 0.0
        }
        
        // Present modal for loading
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.presentLoadingModal()
        }
        
        // Firebase initializers
        ref = Database.database().reference()
        self.storageRef = storage.reference()
        self.userID = Auth.auth().currentUser?.uid
        
        // Initialize the Live Feed
        self.initLandingFeed()
        
        // Changing progress bar height
        recordProgress.transform = recordProgress.transform.scaledBy(x: 1, y: 5)
        recordProgress.alpha = 0.0
        
        // Set the rounded edge for the outer bar
        recordProgress.layer.cornerRadius = 2.5
        recordProgress.clipsToBounds = true
        
        // Set the rounded edge for the inner bar
        recordProgress.layer.sublayers![1].cornerRadius = 2.5
        recordProgress.subviews[1].clipsToBounds = true
        
        // Configure bubble list
        self.configureBubbleListTable()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Set animation for HearChatter and HoldRecord labels
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.landingRecordLabel.layer.removeAllAnimations()
        self.toggleLabels()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? RecordEditModal {
            destination.trashDelegate = self
            destination.recordedUrl = self.recordedURL
        }
    }
    
    // Initialize Landing Feed
    
    func initLandingFeed() {
        // Upon initialization, this will fire for EACH child in chatterFeed, and observe for each NEW -------------------------------------
        self.ref.child("users").child(self.userID!).child("chatterFeed").observe(.childAdded, with: { (snapshot) -> Void in
            // ************* Remember to add conditional to filter/delete based on date **************
            
            let value = snapshot.value as? NSDictionary
            
            let id = value?["id"] as? String ?? ""
            let userDetails = value?["userDetails"] as? String ?? ""
            
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let localURL = documentsURL.appendingPathComponent("\(id.suffix(10)).m4a")
            
            let newView = LandingFeedSegmentView()
            
            // Generate audio file on UIView instance 
            newView.generateAudioFile(audioURL: localURL, id: id)
            newView.frame.size.width = 80
            newView.frame.size.height = 80
            newView.layer.cornerRadius = 40
            newView.layer.backgroundColor = UIColor.red.cgColor
            
            newView.queueNextDelegate = self
            
            self.landingFeedViewArray.append(newView)
            self.bubbleListButton?.setTitle(String(self.landingFeedViewArray.count), for: .normal)
        })
    }
    
    // Actions --------------------------------------------

    @IBAction func startRecord(_ sender: AnyObject) {
        if (!finishedRecording) {
            self.landingRecordLabel.alpha = 0.0
            self.labelAlpha = 0.0
            
            if sender.state == UIGestureRecognizerState.began
            {
                // Start the progress view
                self.startRecordProgress()
                
                // Background darkening
                UIView.animate(withDuration: 0.5, delay: 0.0, options:.curveLinear, animations: {
                    self.recordButton.backgroundColor = UIColor(red: 68/255, green: 14/255, blue: 112/255, alpha: 1.0)
                    self.recordProgress.alpha = 1.0
                    self.landingRecordLabel.alpha = 0.0
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
    
    @IBAction func toggleTableViewPressed(sender: Any) {
        self.toggleTableView()
    }
    
    @IBAction func queueBubbleList() {
        if (self.isPlaying) {
            queueList(skip: true)
        }   else {
            queueList(skip: false)
            self.isPlaying = true
        }
    }
    
    @IBAction func unwindToLandingRecord(segue: UIStoryboardSegue) {}
    
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
        
        // Return labels
        self.landingRecordLabel.alpha = 1.0
        self.labelAlpha = 1.0
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
    
    // View methods ------------------------------------------
    
    @objc func toggleLabels() {
        //Toggle on views after loaded
        self.landingRecordLabel.alpha = CGFloat(self.labelAlpha)
        self.bubbleListButton.alpha = 1.0
        
        if (!isRecording) {
            let labelText = (self.landingRecordLabel.text == "Tap to hear Chatter") ? "Hold to record" : "Tap to hear Chatter"
            
            UIView.transition(with: self.landingRecordLabel, duration: 1, options: .transitionCrossDissolve, animations: {
                self.landingRecordLabel.text = labelText
            }, completion: nil)
            
            perform(#selector(toggleLabels), with: nil, afterDelay: 3)
        }
    }
    
    func configureBubbleListTable() {
        bubbleListButton?.layer.cornerRadius = (bubbleListButton?.frame.size.height)! / 2
        
        self.bubbleListTableView.dataSource = self
        self.bubbleListTableView.tableFooterView = UIView()
        
        self.bubbleListTableView.rowHeight = 80.0
        
        self.bubbleListButton?.setTitle(String(self.landingFeedViewArray.count), for: .normal)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.expanded && self.landingFeedViewArray.count > 6) {
            return 6
        } else if (self.expanded) {
            return self.landingFeedViewArray.count;
        }   else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bubbleListCell", for: indexPath) as! BubbleListCell;
        cell.layer.cornerRadius = 40
        cell.addSubview(self.landingFeedViewArray[indexPath[1]])
        
        if (indexPath[1] % 2 == 0) {
            print("EVEN")
//            cell.bubbleListCellButton.frame.origin.x += 10
        }   else {
//            cell.bubbleListCellButton.frame.origin.x -= 10
        }
        
        return cell;
    }
    
    func toggleTableView() {
        self.expanded = !self.expanded
        let range = NSMakeRange(0, self.bubbleListTableView.numberOfSections)
        let sections = NSIndexSet(indexesIn: range)
        self.bubbleListTableView.reloadSections(sections as IndexSet, with: .automatic)
    }
    
    func queueList(skip: Bool) {
        if (self.landingFeedViewArray.count > 0 && !skip) {
            self.landingFeedViewArray.first?.playAudio()
        }   else if (self.landingFeedViewArray.count > 0 && skip) {
            self.landingFeedViewArray.first?.player?.stop()
            self.queueNext()
        }
    }
    
    func queueNext() {
        self.landingFeedViewArray.removeFirst()
        self.bubbleListButton?.setTitle(String(self.landingFeedViewArray.count), for: .normal)
        let range = NSMakeRange(0, self.bubbleListTableView.numberOfSections)
        let sections = NSIndexSet(indexesIn: range)
        self.bubbleListTableView.reloadSections(sections as IndexSet, with: .automatic)
        
        self.queueList(skip: false)
    }
}
