//
//  LandingPagePreLoader.swift
//  Chatter
//
//  Created by Austen Ma on 5/2/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase

extension Menu {
    
    func preloadFollowersList() {
        var followerLabelArray: [String] = []
        var followerIDArray: [String] = []
        var followerItemArray: [LandingRecord.friendItem] = []
        
        // Grab the invites array from DB
        self.ref.child("users").child(userID!).child("follower").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            
            if (value != nil) {
                for user in value! {
                    let followerID = user.key as? String
                    
                    // Retrieve username with ID
                    self.ref.child("users").child(followerID!).child("username").observeSingleEvent(of: .value, with: { (snapshot) in
                        let followerUsername = snapshot.value as? String
                        
                        if (!followerLabelArray.contains(followerUsername!)) {
                            followerLabelArray.append(followerUsername!)
                            followerIDArray.append(followerID!)
                            
                            // Send notification with FollowerSet to composeModal
                            self.getFollowerProfileImage(userDetails: followerID!) { (result: UIImage) in
                                let currFollowerItem = LandingRecord.friendItem(userID: followerID!, userName: followerUsername!, profileImage: result)
                                self.preloadedFollowersList.append(currFollowerItem)
                                
                                // Send updated items to compose modal
                                NotificationCenter.default.post(name: .sendToComposeModalFriendsList, object: nil, userInfo: ["userData": currFollowerItem])
                                
                                // Update followersView list
                                self.followersVC.followerItemArray = self.preloadedFollowersList
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
    
    func getFollowerProfileImage(userDetails: String, completionHandler: @escaping(_ result: UIImage) -> Void) {
        
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
