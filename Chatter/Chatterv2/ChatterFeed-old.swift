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

protocol SwitchRecChatterViewDelegate
{
    func SwitchRecChatterView(toPage: String)
}

class ChatterFeedOld: UIViewController {
    @IBOutlet weak var chatterScrollView: UIScrollView!
    @IBOutlet var chatterFeedView: UIView!
    
    var switchDelegate:SwitchRecChatterViewDelegate?
    
    var ref: DatabaseReference!
    let storage = Storage.storage()
    
    var chatterFeedSegmentArray: [ChatterFeedSegmentView] = []
    // Current queue position of Feed
    var currentIdx: Int = 0
    var prevIdx: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chatterFeedSegmentArray = []
        
        // Listens for Hear Chatter queue from Landing
        NotificationCenter.default.addObserver(self, selector: #selector(queueNextChatter(notification:)), name: .queueNextChatter, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(chatterFinishedAndQueue(notification:)), name: .chatterFinishedAndQueue, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(chatterChangedAndQueue(notification:)), name: .chatterChangedAndQueue, object: nil)
        
        ref = Database.database().reference()
        let storageRef = storage.reference()
        let userID = Auth.auth().currentUser?.uid
        
        // Setting up UI Constructors --------------------------------------------------------------------------
        chatterScrollView.contentSize = chatterFeedView.frame.size
        
        let imageWidth:CGFloat = 300
        var imageHeight:CGFloat = 300
        var yPosition:CGFloat = 0
        var scrollViewContentSize:CGFloat=0;

        // Upon initialization, this will fire for EACH child in chatterFeed, and observe for each NEW -------------------------------------
        self.ref.child("users").child(userID!).child("chatterFeed").observe(.childAdded, with: { (snapshot) -> Void in
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // change 1 to desired number of seconds
                newView.generateWaveForm(audioURL: localURL)
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func queueNextChatter(notification: NSNotification) {
        // Takes in an identifier, related to its position in overall array
        print(self.chatterFeedSegmentArray)
        
        // Stop audio from previous Chatter
        if (self.chatterFeedSegmentArray[self.prevIdx].player?.isPlaying)! {
            self.chatterFeedSegmentArray[self.prevIdx].player?.stop()
        }
        
        self.chatterFeedSegmentArray[self.currentIdx].playAudio()
        
        self.prevIdx = self.currentIdx
        // Auto-Queuing from Hear Chatter button
        if (self.currentIdx + 1 < self.chatterFeedSegmentArray.count) {
            // Queue next Chatter
            self.currentIdx += 1
        }   else {
            // Reset Feed
            self.currentIdx = 0
        }
    }
    
    @objc func chatterFinishedAndQueue(notification: NSNotification) {
        self.queueNextChatter(notification: notification)
    }
    
    @objc func chatterChangedAndQueue(notification: NSNotification) {
        // Find out which Idx has been tapped
        let tappedPlayer = notification.userInfo!["player"] as! ChatterFeedSegmentView
        
        for (index, player) in self.chatterFeedSegmentArray.enumerated() {
            if (player == tappedPlayer) {
                print("FOUND PLAYER: \(index)")
                
                // Set to current index
                self.currentIdx = index
                
                // Queue Next
                self.queueNextChatter(notification: notification)
            }
        }
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

        switchDelegate?.SwitchRecChatterView(toPage: "recordView")
    }
}
