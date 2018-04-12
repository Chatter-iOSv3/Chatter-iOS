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
        
        ref = Database.database().reference()
        self.storageRef = storage.reference()
        self.userID = Auth.auth().currentUser?.uid
        
        // Setting up UI Constructors
        chatterScrollView.contentSize = chatterFeedView.frame.size
        
        self.retrieveChatterFeedAndRender()
    }
    
    func retrieveChatterFeedAndRender() {
        let imageWidth:CGFloat = 300
        var imageHeight:CGFloat = 100
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
            newView.frame.origin.x = newView.frame.origin.x + 65
            newView.frame.origin.y = yPosition + 5
            newView.layer.cornerRadius = 30
            
            // Generate Segment Divider
            let dividerLine = CALayer()
            dividerLine.frame = CGRect(x: newView.frame.width - self.chatterScrollView.frame.width + 10, y: newView.frame.height - 17, width: self.chatterFeedView.frame.width, height: 0.5)
            dividerLine.backgroundColor = UIColor(red: 214/255, green: 214/255, blue: 214/255, alpha: 1.0).cgColor
            newView.layer.addSublayer(dividerLine)
            
            // Generate the view for the Avatar
            let newAvatarView = UIView()
            newAvatarView.frame.size.width = 66
            newAvatarView.frame.size.height = 66
            newAvatarView.frame.origin.x = 10
            newAvatarView.frame.origin.y = yPosition + 4
            newAvatarView.layer.cornerRadius = newAvatarView.frame.size.height / 2
            newAvatarView.layer.borderWidth = 3
            newAvatarView.layer.borderColor = UIColor.white.cgColor
            newAvatarView.layer.backgroundColor = self.generateRandomColor().cgColor
            self.setProfileImageAvatar(userDetails: userDetails, newView: newAvatarView)
            
            // Generate the avatar placeholder view
            let newAvatarPlaceholderView = UIView()
            newAvatarPlaceholderView.frame.size.width = 65
            newAvatarPlaceholderView.frame.size.height = 65
            newAvatarPlaceholderView.frame.origin.x = 40
            newAvatarPlaceholderView.frame.origin.y = yPosition + 5
            newAvatarPlaceholderView.layer.backgroundColor = UIColor(red: 119/255, green: 211/255, blue: 239/255, alpha: 1.0).cgColor
            self.chatterScrollView.addSubview(newAvatarPlaceholderView)
            
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
            
            imageHeight = 100
            
            self.chatterFeedSegmentArray.append(newView)
        })
    }
    
    func setProfileImageAvatar(userDetails: String, newView: UIView) {
        self.ref.child("users").child(userDetails).observeSingleEvent(of: .value) {
            (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            if let profileImageURL = value?["profileImageURL"] as? String {
                self.setProfileImageAvatarWithURL(imageURL: profileImageURL, newView: newView)
            }   else {
                let firstname = value?["firstname"] as? String ?? ""
                let firstnameLetter = String(describing: firstname.first!)
                self.setProfileImageAvatarWithLabel(firstnameLetter: firstnameLetter, newView: newView)
            }
        }
    }
    
    func setProfileImageAvatarWithURL(imageURL: String, newView: UIView) {
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
            
            var resizedCurrImage = self.resizeImage(image: currImage!, targetSize: CGSize(width: 65, height:  65))
            newView.backgroundColor = UIColor(patternImage: resizedCurrImage)
        })
    }
    
    func setProfileImageAvatarWithLabel(firstnameLetter: String, newView: UIView) {
        // Label Avatar button
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        label.textAlignment = .center
        label.font = label.font.withSize(20)
        label.textColor = .white
        label.text = firstnameLetter
        newView.addSubview(label)
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Feed")
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
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

