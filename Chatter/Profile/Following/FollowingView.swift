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
    let storage = Storage.storage()
    
    var followingLabelArray: [String]!
    var followingIDArray: [String]!
    var followingItemArray: [LandingRecord.friendItem]!
    
    var rerendered: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        followingTableView.delegate = self
        followingTableView.dataSource = self
        
        RerenderFollowingTableView()
        SetFollowingObserver()  
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
         // TODO: Debug the Followings List with a SET instead of Arrays to prevent duplicates
        
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
                        
                        if (!self.followingLabelArray.contains(followingUsername!)) {
                            self.followingLabelArray.append(followingUsername!)
                            self.followingIDArray.append(followingID!)
                            
                            let tempProfileImage = UIImage()
                            let currFollowingItem = LandingRecord.friendItem(userID: followingID!, userName: followingUsername!, profileImage: tempProfileImage)
                            
                            // Send notification with FollowingSet to composeModal
                            NotificationCenter.default.post(name: .sendToComposeModalFriendsList, object: nil, userInfo: ["userData": currFollowingItem])
                        }
                        
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
    
    func checkIfProfileImageLogged(followingID: String) -> UIImage? {
        for followingItem in self.followingItemArray {
            if (followingID == followingItem.userID) {
                return followingItem.profileImage
            }
        }
        return nil
    }
    
    func SetFollowingObserver() {
        self.ref.child("users").child(userID!).child("following").observe(.childAdded, with: { (snapshot) in
            print("FOLLOWING ADDED")
            
            self.RerenderFollowingTableView()
            
            // Send notification to re-render following tableView
            NotificationCenter.default.post(name: .invitationAcceptedRerender, object: nil)
        })
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
        
        // Check if we have profile image downloaded already
        if let currProfileImage = self.checkIfProfileImageLogged(followingID: followingIDArray[indexPath.row]) as? UIImage {
            self.setProfileImageAvatarWithImage(image: currProfileImage, newView: cell.followingAvatarView)
        }   else {
            setProfileImageAvatar(userDetails: followingIDArray[indexPath.row], newView: cell.followingAvatarView, followingUsername: followingLabelArray[indexPath.row])
        }
        
        let currCellAvatarView = cell.followingAvatarView
        configureAvatarView(button: currCellAvatarView!)
        return cell
    }
    
    func configureAvatarView(button: UIView) {
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.clipsToBounds = true
    }
    
    // Avatar Methods ----------------------------------------------------------
    
    func setProfileImageAvatar(userDetails: String, newView: UIView, followingUsername: String) {
        self.ref.child("users").child(userDetails).observeSingleEvent(of: .value) {
            (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            if let profileImageURL = value?["profileImageURL"] as? String {
                self.setProfileImageAvatarWithURL(imageURL: profileImageURL, newView: newView, followerID: userDetails, followerUsername: followingUsername)
            }
        }
    }
    
    func setProfileImageAvatarWithURL(imageURL: String, newView: UIView, followerID: String, followerUsername: String) {
        let profileImageDownloadRef = storage.reference(forURL: imageURL)
        var currImage: UIImage?
        
        profileImageDownloadRef.downloadURL(completion: { (url, error) in
            var data = Data()
            
            do {
                data = try Data(contentsOf: url!)
            } catch {
                print(error)
            }
            currImage = UIImage(data: data as Data)
            
            let resizedCurrImage = self.resizeImage(image: currImage!, targetSize: CGSize(width: 40, height:  40))
            newView.backgroundColor = UIColor(patternImage: resizedCurrImage)
            
            // Send notification with FollowerSet to composeModal
            let currFollowerItem = LandingRecord.friendItem(userID: followerID, userName: followerUsername, profileImage: currImage!)
            
            NotificationCenter.default.post(name: .sendToComposeModalFriendsList, object: nil, userInfo: ["userData": currFollowerItem])
        })
    }
    
    func setProfileImageAvatarWithImage(image: UIImage, newView: UIView) {
        let resizedCurrImage = self.resizeImage(image: image, targetSize: CGSize(width: 40, height:  40))
        newView.backgroundColor = UIColor(patternImage: resizedCurrImage)
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.scale)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
}
