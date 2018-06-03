//
//  FriendsTableViewCell.swift
//  Chatter
//
//  Created by Austen Ma on 4/11/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class FriendsTableViewCell: UITableViewCell {
    @IBOutlet weak var friendAvatarView: UIView!
    @IBOutlet weak var friendUsernameLabel: UILabel!
    @IBOutlet weak var chooseFriendButton: UIButton!
    
    var friendID: String!
    var ChooseAudienceVC: ChooseAudienceModal!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Style Avatar
        self.configureAvatarView(view: friendAvatarView)
        
        // Style Radio Button
        self.chooseFriendButton.layer.cornerRadius = self.chooseFriendButton.frame.size.height / 2
        self.chooseFriendButton.layer.borderWidth = 1.0
        self.chooseFriendButton.layer.borderColor = UIColor(red: 151/255, green: 19/255, blue: 232/255, alpha: 1.0).cgColor
        self.chooseFriendButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    }
    
    @IBAction func friendChosen(_ sender: Any) {
        if (!self.ChooseAudienceVC.selectedFriendsList.contains(self.friendID)) {
            UIView.animate(withDuration: 0.2, delay: 0.0, options:.curveLinear, animations: {
                self.chooseFriendButton.backgroundColor = UIColor(red: 151/255, green: 19/255, blue: 232/255, alpha: 1.0)
            }, completion:nil)
            
            self.ChooseAudienceVC.addSelectedFriend(friendID: self.friendID)
        }   else if (self.ChooseAudienceVC.selectedFriendsList.contains(self.friendID)) {
            UIView.animate(withDuration: 0.2, delay: 0.0, options:.curveLinear, animations: {
                self.chooseFriendButton.backgroundColor = .white
            }, completion:nil)
            
            self.ChooseAudienceVC.removeSelectedFriend(friendID: self.friendID)
        }
    }
    
    func configureAvatarView(view: UIView) {
        view.layer.cornerRadius = 0.5 * view.bounds.size.width
        view.clipsToBounds = true
    }
    
    func generateRandomColor() -> UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.8 // from 0.5 to 1.0 to stay away from white
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from black
        
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
}
