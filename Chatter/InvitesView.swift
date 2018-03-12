//
//  InvitesView.swift
//  Chatter
//
//  Created by Austen Ma on 3/11/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class InvitesView: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var invitesTableView: UITableView!
    @IBOutlet weak var backToMenuButton: UIButton!
    
    var switchDelegate:SwitchMenuFriendsViewDelegate?
    
    var ref: DatabaseReference!
    let userID = Auth.auth().currentUser?.uid
    
    var invitationsArray: [String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        self.invitationsArray = []
        
        // Needed to initialize table view programmatically
        invitesTableView.delegate = self
        invitesTableView.dataSource = self
        
        // Grab the invites array from DB
        ref.child("users").child(userID!).child("invitations").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            
            if (value != nil) {
                for user in value! {
                    print("INVITATION FROM: \(user)")
                    let inviterID = user.key as? String
                    
                    // Retrieve username with ID
                    self.ref.child("users").child(inviterID!).child("username").observeSingleEvent(of: .value, with: { (snapshot) in
                        let inviterUsername = snapshot.value as? String
                        
                        self.invitationsArray.append(inviterUsername!)
                        
                        // Populate the Table View as the invitations are loaded
                        self.invitesTableView.reloadData()
                    })  { (error) in
                        print(error.localizedDescription)
                    }
                }
            }
        })  { (error) in
            print(error.localizedDescription)
        }
    }
    
    @IBAction func backToMenu() {
        backToMenuButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 1.25,
                       delay: 0,
                       usingSpringWithDamping: CGFloat(0.40),
                       initialSpringVelocity: CGFloat(6.0),
                       options: UIViewAnimationOptions.allowUserInteraction,
                       animations: {
                        self.backToMenuButton.transform = CGAffineTransform.identity
        },
                       completion: { Void in()  }
        )
        
        switchDelegate?.SwitchMenuFriendsView(toPage: "menuView")
    }
    
    // Table View Methods -------------------------------------------------------------------------------------------------
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.invitationsArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 100.0;//Choose your custom row height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InvitesTableViewCell") as! InvitesTableViewCell
        
        // To turn off darken on select
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        // Allow button clicks on cells
        cell.contentView.isUserInteractionEnabled = true
        cell.frame.size.height = 100
        cell.inviterUsernameLabel.text = invitationsArray[indexPath.row]
        return cell
    }
}


