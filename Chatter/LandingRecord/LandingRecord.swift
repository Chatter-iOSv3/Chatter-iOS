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
    
    var landingFeedViewArray: [LandingFeedSegmentView] = []
    var landingFeedAudioArray: [AVAudioPlayer] = []
    
    var toggleTask: DispatchWorkItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Hide landing views initially: Loading modal is only an overlay
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
        recordProgress.layer.cornerRadius = recordProgress.frame.size.height / 2 - 1
        recordProgress.clipsToBounds = true
        
        // Set the rounded edge for the inner bar
        recordProgress.layer.sublayers![0].cornerRadius = recordProgress.frame.size.height / 2 - 1
        recordProgress.layer.sublayers![1].cornerRadius = recordProgress.frame.size.height / 2 - 1
        recordProgress.subviews[1].clipsToBounds = true
        
        // Configure bubble list
        self.configureBubbleListTable()
        
        // Create task for toggling labels
        self.toggleTask = DispatchWorkItem { self.toggleLabels() }
        
        NotificationCenter.default.addObserver(self, selector: #selector(stopLandingChatter(notification:)), name: .stopLandingChatter, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Set animation for HearChatter and HoldRecord labels
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.toggleTask?.cancel()
        
        self.toggleTask = DispatchWorkItem { self.toggleLabels() }
        
        self.landingRecordLabel.layer.removeAllAnimations()
        self.landingRecordLabel.text = "Hold to Record"
        self.perform(#selector(self.toggleLabels), with: nil, afterDelay: 1)
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
            newView.frame.size.width = 50
            newView.frame.size.height = 50
            newView.layer.cornerRadius = 25
            newView.layer.backgroundColor = self.generateRandomColor().cgColor
            
            newView.queueNextDelegate = self
            
            // Fill bubbles with profile data
            self.ref.child("users").child(userDetails).observeSingleEvent(of: .value) {
                (snapshot) in
                
                let value = snapshot.value as? NSDictionary
                
                if let profileImageURL = value?["profileImageURL"] as? String {
                    self.setProfileImageWithURL(imageURL: profileImageURL, newView: newView)
                }   else {
                    let firstname = value?["firstname"] as? String ?? ""
                    let firstnameLetter = String(describing: firstname.first!)
                    self.setBubbleLabel(firstnameLetter: firstnameLetter, newView: newView)
                }
            }
            
            self.landingFeedViewArray.append(newView)
            self.bubbleListButton?.setTitle(String(self.landingFeedViewArray.count), for: .normal)
        })
    }
    
    func setProfileImageWithURL(imageURL: String, newView: UIView) {
        let profileImageDownloadRef = storage.reference(forURL: imageURL)
        var currImage: UIImage?
        
        profileImageDownloadRef.downloadURL(completion: { (url, error) in
            var data = Data()
            
            do {
                data = try Data(contentsOf: url!)
            } catch {
                print(error)
            }
            currImage = UIImage(data: data as Data)
            newView.backgroundColor = UIColor(patternImage: currImage!)
        })
    }
    
    func setBubbleLabel(firstnameLetter: String, newView: UIView) {
        // Label Avatar button
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        label.textAlignment = .center
        label.font = label.font.withSize(20)
        label.textColor = .white
        label.text = firstnameLetter
        newView.addSubview(label)
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
//            sound.numberOfLoops = -1
            sound.play()
        } catch {
            print("error loading file")
            // couldn't load file :(
        }
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
    
    @objc func stopLandingChatter(notification: NSNotification) {
        self.landingFeedViewArray.first?.player?.stop()
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
        performSegue(withIdentifier: "showLoadingModal", sender: nil)
    }
    
    // View methods ------------------------------------------
    
    @objc func exposeLabels() {
        self.landingRecordLabel.alpha = 1.0
        self.bubbleListButton.alpha = 1.0
    }
    
    @objc func toggleLabels() {
        //Toggle on views after loaded
        self.landingRecordLabel.alpha = CGFloat(self.labelAlpha)
        self.bubbleListButton.alpha = 1.0
        
        if (!isRecording) {
            let labelText = (self.landingRecordLabel.text == "Tap to hear Chatter") ? "Hold to record" : "Tap to hear Chatter"
            
            UIView.transition(with: self.landingRecordLabel, duration: 1.0, options: .transitionCrossDissolve, animations: {
                self.landingRecordLabel.text = labelText
            }, completion: { completion in
                self.blinkLabel()
            })
        }
    }
    
    @objc func blinkLabel() {
        UIView.transition(with: self.landingRecordLabel, duration: 1.5, options: [.repeat, .autoreverse, .transitionCrossDissolve], animations: {
            UIView.setAnimationRepeatCount(6)
            self.landingRecordLabel.textColor = UIColor(red: 160/255, green: 35/255, blue: 232/255, alpha: 1.0)
        }, completion: { completion in
            self.landingRecordLabel.textColor = UIColor(red: 190/255, green: 140/255, blue: 234/255, alpha: 1.0)
        })
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 9.0, execute: self.toggleTask!)
    }
    
    func configureBubbleListTable() {
        bubbleListButton?.layer.cornerRadius = (bubbleListButton?.frame.size.height)! / 2
        
        self.bubbleListTableView.dataSource = self
        self.bubbleListTableView.tableFooterView = UIView()
        
        self.bubbleListTableView.rowHeight = 80.0
        self.bubbleListTableView.allowsSelection = false
        self.bubbleListTableView.separatorStyle = .none
        
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
        
        let avatarView = self.landingFeedViewArray[indexPath[1]]
        
        if (indexPath[1] % 2 == 0) {
            print("EVEN \(avatarView.frame.origin.x)")
            avatarView.frame.origin.x = 20
        }   else {
            avatarView.frame.origin.x = 0
        }
        
        cell.landingFeedSegment = avatarView
        cell.addAvatarView()
        
        return cell;
    }
    
    func toggleTableView() {
        self.expanded = !self.expanded
        let range = NSMakeRange(0, self.bubbleListTableView.numberOfSections)
        let sections = NSIndexSet(indexesIn: range)
        
        self.bubbleListTableView.reloadSections(sections as IndexSet, with: .automatic)
        
        print(self.expanded)
        if (!self.expanded) {
            self.resetBubbles()
        }   else {
            self.animateBubbles()
        }
    }
    
    func animateBubbles() {
        let cells = self.bubbleListTableView.visibleCells
        
        for cell in cells {
            let currCell: BubbleListCell = cell as! BubbleListCell
            currCell.animateAvatarViews()
        }
    }
    
    func resetBubbles() {
        let cells = self.landingFeedViewArray
        
        for cell in cells {
            cell.frame.size.width = 50
            cell.frame.size.height = 50
            cell.layer.cornerRadius = 25
        }
    }
    
    // Misc ---------------------------------------------------------------------------
    
    func generateRandomColor() -> UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from white
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.85 // from 0.5 to 1.0 to stay away from black
        
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
}
