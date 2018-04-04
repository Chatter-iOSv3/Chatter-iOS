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
import XLPagerTabStrip

class ChatterFeed: UIViewController, IndicatorInfoProvider {
    @IBOutlet weak var chatterScrollView: UIScrollView!
    @IBOutlet var chatterFeedView: UIView!
    @IBOutlet weak var placeHolderCurveView: UIView!
    
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
        
        // Initial styling
        self.placeHolderCurveView.layer.cornerRadius = 37.5
        
        // Setting up UI Constructors --------------------------------------------------------------------------
        chatterScrollView.contentSize = chatterFeedView.frame.size
        
        self.retrieveChatterFeedAndRender()
    }
    
    func retrieveChatterFeedAndRender() {
        let imageWidth:CGFloat = 300
        var imageHeight:CGFloat = 125
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
            
            // Generate the view for the ChatterSegment
            let newView = ChatterFeedSegmentView()
            newView.contentMode = UIViewContentMode.scaleAspectFit
            newView.frame.size.width = imageWidth
            newView.frame.size.height = imageHeight
            newView.center = self.view.center
            newView.frame.origin.x = newView.frame.origin.x + 30
            newView.frame.origin.y = yPosition
            newView.layer.cornerRadius = 30
            
            // Generate the view for the Avatar
            let newAvatarView = UIView()
            newAvatarView.frame.size.width = 75
            newAvatarView.frame.size.height = 75
            newAvatarView.frame.origin.x = 10
            newAvatarView.frame.origin.y = yPosition
            newAvatarView.layer.cornerRadius = newAvatarView.frame.size.height / 2
            newAvatarView.layer.borderWidth = 4
            newAvatarView.layer.borderColor = self.generateRandomColor().cgColor
            newAvatarView.layer.backgroundColor = UIColor.white.cgColor
            
            // Generate audio and wave form for file on UIView instance
            newView.generateAudioFile(audioURL: localURL, id: id)
            
            newView.addSubview(newAvatarView)
            self.chatterScrollView.addSubview(newView)
            self.chatterScrollView.addSubview(newAvatarView)
            let spacer:CGFloat = 0
            yPosition+=imageHeight + spacer
            scrollViewContentSize+=imageHeight + spacer
            
            // Calculates running total of how long the scrollView needs to be with the variables
            self.chatterScrollView.contentSize = CGSize(width: imageWidth, height: scrollViewContentSize)
            
            imageHeight = 125
            
            self.chatterFeedSegmentArray.append(newView)
        })
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Chatter")
    }
    
    deinit {
        print("DEINITIALIZING")
        let userID = Auth.auth().currentUser?.uid
//        self.ref.child("users").child(userID!).child("chatterFeed").removeAllObservers()
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
    
    func generateRandomColor() -> UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from white
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.85 // from 0.5 to 1.0 to stay away from black
        
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
}

