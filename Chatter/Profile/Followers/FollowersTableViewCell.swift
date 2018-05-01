//
//  FollowersTableViewCell.swift
//  Chatter
//
//  Created by Austen Ma on 3/12/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class FollowersTableViewCell: UITableViewCell {
    @IBOutlet weak var followerAvatarView: UIView!
    @IBOutlet weak var followerUsernameLabel: UILabel!
    
    var ref = Database.database().reference()
    let storage = Storage.storage()
    let userID = Auth.auth().currentUser?.uid
    var storageRef: Any?
    
    var followerUsernameFirstLetter: String!
    var followerUserID: String!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setProfileImageAvatar(userDetails: self.followerUserID, newView: self.followerAvatarView)
    }
    
    // Avatar Methods ----------------------------------------------------------
    
    func setProfileImageAvatar(userDetails: String, newView: UIView) {
        self.ref.child("users").child(userDetails).observeSingleEvent(of: .value) {
            (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            if let profileImageURL = value?["profileImageURL"] as? String {
                self.setProfileImageAvatarWithURL(imageURL: profileImageURL, newView: newView)
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
            
            var resizedCurrImage = self.resizeImage(image: currImage!, targetSize: CGSize(width: 40, height:  40))
            newView.backgroundColor = UIColor(patternImage: resizedCurrImage)
        })
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
        UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.scale)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
