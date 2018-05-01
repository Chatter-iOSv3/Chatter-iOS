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
}
