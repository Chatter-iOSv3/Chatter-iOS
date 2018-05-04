//
//  Menu.swift
//  Chatter
//
//  Created by Austen Ma on 2/26/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class Menu: UIViewController, SwitchMenuFollowersViewDelegate, SwitchMenuInvitesViewDelegate, SwitchMenuFollowingViewDelegate {
    @IBOutlet weak var followerView: UIView!
    @IBOutlet var menuView: UIView!
    @IBOutlet weak var invitesView: UIView!
    @IBOutlet weak var followingView: UIView!
    
    // Firebase Variables
    var ref: DatabaseReference!
    let storage = Storage.storage()
    var storageRef: Any?
    var userID: String!
    
    var followersVC: FollowersView!
    
    var preloadedFollowersList: [LandingRecord.friendItem]! = []
    
    var preloadingFollowers: Bool = true
    
    override func viewDidLoad() {
        // Firebase initializers
        ref = Database.database().reference()
        self.storageRef = storage.reference()
        self.userID = Auth.auth().currentUser?.uid
        
        self.menuView.alpha = 1.0
        self.invitesView.alpha = 0.0
        self.followerView.alpha = 0.0
        self.followingView.alpha = 0.0
        
        self.preloadFollowersList()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.post(name: .stopLandingChatter, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? MenuView {
            destination.switchMenuFollowersDelegate = self
            destination.switchMenuInvitesDelegate = self
            destination.switchMenuFollowingDelegate = self
        }
        
        if let destination = segue.destination as? FollowersView {
            destination.switchDelegate = self
            self.followersVC = destination
        }
        
        if let destination = segue.destination as? InvitesView {
            destination.switchDelegate = self
        }
        
        if let destination = segue.destination as? FollowingView {
            destination.switchDelegate = self
        }
    }

    func SwitchMenuFollowersView(toPage: String) {
        if (toPage == "followerView") {
            UIView.animate(withDuration: 0.5, animations: {
                self.menuView.alpha = 0.0
                self.invitesView.alpha = 0.0
                self.followerView.alpha = 1.0
            })
        }   else {
            UIView.animate(withDuration: 0.5, animations: {
                self.menuView.alpha = 1.0
                self.followerView.alpha = 0.0
                self.invitesView.alpha = 0.0
            })
        }
    }
    
    func SwitchMenuFollowingView(toPage: String) {
        if (toPage == "followingView") {
            UIView.animate(withDuration: 0.5, animations: {
                self.menuView.alpha = 0.0
                self.invitesView.alpha = 0.0
                self.followerView.alpha = 0.0
                self.followingView.alpha = 1.0
            })
        }   else {
            UIView.animate(withDuration: 0.5, animations: {
                self.menuView.alpha = 1.0
                self.followerView.alpha = 0.0
                self.invitesView.alpha = 0.0
                self.followingView.alpha = 0.0
            })
        }
    }
    
    func SwitchMenuInvitesView(toPage: String) {
        if (toPage == "invitesView") {
            UIView.animate(withDuration: 0.5, animations: {
                self.menuView.alpha = 0.0
                self.followerView.alpha = 0.0
                self.invitesView.alpha = 1.0
            })
        }   else {
            UIView.animate(withDuration: 0.5, animations: {
                self.menuView.alpha = 1.0
                self.invitesView.alpha = 0.0
                self.invitesView.alpha = 0.0
            })
        }
    }
}

