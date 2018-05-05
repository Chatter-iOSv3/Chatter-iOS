//
//  FollowingsPreLoader.swift
//  Chatter
//
//  Created by Austen Ma on 5/5/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase

extension Menu {
    
    func preloadFollowingsList() {
        var followingLabelArray: [String] = []
        var followingIDArray: [String] = []
        var followingItemArray: [LandingRecord.friendItem] = []
        
        // Grab the invites array from DB
        self.ref.child("users").child(userID!).child("following").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            
            if (value != nil) {
                for user in value! {
                    let followingID = user.key as? String
                    
                    // Retrieve username with ID
                    self.ref.child("users").child(followingID!).child("username").observeSingleEvent(of: .value, with: { (snapshot) in
                        let followingUsername = snapshot.value as? String
                        
                        if (!followingLabelArray.contains(followingUsername!)) {
                            followingLabelArray.append(followingUsername!)
                            followingIDArray.append(followingID!)
                            
                            // Send notification with FollowingSet to composeModal
                            self.getFollowingProfileImage(userDetails: followingID!) { (result: UIImage) in
                                let currFollowingItem = LandingRecord.friendItem(userID: followingID!, userName: followingUsername!, profileImage: result)
                                self.preloadedFollowingsList.append(currFollowingItem)
                                
                                // Send updated items to compose modal
                                NotificationCenter.default.post(name: .sendToComposeModalFriendsList, object: nil, userInfo: ["userData": currFollowingItem])
                                
                                // Update followingsView list
                                self.followingsVC.followingItemArray = self.preloadedFollowingsList
                            }
                        }
                    })  { (error) in
                        print(error.localizedDescription)
                    }
                }
            }
        })  { (error) in
            print(error.localizedDescription)
        }
    }
    
    func getFollowingProfileImage(userDetails: String, completionHandler: @escaping(_ result: UIImage) -> Void) {
        
        self.ref.child("users").child(userDetails).observeSingleEvent(of: .value) {
            (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            if let profileImageURL = value?["profileImageURL"] as? String {
                let profileImageDownloadRef = self.storage.reference(forURL: profileImageURL)
                var currImage: UIImage?
                
                profileImageDownloadRef.downloadURL(completion: { (url, error) in
                    var data = Data()
                    
                    do {
                        data = try Data(contentsOf: url!)
                    } catch {
                        print(error)
                    }
                    currImage = UIImage(data: data as Data)
                    
                    completionHandler(currImage!)
                })
            }
        }
    }
}
