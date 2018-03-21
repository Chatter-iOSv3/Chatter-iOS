//
//  ChatterFeed.swift
//  Chatter
//
//  Created by Austen Ma on 2/28/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import AVFoundation
import AudioToolbox

class ChatterFeed: UIViewController {
    @IBOutlet weak var chatterScrollView: UIScrollView!
    @IBOutlet var chatterFeedView: UIView!
    
    var ref: DatabaseReference!
    let storage = Storage.storage()
    var userID: String?
    var storageRef: Any?
    
    var chatterFeedSegmentArray: [ChatterFeedSegmentView] = []
    // Current queue position of Feed
    var currentIdx: Int = 0
    var prevIdx: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chatterFeedSegmentArray = []
        
        ref = Database.database().reference()
        self.storageRef = storage.reference()
        self.userID = Auth.auth().currentUser?.uid
        
        // Setting up UI Constructors --------------------------------------------------------------------------
        chatterScrollView.contentSize = chatterFeedView.frame.size
        
        self.retrieveChatterFeedAndRender()
    }
    
    func retrieveChatterFeedAndRender() {
        let imageWidth:CGFloat = 300
        var imageHeight:CGFloat = 300
        var yPosition:CGFloat = 0
        var scrollViewContentSize:CGFloat=0;
        
        // Upon initialization, this will fire for EACH child in chatterFeed, and observe for each NEW -------------------------------------
        self.ref.child("users").child(self.userID!).child("chatterFeed").observe(.childAdded, with: { (snapshot) -> Void in
            // ************* Remember to add conditional to filter/delete based on date **************
            
            let value = snapshot.value as? NSDictionary
            
            let id = value?["id"] as? String ?? ""
            let userDetails = value?["userDetails"] as? String ?? ""
            
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let localURL = documentsURL.appendingPathComponent("\(id.suffix(10)).m4a")
            
            let newView = ChatterFeedSegmentView()
            //            newView.layer.borderWidth = 1
            //            newView.layer.borderColor = UIColor.purple.cgColor
            newView.contentMode = UIViewContentMode.scaleAspectFit
            newView.frame.size.width = imageWidth
            newView.frame.size.height = imageHeight
            newView.center = self.view.center
            newView.frame.origin.y = yPosition
            
            // Generate audio file on UIView instance
            newView.generateAudioFile(audioURL: localURL, id: id)
            
            // Calculate waveForm multiplier before async
            let multiplier = self.calculateMultiplierWithAudio(audioUrl: localURL)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // change 1 to desired number of seconds
                newView.generateWaveForm(audioURL: localURL, multiplier: multiplier)
            }
            
            self.chatterScrollView.addSubview(newView)
            let spacer:CGFloat = 0
            yPosition+=imageHeight + spacer
            scrollViewContentSize+=imageHeight + spacer
            
            // Calculates running total of how long the scrollView needs to be with the variables
            self.chatterScrollView.contentSize = CGSize(width: imageWidth, height: scrollViewContentSize)
            
            imageHeight = 300
            
            self.chatterFeedSegmentArray.append(newView)
        })
    }
    
    func calculateMultiplierWithAudio(audioUrl: URL) -> Float {
        let asset = AVURLAsset(url: audioUrl)
        let audioDuration = asset.duration
        let audioDurationSeconds = CMTimeGetSeconds(audioDuration)
        
        return Float(audioDurationSeconds * 9.5)
    }
    
    deinit {
        print("DEINITIALIZING")
        let userID = Auth.auth().currentUser?.uid
        self.ref.child("users").child(userID!).child("chatterFeed").removeAllObservers()
    }
    
    @IBAction func animateButton(sender: UIButton) {
        print("ACTION FIRED")
        self.chatterFeedSegmentArray[self.prevIdx].player?.stop()
        
        sender.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 1.25,
                       delay: 0,
                       usingSpringWithDamping: CGFloat(0.20),
                       initialSpringVelocity: CGFloat(6.0),
                       options: UIViewAnimationOptions.allowUserInteraction,
                       animations: {
                        sender.transform = CGAffineTransform.identity
        },
                       completion: { Void in()  }
        )
    }
}

