//
//  RecordEditModal.swift
//  Chatter
//
//  Created by Austen Ma on 3/19/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Firebase

protocol TrashRecordingDelegate
{
    func trashRecording()
}

class RecordEditModal: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    @IBOutlet weak var recordEditModalView: UIView!
    @IBOutlet weak var recordWaveFormView: UIView!
    @IBOutlet weak var saveRecordingButton: UIButton!
    
    var trashDelegate:TrashRecordingDelegate?
    
    // Initialize Audio player vars
    var player : AVAudioPlayer?
    var recordedUrl: URL?
    
    // Initialize Firebase vars
    let storage = Storage.storage()
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        recordEditModalView.layer.cornerRadius = 30
        recordWaveFormView.layer.cornerRadius = 20
    }
    
    @IBAction func playRecording(sender: Any) {
        let url = self.recordedUrl!
        do {
            // AVAudioPlayer setting up with the saved file URL
            let sound = try AVAudioPlayer(contentsOf: url)
            self.player = sound
            
            // If in the middle of another play
            sound.stop()

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
    
    @IBAction func closeRecordEdit(_ sender: Any) {
        trashDelegate?.trashRecording()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveRecording(sender: AnyObject) {
        print("SAVING")
        
        // Initialize FB storage ref
        let storageRef = storage.reference()
        let userID = Auth.auth().currentUser?.uid
        
        // Get audio url and generate a unique ID for the audio file
        let audioUrl = self.recordedUrl!
        let audioID = randomString(length: 10)
        let fullAudioID = "\(userID ?? "") | \(audioID)"
        
        // Saving the recording to FB
        let audioRef = storageRef.child("audio/\(fullAudioID)")
        
        audioRef.putFile(from: audioUrl, metadata: nil) { metadata, error in
            if let error = error {
                print(error)
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                //                    let downloadURL = metadata!.downloadURL()
                
                // Write to the ChatterFeed string in FB-DB
                self.ref.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
                    // Retrieve existing ChatterFeed
                    let value = snapshot.value as? NSDictionary
                    let currChatterFeedCount = (value!["chatterFeed"] as AnyObject).count
                    
                    // Generating chatterFeed # identifier
                    var countIdentifier: Int
                    if ((currChatterFeedCount) != nil) {
                        countIdentifier = currChatterFeedCount!
                    }   else {
                        countIdentifier = 0
                    }
                    
                    // Construct new ChatterFeed segment
                    var chatterFeedSegment = Dictionary<String, Any>()
                    chatterFeedSegment = ["id": fullAudioID, "userDetails": userID!, "dateCreated": self.getCurrentDate()]
                    
                    let childUpdates = ["\(countIdentifier)": chatterFeedSegment]
                    
                    // Get the list of followers
                    let follower = value!["follower"] as? NSDictionary
                    
                    // Update your Chatter feed, then feed in all follower
                    self.ref.child("users").child(userID!).child("chatterFeed").updateChildValues(childUpdates) {error, ref in
                        if (follower != nil) {
                            // Iterate through each follower and update their feed
                            for follower in follower! {
                                let followerID = follower.key as? String
                                self.ref.child("users").child(followerID!).child("chatterFeed").observeSingleEvent(of: .value, with: { (followerSnapshot) in
                                    let followerValue = followerSnapshot.value as? Any
                                    let followerChatterFeedCount = (followerValue! as AnyObject).count
                                    
                                    // Generating follower chatterFeed # identifier
                                    var followerCountIdentifier: Int
                                    if ((followerChatterFeedCount) != nil) {
                                        followerCountIdentifier = followerChatterFeedCount!
                                    }   else {
                                        followerCountIdentifier = 0
                                    }
                                    
                                    // Construct follower ChatterFeed segment
                                    var followerChatterFeedSegment = Dictionary<String, Any>()
                                    followerChatterFeedSegment = ["id": fullAudioID, "userDetails": userID!, "dateCreated": self.getCurrentDate()]
                                    
                                    let followerChildUpdates = ["\(followerCountIdentifier)": followerChatterFeedSegment]
                                    
                                    self.ref.child("users").child(followerID!).child("chatterFeed").updateChildValues(followerChildUpdates) {error, ref in
                                        print("UPDATE PROCESS COMPLETE: \(followerID)")
                                    }
                                })
                            }
                        }
                        
                        // Exit the modal
                        print("LOCAL SAVE SUCCESS")
                        self.trashDelegate?.trashRecording()
                        self.performSegue(withIdentifier: "unwindToLandingRecord", sender: self)
                    }
                }) { (error) in
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func animateButton(sender: UIButton) {

        sender.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)

        UIView.animate(withDuration: 1.25,
                       delay: 0,
                       usingSpringWithDamping: CGFloat(0.20),
                       initialSpringVelocity: CGFloat(8.0),
                       options: UIViewAnimationOptions.allowUserInteraction,
                       animations: {
                        sender.transform = CGAffineTransform.identity
        },
                       completion: { Void in()  }
        )
    }
    
    // OTHER UTILITIES --------------------------------------------------
    
    func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
    func getCurrentDate() -> String {
        let date = Date()
        let formatter = DateFormatter()
        
        formatter.dateFormat = "dd.MM.yyyy"
        
        let result = formatter.string(from: date)
        
        return result
    }
}
