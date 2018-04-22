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

class MenuView: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var profileImageView: UIView!
    
    @IBOutlet weak var followingCountLabel: UILabel!
    @IBOutlet weak var followerCountLabel: UILabel!
    
    @IBOutlet weak var bitmojiButton: UIButton!
    @IBOutlet weak var findFriendsButton: UIButton!
    @IBOutlet weak var followRequestsButton: UIButton!
    @IBOutlet weak var connectDevicesButton: UIButton!
    @IBOutlet weak var followRequestsBadge: UIButton!
    
    
    // Initialize FB storage + DB
    var ref: DatabaseReference!
    let userID = Auth.auth().currentUser?.uid
    let storage = Storage.storage()
    
    var switchMenuFollowersDelegate:SwitchMenuFollowersViewDelegate?
    var switchMenuInvitesDelegate:SwitchMenuInvitesViewDelegate?
    var switchMenuFollowingDelegate:SwitchMenuFollowingViewDelegate?
    
    override func viewDidLoad() {
        ref = Database.database().reference()
        
        // Set user full name, username, avatar button labels, and counts
        self.initializeProfile()
        
        self.configureAvatarButton()
        self.configureProfileImageView()
        self.configureButtons()
        
        
        // Listens for invitation Acceptance
        NotificationCenter.default.addObserver(self, selector: #selector(invitationAccepted(notification:)), name: .invitationAcceptedRerender, object: nil)
        
    }
    
    func initializeProfile() {
        // Set user full name, username, avatar button labels, and counts
        ref.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            
            let firstname = value?["firstname"] as? String ?? ""
            let lastname = value?["lastname"] as? String ?? ""
            
            self.fullNameLabel.text = firstname + " " + lastname
            
            let username = value?["username"] as? String ?? ""
            
            self.usernameLabel.text = "@" + username
            
            let profileImageURL = value?["profileImageURL"] as? String ?? ""
            
            if (value?["profileImageURL"] == nil) {
                // Label Avatar button
                let firstnameLetter = String(describing: firstname.first!)
                self.labelProfileImage(firstnameLetter: firstnameLetter)
            }   else {
                self.renderProfileImageWithURL(imageURL: profileImageURL)
            }
            
            // Set follower/following counts
            let follower = value?["follower"] as? NSDictionary ?? [:]
            let following = value?["following"] as? NSDictionary ?? [:]
            let followRequests = value?["invitations"] as? NSDictionary ?? [:]
            
            self.followerCountLabel.text = String(follower.count)
            self.followingCountLabel.text = String(following.count)
            
            if (followRequests.count > 0) {
                self.followRequestsBadge.setTitle(String(followRequests.count), for: .normal)
                
                UIView.animate(withDuration: 0.5, delay: 0.0, options:.curveLinear, animations: {
                    self.followRequestsBadge.alpha = 1.0
                }, completion:nil)
            }   else if (followRequests.count == 0) {
                self.followRequestsBadge.alpha = 0.0
            }
        })
    }
    
    func labelProfileImage(firstnameLetter: String) {
        // Label Avatar button
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 75, height: 75))
        label.textAlignment = .center
        label.font = label.font.withSize(20)
        label.textColor = .white
        label.text = firstnameLetter
        self.profileImageView.addSubview(label)
    }
    
    
    @objc func invitationAccepted(notification: NSNotification) {
        initializeProfile()
    }
    
    // Actions -----------------------------------------------------------------------
    
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
    
    // View configuration ------------------------------------------------------------------
    
    func configureAvatarButton() {
        profileImageView.layer.cornerRadius = 0.5 * profileImageView.bounds.size.width
        profileImageView.clipsToBounds = true
        profileImageView.backgroundColor = UIColor(red: 179/255, green: 95/255, blue: 232/255, alpha: 1.0)
    }
    
    func configureProfileImageView() {
        // Add gesture handler
        self.profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectProfileImageView)))
        self.profileImageView.isUserInteractionEnabled = true
        
        // Style
        self.profileImageView.layer.borderColor = UIColor(red: 151/255, green: 19/255, blue: 232/255, alpha: 1.0).cgColor
        self.profileImageView.layer.borderWidth = 2
    }
    
    func configureButtons() {
        let followRequestsPath = UIBezierPath(roundedRect:self.followRequestsButton.bounds,
                                byRoundingCorners:[.topRight, .bottomRight],
                                cornerRadii: CGSize(width: 15, height:  15))
        
        let followRequestsMaskLayer = CAShapeLayer()
        
        followRequestsMaskLayer.path = followRequestsPath.cgPath
        self.followRequestsButton.layer.mask = followRequestsMaskLayer
        
        let bitmojiPath = UIBezierPath(roundedRect:self.bitmojiButton.bounds,
                                byRoundingCorners:[.topLeft, .bottomLeft],
                                cornerRadii: CGSize(width: 15, height:  15))
        
        let bitmojiMaskLayer = CAShapeLayer()
        
        bitmojiMaskLayer.path = bitmojiPath.cgPath
        self.bitmojiButton.layer.mask = bitmojiMaskLayer
        
        self.findFriendsButton.layer.cornerRadius = self.findFriendsButton.frame.size.height / 2 - 10
        self.connectDevicesButton.layer.cornerRadius = self.connectDevicesButton.frame.size.height / 2 - 10
        
        self.followRequestsBadge.layer.cornerRadius = self.followRequestsBadge.frame.size.height / 2
        self.followRequestsBadge.alpha = 0.0
    }
    
    // Profile picture Utilities --------------------------------------------------------
    
    @objc func handleSelectProfileImageView() {
        let imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var selectedImageFromPicker: UIImage?
        
        print(info)
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        }   else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            print("Image Selected")
            let resizedSelectedImage = self.resizeImage(image: selectedImage, targetSize: CGSize(width:90, height:90))
            profileImageView.backgroundColor = UIColor(patternImage: resizedSelectedImage)
            self.sendProfileImageToFeeds(image: selectedImage)
            
            self.uploadNewProfileImage(newProfileImage: resizedSelectedImage)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("Canceled")
        dismiss(animated: true, completion: nil)
    }
    
    func uploadNewProfileImage(newProfileImage:UIImage) {
        // Initialize FB storage ref
        let storageRef = storage.reference()
        let userID = Auth.auth().currentUser?.uid
        
        let imageRef = storageRef.child("profileImages/\(userID!)_profileImage.png")
        
        if let uploadData = UIImagePNGRepresentation(newProfileImage) {
            imageRef.putData(uploadData, metadata: nil) { metadata, error in
                if let error = error {
                    print(error)
                } else {
                    print(metadata?.downloadURL()!)
                    // Write profile pic URL to user's FB
                    
                    let childUpdates = ["profileImageURL": metadata?.downloadURL()?.absoluteString]
                    
                    self.ref.child("users").child(userID!).updateChildValues(childUpdates) {error, ref in
                        print("Uploaded Image!")
                    }
                }
            }
        }
    }
    
    func renderProfileImageWithURL(imageURL: String) {
        let profileImageDownloadRef = storage.reference(forURL: imageURL)
        
        profileImageDownloadRef.downloadURL(completion: { (url, error) in
            var data = Data()
            
            do {
                data = try Data(contentsOf: url!)
            } catch {
                print(error)
            }
            let image = UIImage(data: data as Data)
            
            let resizedSelectedImage = self.resizeImage(image: image!, targetSize: CGSize(width:90, height:90))
            
            self.profileImageView.backgroundColor = UIColor(patternImage: resizedSelectedImage)
            
            // Send loaded profile image to Feed page
            self.sendProfileImageToFeeds(image: image!)
        })
    }
    
    func sendProfileImageToFeeds(image: UIImage) {
        if (image != nil) {
            let resizedForFeedImage = self.resizeImage(image: image, targetSize: CGSize(width: 40, height:  40))
            NotificationCenter.default.post(name: .profileImageChanged, object: nil, userInfo: ["image": resizedForFeedImage])
        }
    }
    
    // Utilities ---------------------------------------------------------------------
    
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

