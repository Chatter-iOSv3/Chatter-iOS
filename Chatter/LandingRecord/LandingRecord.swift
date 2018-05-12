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
import AudioToolbox.AudioServices
import Firebase

class LandingRecord: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate, TrashRecordingDelegate, UITableViewDataSource, QueueNextDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
    
    // Upload Variables
    var videoPicker: UIImagePickerController!
    var uploadedTempURL: URL!
    
    // Player Variables
    var isPlaying = false
    
    // Bubble list variables
    var expanded = false
    
    var landingFeedViewArray: [LandingFeedSegmentView] = []
    var landingFeedAudioArray: [AVAudioPlayer] = []
    
    var toggleTask: DispatchWorkItem?
    
    // Friends list
    struct friendItem {
        let userID: String
        let userName: String
        let profileImage: UIImage
    }
    
    var friendsList: [friendItem]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initializing page -----------------------------------------------------------------------
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
        
        // UI Initializers -------------------------------------------------------------
        // Initialize the Live Feed
        self.initLandingFeed()
        // Style progress bar
        self.styleRecordProgressBar()
        // Configure bubble list
        self.configureBubbleListTable()
        // Create task for toggling labels
        self.toggleTask = DispatchWorkItem { self.toggleLabels() }
        // Setup uploading
        self.setupUploading()
        
        // Notifications ---------------------------------------------------------------
        // Stopping landing Chatter
        NotificationCenter.default.addObserver(self, selector: #selector(stopLandingChatter(notification:)), name: .stopLandingChatter, object: nil)
        // Listens for Friends list from Followers/Following
        NotificationCenter.default.addObserver(self, selector: #selector(friendsListSetup(notification:)), name: .sendToComposeModalFriendsList, object: nil)
        self.friendsList = []
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Set animation for HearChatter and HoldRecord labels
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.toggleTask?.cancel()
        self.toggleTask = DispatchWorkItem { self.toggleLabels() }
        
        self.landingRecordLabel.layer.removeAllAnimations()
        self.landingRecordLabel.text = "Hold to Record"
        self.perform(#selector(self.toggleLabels), with: nil, afterDelay: 2)
        
        // Send notification to stop ChatterFeedChatter
        NotificationCenter.default.post(name: .stopChatterFeedChatter, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? RecordEditModal {
            destination.trashDelegate = self
            destination.recordedUrl = self.recordedURL
            destination.friendsList = self.friendsList
        }
        
        if let destination = segue.destination as? UploadModalViewController {
            self.stopLandingChatter()
            destination.uploadedUrl = self.uploadedTempURL
        }
    }
    
    // Initialize Landing Feed ----------------------------------------------------------
    func initLandingFeed() {
        // Upon initialization, this will fire for EACH child in chatterFeed, and observe for each
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
    
    // Actions --------------------------------------------

    @IBAction func startRecord(_ sender: AnyObject) {
        if (!finishedRecording) {
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            self.toggleTask?.cancel()
            self.landingRecordLabel.layer.removeAllAnimations()
            
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
        // Haptic Feedback
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        if (self.isPlaying) {
            queueList(skip: true)
        }   else {
            queueList(skip: false)
            self.isPlaying = true
        }
    }
    
    @IBAction func unwindToLandingRecord(segue: UIStoryboardSegue) {}
}
