//
//  FollowingTableViewCell.swift
//  Chatter
//
//  Created by Austen Ma on 3/13/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class FollowingTableViewCell: UITableViewCell {
    @IBOutlet weak var followingAvatarButton: UIButton!
    @IBOutlet weak var followingUsernameLabel: UILabel!
    
    var ref = Database.database().reference()
    let userID = Auth.auth().currentUser?.uid
}

