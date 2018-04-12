//
//  DirectChatter.swift
//  Chatter
//
//  Created by Austen Ma on 4/3/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import XLPagerTabStrip
import Firebase

class DirectChatter: UIViewController, IndicatorInfoProvider {
    @IBOutlet weak var directScrollView: UIScrollView!
    @IBOutlet var directView: UIView!
    
    // Initialize Firebase
    var ref: DatabaseReference!
    let storage = Storage.storage()
    var userID: String?
    var storageRef: Any?
    
    // Array Chatter Rooms
    var directChatterRoomsArray: [UIView] = []
    var directChatterRoomsIDArray: [String] = []
    
    // Scrollview Values
    var yPosition:CGFloat = 0
    var scrollViewContentSize:CGFloat=0
    let imageWidth:CGFloat = 300
    var imageHeight:CGFloat = 100
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setting up UI Constructors
        directScrollView.contentSize = directView.frame.size
        
        ref = Database.database().reference()
        self.storageRef = storage.reference()
        self.userID = Auth.auth().currentUser?.uid
        
        self.retrieveDirectChatterAndRender()
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Direct")
    }
    
    func retrieveDirectChatterAndRender() {

        // Upon initialization, this will fire for EACH child in Direct Chatter, and observe for each NEW -------------------------------------
        self.ref.child("users").child(self.userID!).child("chatterRooms").observe(.childAdded, with: { (snapshot) -> Void in
            // ************************ Refactor Here *******************************
            
            if (!self.directChatterRoomsIDArray.contains(snapshot.key)) {
                let value = snapshot.value as? NSDictionary
                
                let users = value?["users"] as? String ?? ""
                
                if let chatterRoomSegments = value?["chatterRoomSegments"] as? NSDictionary {
                    print("Segments Exist! \(users)")
                    
                    self.constructDirectChatterRooms(users: users, chatterRoomSegments: chatterRoomSegments)
                    self.directChatterRoomsIDArray.append(snapshot.key)
                }   else {
                    self.constructDirectChatterRooms(users: users, chatterRoomSegments: [:])
                    self.directChatterRoomsIDArray.append(snapshot.key)
                }
            }
        })
    } 
    
    // View Methods ----------------------------------------------------------------------------------
    
    func constructDirectChatterRooms(users: String, chatterRoomSegments: NSDictionary) {
        // Generate the view for the ChatterSegment
        let newView = DirectChatterRoomView()
        newView.contentMode = UIViewContentMode.scaleAspectFit
        newView.frame.size.width = self.imageWidth
        newView.frame.size.height = self.imageHeight
        newView.frame.origin.x = newView.frame.origin.x + 65
        newView.frame.origin.y = self.yPosition + 5
        newView.layer.cornerRadius = 30
        newView.chatterRoomSegments = chatterRoomSegments
        
        // Generate Segment Divider
        let dividerLine = CALayer()
        dividerLine.frame = CGRect(x: newView.frame.width - self.directScrollView.frame.width + 10, y: newView.frame.height - 17, width: self.directScrollView.frame.width, height: 0.5)
        dividerLine.backgroundColor = UIColor(red: 214/255, green: 214/255, blue: 214/255, alpha: 1.0).cgColor
        newView.layer.addSublayer(dividerLine)
        
        // Generate the view for the Avatar
        let newAvatarView = UIView()
        newAvatarView.frame.size.width = 67
        newAvatarView.frame.size.height = 67
        newAvatarView.frame.origin.x = 10
        newAvatarView.frame.origin.y = self.yPosition + 5
        newAvatarView.layer.cornerRadius = newAvatarView.frame.size.height / 2
        newAvatarView.layer.borderWidth = 3
        newAvatarView.layer.borderColor = UIColor.white.cgColor
        newAvatarView.layer.backgroundColor = self.generateRandomColor().cgColor
        self.setProfileImageAvatar(userDetails: users, newView: newAvatarView)
        
        // Generate the avatar placeholder view
        let newAvatarPlaceholderView = UIView()
        newAvatarPlaceholderView.frame.size.width = 65
        newAvatarPlaceholderView.frame.size.height = 65
        newAvatarPlaceholderView.frame.origin.x = 40
        newAvatarPlaceholderView.frame.origin.y = self.yPosition + 5
        newAvatarPlaceholderView.layer.backgroundColor = UIColor(red: 119/255, green: 211/255, blue: 239/255, alpha: 1.0).cgColor
        self.directScrollView.addSubview(newAvatarPlaceholderView)
        
        // Add the subviews
        self.directScrollView.addSubview(newView)
        self.directScrollView.addSubview(newAvatarView)
        let spacer:CGFloat = 0
        self.yPosition+=self.imageHeight + spacer
        self.scrollViewContentSize+=self.imageHeight + spacer
        
        // Calculates running total of how long the scrollView needs to be with the variables
        self.directScrollView.contentSize = CGSize(width: self.imageWidth, height: self.scrollViewContentSize)
        
        self.imageHeight = 100
        
        self.directChatterRoomsArray.append(newView)
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

