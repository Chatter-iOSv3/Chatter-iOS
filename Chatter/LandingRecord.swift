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
import UICircularProgressRing
import Firebase

protocol MenuActionDelegate {
    func openSegue(_ segueName: String, sender: AnyObject?)
    func reopenMenu()
}

protocol SwitchChatterButtonToUtilitiesDelegate
{
    func SwitchChatterButtonToUtilities(toFunction: String)
}

class LandingRecord: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate{
    
    @IBOutlet weak var recordProgress: UIProgressView!
    
    // Initialize FB storage + DB
    let storage = Storage.storage()
    var ref: DatabaseReference!
 
    var switchDelegate:SwitchChatterButtonToUtilitiesDelegate?
    
    var isRecording = false
    var audioRecorder: AVAudioRecorder?
    var player : AVAudioPlayer?
    var finishedRecording = false

    let interactor = Interactor()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Firebase DB Reference
        ref = Database.database().reference()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startRecord(_ sender: AnyObject) {
        if sender.state == UIGestureRecognizerState.began
        {
            print("LONG CLICK RECOGNIZED")
        }
        else if (sender.state == UIGestureRecognizerState.ended)
        {
            print("ENDED RECORDING")
        }
//        if (!finishedRecording) {
//            if (sender.state == UIGestureRecognizerState.began) {
//                // Code to start recording
//                startRecording()
//
//                self.circularProgressRing.setProgress(value: 100, animationDuration: 30.0) {
//                    if (self.circularProgressRing.currentValue == 100) {
//                        UIView.animate(withDuration: 0.5, animations: {
//                            self.recordingFilters.alpha = 1.0
//                        })
//                        // Ending Animation
//                        self.recButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
//
//                        UIView.animate(withDuration: 1.25,
//                                       delay: 0,
//                                       usingSpringWithDamping: CGFloat(0.60),
//                                       initialSpringVelocity: CGFloat(6.0),
//                                       options: UIViewAnimationOptions.allowUserInteraction,
//                                       animations: {
//                                        self.recButton.transform = CGAffineTransform.identity
//                        },
//                                       completion: { Void in()  }
//                        )
//
//                        //Code to stop recording
//                        self.finishRecording()
//                        self.finishedRecording = true
//
//                        // Code to start playback
//                        self.playSound()
//                    }
//                }
//            }   else if (sender.state == UIGestureRecognizerState.ended && !self.finishedRecording) {
//                // Case if recording ends before time limit
//                self.circularProgressRing.setProgress(value: 0, animationDuration: 0.5) {
//                    print("FINISHED RECORDING.")
//                    UIView.animate(withDuration: 0.5, animations: {
//                        self.recordingFilters.alpha = 1.0
//                    })
//
//                    //Code to stop recording
//                    self.finishRecording()
//                    self.finishedRecording = true
//
//                    // Code to start playback
//                    self.playSound()
//                }
//            }
//        }
        
    }

//    @IBAction func animateButton(sender: UIButton) {
//
//        sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
//
//        UIView.animate(withDuration: 1.25,
//                       delay: 0,
//                       usingSpringWithDamping: CGFloat(0.30),
//                       initialSpringVelocity: CGFloat(6.0),
//                       options: UIViewAnimationOptions.allowUserInteraction,
//                       animations: {
//                        sender.transform = CGAffineTransform.identity
//        },
//                       completion: { Void in()  }
//        )
//    }
    
    @IBAction func openMenu(sender: AnyObject) {
        performSegue(withIdentifier: "openMenu", sender: nil)
    }
    
    @IBAction func edgePanGesture(_ sender: UIScreenEdgePanGestureRecognizer) {
        let translation = sender.translation(in: view)
        
        let progress = MenuHelper.calculateProgress(translation, viewBounds: view.bounds, direction: .right)
        
        MenuHelper.mapGestureStateToInteractor(
            sender.state,
            progress: progress,
            interactor: interactor){
                self.performSegue(withIdentifier: "openMenu", sender: nil)
        }
    }
    
    @IBAction func saveRecording(sender: AnyObject) {
        if (finishedRecording) {
            
            print("SAVING")
            
            // Initialize FB storage ref
            let storageRef = storage.reference()
            let userID = Auth.auth().currentUser?.uid
            
            // Get audio url and generate a unique ID for the audio file
            let audioUrl = getAudioFileUrl()
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
                        
                        // Get the list of follower
                        let follower = value!["follower"] as! NSDictionary
                        
                        // Update your Chatter feed, then feed in all follower
                        self.ref.child("users").child(userID!).child("chatterFeed").updateChildValues(childUpdates) {error, ref in
                            
                            // Iterate through each follower and update their feed
                            for follower in follower {
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
                        
                        print("LOCAL SAVE SUCCESS")
                    
                    }) { (error) in
                        print(error.localizedDescription)
                    }
                }
            }
            
            // Stop the looping
            self.player?.stop()
            
            // Trash the recording
            self.switchDelegate?.SwitchChatterButtonToUtilities(toFunction: "finished")
            
            // Reset recording
            self.finishedRecording = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? Menu {
            destinationViewController.transitioningDelegate = self
            destinationViewController.interactor = interactor
            destinationViewController.menuActionDelegate = self
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
    
    func finishRecording() {
        audioRecorder?.stop()
        isRecording = false
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            finishRecording()
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
    
    // Recording Utilities ---------------------------------------------------------
    
    @objc func trashRecording(notification: NSNotification) {
        isRecording = false
        
        // Stop the looping
        self.player?.stop()
        
        // Reset recording
        finishedRecording = false
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

extension LandingRecord: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentMenuAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissMenuAnimator()
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}

extension LandingRecord: MenuActionDelegate {
    func openSegue(_ segueName: String, sender: AnyObject?) {
        dismiss(animated: true){
            self.performSegue(withIdentifier: segueName, sender: sender)
        }
    }
    func reopenMenu(){
        performSegue(withIdentifier: "openMenu", sender: nil)
    }
}
