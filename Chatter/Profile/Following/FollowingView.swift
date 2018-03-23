//
//  FollowingViewController
//  Chatter
//
//  Created by Austen Ma on 3/11/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class FollowingView: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var backToMenuButton: UIButton!
    @IBOutlet weak var addFollowingButton: UIButton!
    @IBOutlet weak var followingTableView: UITableView!
    
    var switchDelegate:SwitchMenuFollowingViewDelegate?
    
    var ref: DatabaseReference!
    let userID = Auth.auth().currentUser?.uid
    
    var followingLabelArray: [String]!
    var followingIDArray: [String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        followingTableView.delegate = self
        followingTableView.dataSource = self
        
        RerenderFollowingTableView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goBackToMenu(sender: AnyObject) {
        backToMenuButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        // Obsererver for accepted follow requests
        self.ref.child("users").child(userID!).child("chatterFeed").observe(.childAdded, with: { (snapshot) -> Void in
            self.RerenderFollowingTableView()
        })
        
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
        
        switchDelegate?.SwitchMenuFollowingView(toPage: "menuView")
    }
    
    func RerenderFollowingTableView() {
        self.followingLabelArray = []
        self.followingIDArray = []
        
        // Grab the invites array from DB
        self.ref.child("users").child(userID!).child("following").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            
            if (value != nil) {
                for user in value! {
                    print("following: \(user)")
                    let followingID = user.key as? String
                    
                    // Retrieve username with ID
                    self.ref.child("users").child(followingID!).child("username").observeSingleEvent(of: .value, with: { (snapshot) in
                        let followingUsername = snapshot.value as? String
                        
                        self.followingLabelArray.append(followingUsername!)
                        self.followingIDArray.append(followingID!)
                        
                        // Populate the Table View as the invitations are loaded
                        self.followingTableView.reloadData()
                    })  { (error) in
                        print(error.localizedDescription)
                    }
                }
            }   else {
                self.followingTableView.reloadData()
            }
        })  { (error) in
            print(error.localizedDescription)
        }
    }
    
    @objc func invitationAccepted(notification: NSNotification) {
        RerenderFollowingTableView()
    }
    
    // Table View Methods --------------------------------------------------------------------------------
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.followingLabelArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 90.0;//Choose your custom row height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FollowingTableViewCell") as! FollowingTableViewCell
        
        // To turn off darken on select
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        // Allow button clicks on cells
        cell.contentView.isUserInteractionEnabled = true
        
        // Styling the Cell
        cell.frame.size.height = 100
        cell.followingUsernameLabel.text = followingLabelArray[indexPath.row]
        let firstnameLetter = String(describing: followingLabelArray[indexPath.row].first!).uppercased()
        cell.followingAvatarButton.setTitle(firstnameLetter, for: .normal)
        let randomColor = generateRandomColor()
        let currCellButton = cell.followingAvatarButton
        configureAvatarButton(button: currCellButton!, color: randomColor)
        return cell
    }
    
    func configureAvatarButton(button: UIButton, color: UIColor) {
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.clipsToBounds = true
        button.backgroundColor = color
    }
    
    func generateRandomColor() -> UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.8 // from 0.5 to 1.0 to stay away from white
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from black
        
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
    
}
