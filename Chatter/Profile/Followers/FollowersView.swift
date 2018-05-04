//
//  FollowersViewController
//  Chatter
//
//  Created by Austen Ma on 3/11/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class FollowersView: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var backToMenuButton: UIButton!
    @IBOutlet weak var followerTableView: UITableView!
    
    var switchDelegate:SwitchMenuFollowersViewDelegate?
    
    var ref: DatabaseReference!
    let userID = Auth.auth().currentUser?.uid
    let storage = Storage.storage()
    
    var followerLabelArray: [String]!
    var followerIDArray: [String]!
    var followerItemArray: [LandingRecord.friendItem]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        followerTableView.delegate = self
        followerTableView.dataSource = self
        
        SetFollowersObserver()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        RerenderFollowersTableView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goBackToMenu(sender: AnyObject) {
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
        
        switchDelegate?.SwitchMenuFollowersView(toPage: "menuView")
    }
    
    func RerenderFollowersTableView() {
        // TODO: Debug the Followers List with a SET instead of Arrays to prevent duplicates
        
        self.followerLabelArray = []
        self.followerIDArray = []
        
        // Grab the invites array from DB
        self.ref.child("users").child(userID!).child("follower").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            
            if (value != nil) {
                for user in value! {
                    let followerID = user.key as? String
                    
                    // Retrieve username with ID
                    self.ref.child("users").child(followerID!).child("username").observeSingleEvent(of: .value, with: { (snapshot) in
                        let followerUsername = snapshot.value as? String
                        
                        if (!self.followerLabelArray.contains(followerUsername!)) {
                            self.followerLabelArray.append(followerUsername!)
                            self.followerIDArray.append(followerID!)
                            
                            let tempProfileImage = UIImage()
                            let currFollowerItem = LandingRecord.friendItem(userID: followerID!, userName: followerUsername!, profileImage: tempProfileImage)
                            
                            // Send notification with FollowerSet to composeModal
                            NotificationCenter.default.post(name: .sendToComposeModalFriendsList, object: nil, userInfo: ["userData": currFollowerItem])
                        }
                        
                        // Populate the Table View as the invitations are loaded
                        self.followerTableView.reloadData()
                    })  { (error) in
                        print(error.localizedDescription)
                    }
                }
            }   else {
                self.followerTableView.reloadData()
            }
        })  { (error) in
            print(error.localizedDescription)
        }
    }
    
    func checkIfProfileImageLogged(followerID: String) -> UIImage? {
        for followerItem in self.followerItemArray {
            if (followerID == followerItem.userID) {
                return followerItem.profileImage
            }
        }
        return nil
    }
    
    func SetFollowersObserver() {
        self.ref.child("users").child(userID!).child("follower").observe(.childAdded, with: { (snapshot) in
            
            self.RerenderFollowersTableView()
            
            // Send notification to re-render follower tableView
            NotificationCenter.default.post(name: .invitationAcceptedRerender, object: nil)
        })
    }
    
    // Table View Methods --------------------------------------------------------------------------------
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.followerLabelArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 90.0;//Choose your custom row height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FollowersTableViewCell") as! FollowersTableViewCell
        
        // To turn off darken on select
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        // Allow button clicks on cells
        cell.contentView.isUserInteractionEnabled = true
        
        // Styling the Cell
        cell.frame.size.height = 100
        cell.followerUsernameLabel.text = followerLabelArray[indexPath.row]
        let firstnameLetter = String(describing: followerLabelArray[indexPath.row].first!).uppercased()
        
        // Check if we have profile image downloaded already
        if let currProfileImage = self.checkIfProfileImageLogged(followerID: followerIDArray[indexPath.row]) as? UIImage {
            self.setProfileImageAvatarWithImage(image: currProfileImage, newView: cell.followerAvatarView)
        }   else {
            setProfileImageAvatar(userDetails: followerIDArray[indexPath.row], newView: cell.followerAvatarView, followerUsername: followerLabelArray[indexPath.row])
        }
        
        let currCellAvatarView = cell.followerAvatarView
        configureAvatarView(button: currCellAvatarView!)
        return cell
    }
    
    func configureAvatarView(button: UIView) {
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.clipsToBounds = true
    }
    
    func generateRandomColor() -> UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.8 // from 0.5 to 1.0 to stay away from white
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from black
        
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
    
    // Avatar Methods ----------------------------------------------------------
    
    func setProfileImageAvatar(userDetails: String, newView: UIView, followerUsername: String) {
        self.ref.child("users").child(userDetails).observeSingleEvent(of: .value) {
            (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            if let profileImageURL = value?["profileImageURL"] as? String {
                self.setProfileImageAvatarWithURL(imageURL: profileImageURL, newView: newView, followerID: userDetails, followerUsername: followerUsername)
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
            
            var resizedCurrImage = self.resizeImage(image: currImage!, targetSize: CGSize(width: 40, height:  40))
            newView.backgroundColor = UIColor(patternImage: resizedCurrImage)
            
            // Send notification with FollowerSet to composeModal
            let currFollowerItem = LandingRecord.friendItem(userID: followerID, userName: followerUsername, profileImage: currImage!)
            
            NotificationCenter.default.post(name: .sendToComposeModalFriendsList, object: nil, userInfo: ["userData": currFollowerItem])
        })
    }
    
    func setProfileImageAvatarWithImage(image: UIImage, newView: UIView) {
        var resizedCurrImage = self.resizeImage(image: image, targetSize: CGSize(width: 40, height:  40))
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

