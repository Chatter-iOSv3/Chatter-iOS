//
//  FollowPopup.swift
//  Chatter
//
//  Created by Austen Ma on 3/11/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class FollowModal: UIViewController {
    @IBOutlet weak var modalView: UIView!
    @IBOutlet weak var inviteUsernameInput: UITextField!
    @IBOutlet weak var inviteButton: UIButton!
    
    var ref: DatabaseReference!
    let userID = Auth.auth().currentUser?.uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up modal styling
        modalView.layer.cornerRadius = 10
        inviteButton.layer.cornerRadius = inviteButton.frame.size.height / 2 - 10
        
        let inviteUsernameInputBottomLine = CALayer()
        inviteUsernameInputBottomLine.frame = CGRect(x: 0.0, y: self.inviteUsernameInput.frame.height - 1, width: self.inviteUsernameInput.frame.width, height: 0.5)
        inviteUsernameInputBottomLine.backgroundColor = UIColor.gray.cgColor
        self.inviteUsernameInput.borderStyle = UITextBorderStyle.none
        self.inviteUsernameInput.layer.addSublayer(inviteUsernameInputBottomLine)
        
        // Initiate Firebase
        ref = Database.database().reference()
    }
    
    @IBAction func closeModal(sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func sendInvite(sender: AnyObject) {
        print("INITIATE INVITATION")
        guard let inviteUsername = inviteUsernameInput.text else {return}
        
        ref.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            
            // Iterate through users to find matching user data with username
            for user in value! {
                let currUserDetails = user.value as? NSDictionary
                let currUserID = user.key as? String
                
                if (String(describing: currUserDetails!["username"]!) == inviteUsername && self.userID != currUserID) {
                    print("FOUND USER: \(user)")
                    
                    let invitedUserID = user.key as? String
                    
                    // Send an invitation by storing an invitation property in the invited's data
                    let invitationData: [String: String] = [self.userID!: "Invitation Message Link Here!"]
                    self.ref.child("users").child(invitedUserID!).child("invitations").updateChildValues(invitationData) { (error, ref) -> Void in
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        })
    }
}

