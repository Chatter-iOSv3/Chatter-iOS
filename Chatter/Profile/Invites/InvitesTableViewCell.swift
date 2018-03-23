//
//  InvitationsTableCell.swift
//  Chatter
//
//  Created by Austen Ma on 3/11/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase

protocol RerenderInvitationsTableViewDelegate
{
    func RerenderInvitationsTableView()
}

class InvitesTableViewCell: UITableViewCell {
    @IBOutlet weak var inviterUsernameLabel: UILabel!
    @IBOutlet weak var inviteDenyButton: UIButton!
    @IBOutlet weak var inviteAcceptButton: UIButton!
    
    var inviterID: String!
    
    var ref = Database.database().reference()
    let userID = Auth.auth().currentUser?.uid
    
    var rerenderDelegate: RerenderInvitationsTableViewDelegate?
    
    @IBAction func acceptInvitation(sender: UIButton) {
        print(self.inviterID)
        
        // Use InviterID and UserID to exchange follower list data
        ref.child("users").child(userID!).child("follower").updateChildValues([inviterID: ["userDetails": ""]]) {error,ref in
            self.ref.child("users").child(self.inviterID!).child("following").updateChildValues([self.userID!: ["userDetails": ""]]) {error,ref in
                print("follower invitation Exchanged!")
                // Delete Invitation
                self.ref.child("users").child(self.userID!).child("invitations").child(self.inviterID).removeValue() { error, ref in
                    // Call re-render on tableView
                    self.rerenderDelegate?.RerenderInvitationsTableView()
                    
                    // Send notification to re-render follower tableView
                    NotificationCenter.default.post(name: .invitationAcceptedRerenderFollowers, object: nil)
                }
            }
        }
    }
    
    @IBAction func denyInvitation(sender: UIButton) {
        print(self.inviterID)
        
        // Delete Invitation
    }
    
    @IBAction func animateButton(sender: UIButton) {
        sender.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 1.25,
                       delay: 0,
                       usingSpringWithDamping: CGFloat(0.40),
                       initialSpringVelocity: CGFloat(6.0),
                       options: UIViewAnimationOptions.allowUserInteraction,
                       animations: {
                        sender.transform = CGAffineTransform.identity
        },
                       completion: { Void in()  }
        )
    }
}
