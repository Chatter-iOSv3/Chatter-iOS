//
//  MenuViewController.swift
//  Chatter
//
//  Created by Austen Ma on 3/11/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase

protocol SwitchMenuFollowersViewDelegate
{
    func SwitchMenuFollowersView(toPage: String)
}

protocol SwitchMenuFollowingViewDelegate
{
    func SwitchMenuFollowingView(toPage: String)
}

protocol SwitchMenuInvitesViewDelegate
{
    func SwitchMenuInvitesView(toPage: String)
}

class MenuView: UIViewController {
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userAvatarButton: UIButton!
    @IBOutlet weak var profileView: UIView!
    
    @IBOutlet weak var followingCountLabel: UILabel!
    @IBOutlet weak var followerCountLabel: UILabel!
    
    @IBOutlet weak var bitmojiButton: UIButton!
    @IBOutlet weak var syncContactsButton: UIButton!
    @IBOutlet weak var followRequestsButton: UIButton!
    @IBOutlet weak var connectDevicesButton: UIButton!
    
    
    // Initialize FB storage + DB
    var ref: DatabaseReference!
    let userID = Auth.auth().currentUser?.uid
    
    var switchMenuFollowersDelegate:SwitchMenuFollowersViewDelegate?
    var switchMenuInvitesDelegate:SwitchMenuInvitesViewDelegate?
    var switchMenuFollowingDelegate:SwitchMenuFollowingViewDelegate?
    
    override func viewDidLoad() {
        ref = Database.database().reference()
        
        // Set user full name, username, avatar button labels, and counts
        ref.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            
            let firstname = value?["firstname"] as? String ?? ""
            let lastname = value?["lastname"] as? String ?? ""
            
            self.fullNameLabel.text = firstname + " " + lastname
            
            let username = value?["username"] as? String ?? ""
            
            self.usernameLabel.text = "@" + username
            
            // Label Avatar button
            let firstnameLetter = String(describing: firstname.first!)
            self.userAvatarButton.setTitle(firstnameLetter, for: .normal)
            
            // Set follower/following counts
            let followers = value?["followers"] as? NSDictionary ?? [:]
            let following = value?["following"] as? NSDictionary ?? [:]
            
            self.followerCountLabel.text = String(followers.count)
            self.followingCountLabel.text = String(following.count)
            
            self.configureAvatarButton()
            self.configureProfileView()
            self.configureButtons()
        })
    }
    
    @IBAction func goToFollowers(sender: AnyObject) {
        switchMenuFollowersDelegate?.SwitchMenuFollowersView(toPage: "followerView")
    }
    
    @IBAction func goToInvites(sender: AnyObject) {
        switchMenuInvitesDelegate?.SwitchMenuInvitesView(toPage: "invitesView")
    }
    
    @IBAction func goToFollowing(sender: AnyObject) {
        switchMenuFollowingDelegate?.SwitchMenuFollowingView(toPage: "followingView")
    }
    
    @IBAction func signOut(sender: UIButton) {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
        // Calls unwind method to log out
        self.performSegue(withIdentifier: "unwindToLogin", sender: self)
    }
    
    func configureAvatarButton() {
        userAvatarButton.layer.cornerRadius = 0.5 * userAvatarButton.bounds.size.width
        userAvatarButton.clipsToBounds = true
        userAvatarButton.backgroundColor = UIColor(red: 179/255, green: 95/255, blue: 232/255, alpha: 1.0)
    }
    
    func configureProfileView() {
        let path = UIBezierPath(roundedRect:self.profileView.bounds,
                                byRoundingCorners:[.topRight, .topLeft],
                                cornerRadii: CGSize(width: 20, height:  20))
        
        let maskLayer = CAShapeLayer()
        
        maskLayer.path = path.cgPath
        self.profileView.layer.mask = maskLayer
    }
    
    func configureButtons() {
        self.bitmojiButton.layer.cornerRadius = self.bitmojiButton.frame.size.height / 2
        self.syncContactsButton.layer.cornerRadius = self.syncContactsButton.frame.size.height / 2
        self.followRequestsButton.layer.cornerRadius = self.followRequestsButton.frame.size.height / 2
        self.connectDevicesButton.layer.cornerRadius = self.connectDevicesButton.frame.size.height / 2
    }
}

