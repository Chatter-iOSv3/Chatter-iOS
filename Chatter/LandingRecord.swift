//
//  LandingRecord.swift
//  Chatter
//
//  Created by Austen Ma on 2/27/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Pulsator
import AVFoundation
import AudioToolbox

protocol MenuActionDelegate {
    func openSegue(_ segueName: String, sender: AnyObject?)
    func reopenMenu()
}

protocol SwitchChatterButtonToUtilitiesDelegate
{
    func SwitchChatterButtonToUtilities(toFunction: String)
}

class LandingRecord: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate{
    
    @IBOutlet weak var topNavView: UIView!
    @IBOutlet weak var recButtonCover: UIView!
    @IBOutlet weak var pulseView: UIView!
    @IBOutlet weak var recButton: UIButton!
    @IBOutlet weak var recordingFilters: UIScrollView!
    @IBOutlet var swipeSaveRecording: UISwipeGestureRecognizer!
    
    var switchDelegate:SwitchChatterButtonToUtilitiesDelegate?
    
    var isRecording = false
    var audioRecorder: AVAudioRecorder?
    var player : AVAudioPlayer?
    var finishedRecording = false

    let pulsator = Pulsator()
    let interactor = Interactor()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        pulseView.layer.addSublayer(pulsator)
        pulsator.backgroundColor = UIColor(red: 0.75, green: 0, blue: 1, alpha: 1).cgColor
        
        topNavView.addBorder(toSide: .Bottom, withColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0.2).cgColor, andThickness: 1.0)
        self.recordingFilters.alpha = 0.0
        
        // Notification center, listening for recording utilities actions
        NotificationCenter.default.addObserver(self, selector: #selector(trashRecording(notification:)), name: .trashing, object: nil)
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidLayoutSubviews() {
        configureButton()
        configureFilterButtons()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func animateRecButton(sender: UIButton) {
        if (!finishedRecording) {
            sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
            UIView.animate(withDuration: 1.25,
                           delay: 0,
                           usingSpringWithDamping: CGFloat(0.30),
                           initialSpringVelocity: CGFloat(6.0),
                           options: UIViewAnimationOptions.allowUserInteraction,
                           animations: {
                            sender.transform = CGAffineTransform.identity
            },
                           completion: { Void in()  }
            )
        
            if (!pulsator.isPulsating) {
                pulsator.numPulse = 6
                pulsator.animationDuration = 2
                pulsator.radius = 170.0
                pulsator.start()
                
                // Toggle on utilities
                switchDelegate?.SwitchChatterButtonToUtilities(toFunction: "recording")
                
                // Code to start recording
                startRecording()
                
            }   else {
                pulsator.stop()
                UIView.animate(withDuration: 0.5, animations: {
                    self.recordingFilters.alpha = 1.0
                })
                
                //Code to stop recording
                finishRecording()
                finishedRecording = true
                
                // Code to start playback
                playSound()
            }
        }
    }

    @IBAction func animateButton(sender: UIButton) {
        
        sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        UIView.animate(withDuration: 1.25,
                       delay: 0,
                       usingSpringWithDamping: CGFloat(0.30),
                       initialSpringVelocity: CGFloat(6.0),
                       options: UIViewAnimationOptions.allowUserInteraction,
                       animations: {
                        sender.transform = CGAffineTransform.identity
        },
                       completion: { Void in()  }
        )
    }
    
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
        print("SAVING")
        if (finishedRecording) {
            // Saving animation
            recButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: 1.5,
                           delay: 0,
                           usingSpringWithDamping: CGFloat(0.6),
                           initialSpringVelocity: CGFloat(50.0),
                           options: UIViewAnimationOptions.allowUserInteraction,
                           animations: {
                            self.recButton.transform = CGAffineTransform.identity
            },
                           completion: { Void in()  }
            )
        
            // Return to recording view
            UIView.animate(withDuration: 0.5, animations: {
                self.recordingFilters.alpha = 0.0
            })
            // Stop the looping
            self.player?.stop()
        
            // Trash the recording
            switchDelegate?.SwitchChatterButtonToUtilities(toFunction: "finished")
        
            // Reset recording
            finishedRecording = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? Profile {
            destinationViewController.transitioningDelegate = self
            destinationViewController.interactor = interactor
            destinationViewController.menuActionDelegate = self
        }
    }

    //    UI Configuration --------------------------------------

    // Configures Circle Blank Behind Record Button
    func configureButton()
    {
        recButtonCover.layer.cornerRadius = 0.5 * recButtonCover.bounds.size.width
        recButtonCover.layer.borderColor = UIColor(red:0, green:0, blue:0, alpha:0).cgColor as CGColor
        recButtonCover.layer.borderWidth = 2.0
        recButtonCover.clipsToBounds = true
    }
    
    func configureFilterButtons()
    {
        recButtonCover.layer.cornerRadius = 0.5 * recButtonCover.bounds.size.width
        recButtonCover.layer.borderColor = UIColor(red:0, green:0, blue:0, alpha:0).cgColor as CGColor
        recButtonCover.layer.borderWidth = 2.0
        recButtonCover.clipsToBounds = true
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
        UIView.animate(withDuration: 0.5, animations: {
            self.recordingFilters.alpha = 0.0
        })
        pulsator.stop()
        isRecording = false
        
        // Stop the looping
        self.player?.stop()
        
        // Trash the recording
        switchDelegate?.SwitchChatterButtonToUtilities(toFunction: "finished")
        
        // Reset recording
        finishedRecording = false
    }

}

extension Notification.Name {
    static let trashing = Notification.Name("trashing")
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
