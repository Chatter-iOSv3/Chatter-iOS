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
    @IBOutlet weak var syncContactsButton: UIButton!
    @IBOutlet weak var followRequestsButton: UIButton!
    @IBOutlet weak var connectDevicesButton: UIButton!
    
    
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
        self.configureProfileView()
        self.configureProfileImageView()
        self.configureButtons()
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
            let followers = value?["followers"] as? NSDictionary ?? [:]
            let following = value?["following"] as? NSDictionary ?? [:]
            
            self.followerCountLabel.text = String(followers.count)
            self.followingCountLabel.text = String(following.count)
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
    
    func configureProfileView() {
        let path = UIBezierPath(roundedRect:self.profileView.bounds,
                                byRoundingCorners:[.topRight, .topLeft],
                                cornerRadii: CGSize(width: 20, height:  20))
        
        let maskLayer = CAShapeLayer()
        
        maskLayer.path = path.cgPath
        self.profileView.layer.mask = maskLayer
    }
    
    func configureProfileImageView() {
        // Add gesture handler
        self.profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectProfileImageView)))
        self.profileImageView.isUserInteractionEnabled = true
    }
    
    func configureButtons() {
        self.bitmojiButton.layer.cornerRadius = self.bitmojiButton.frame.size.height / 2 - 10
        self.syncContactsButton.layer.cornerRadius = self.syncContactsButton.frame.size.height / 2 - 10
        self.followRequestsButton.layer.cornerRadius = self.followRequestsButton.frame.size.height / 2 - 10
        self.connectDevicesButton.layer.cornerRadius = self.connectDevicesButton.frame.size.height / 2 - 10
    }
    
    // Profile picture Utilities --------------------------------------------------------
    
    @objc func handleSelectProfileImageView() {
        print("Clicked")
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
            let resizedSelectedImage = self.resizeImage(image: selectedImage, targetSize: CGSize(width:85.0, height:85.0))
            profileImageView.backgroundColor = UIColor(patternImage: resizedSelectedImage)
            
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
            
            self.profileImageView.backgroundColor = UIColor(patternImage: image!)
        })
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
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

