//
//  ChooseAudienceModal.swift
//  Chatter
//
//  Created by Austen Ma on 4/8/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import AVFoundation

class ChooseAudienceModal: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var chooseAudienceModal: UIView!
    @IBOutlet weak var chatterFeedButton: UIView!
    @IBOutlet weak var friendsTableView: UITableView!
    @IBOutlet weak var initiateChatterTextField: UITextField!
    @IBOutlet weak var uploadButton: UIButton!
    
    var trashDelegate:TrashRecordingDelegate?
    
    var recordedUrl: URL?
    var audioID: String?
    
    // Initialize Firebase vars
    let storage = Storage.storage()
    var ref: DatabaseReference!
    var userID: String = (Auth.auth().currentUser?.uid)!
    
    // Friends list
    var friendsList: [LandingRecord.friendItem]!
    var selectedFriendsList: [String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        self.audioID = randomString(length: 10)
        
        friendsTableView.delegate = self
        friendsTableView.dataSource = self
        
        self.selectedFriendsList = []
        
        // Configure views
        self.configureViews()
    }
    
    func configureViews() {
        self.chooseAudienceModal.layer.cornerRadius = 20
        self.chatterFeedButton.layer.cornerRadius = 30
    }
    
    @IBAction func backToRecordEdit(sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func uploadToChatterFeed() {
        self.saveRecording()
    }
    
    
    @IBAction func sendToDirectChatter(_ sender: Any) {
        if (self.selectedFriendsList.count != 0) {
            self.startDirectChatter(selectedFriendsList: self.selectedFriendsList)
        }
    }
    
    func saveRecording() {
        // Initialize FB storage ref
        let storageRef = storage.reference()
        
        // Get audio url and generate a unique ID for the audio file
        let audioUrl = self.recordedUrl!
        let fullAudioID = "\(self.userID) | \(self.audioID!)"
        
        // Saving the recording to FB
        let audioRef = storageRef.child("audio/\(fullAudioID)")
        
        audioRef.putFile(from: audioUrl, metadata: nil) { metadata, error in
            if let error = error {
                print(error)
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                //                    let downloadURL = metadata!.downloadURL()
                
                // Write to the ChatterFeed string in FB-DB
                self.ref.child("users").child(self.userID).observeSingleEvent(of: .value, with: { (snapshot) in
                    // Retrieve existing ChatterFeed
                    let value = snapshot.value as? NSDictionary
                    let currChatterFeedCount = (value!["chatterFeed"] as AnyObject).count
                    
                    // Generating chatterFeed # identifier
                    var countIdentifier: Int
                    if ((currChatterFeedCount) != nil) {
                        countIdentifier = currChatterFeedCount!
                    }   else {
                        countIdentifier = 0
                    }
                    
                    // Construct new ChatterFeed segment
                    var chatterFeedSegment = Dictionary<String, Any>()
                    chatterFeedSegment = ["id": fullAudioID, "userDetails": self.userID, "dateCreated": self.getCurrentDate()]
                    
                    let childUpdates = ["\(countIdentifier)": chatterFeedSegment]
                    
                    // Get the list of followers
                    let follower = value!["follower"] as? NSDictionary
                    
                    // Update your Chatter feed, then feed in all follower
                    self.ref.child("users").child(self.userID).child("chatterFeed").updateChildValues(childUpdates) {error, ref in
                        if (follower != nil) {
                            // Iterate through each follower and update their feed
                            for follower in follower! {
                                let followerID = follower.key as? String
                                self.ref.child("users").child(followerID!).child("chatterFeed").observeSingleEvent(of: .value, with: { (followerSnapshot) in
                                    let followerValue = followerSnapshot.value as? Any
                                    let followerChatterFeedCount = (followerValue! as AnyObject).count
                                    
                                    // Generating follower chatterFeed # identifier
                                    var followerCountIdentifier: Int
                                    if ((followerChatterFeedCount) != nil) {
                                        followerCountIdentifier = followerChatterFeedCount!
                                    }   else {
                                        followerCountIdentifier = 0
                                    }
                                    
                                    // Construct follower ChatterFeed segment
                                    var followerChatterFeedSegment = Dictionary<String, Any>()
                                    followerChatterFeedSegment = ["id": fullAudioID, "userDetails": self.userID, "dateCreated": self.getCurrentDate()]
                                    
                                    let followerChildUpdates = ["\(followerCountIdentifier)": followerChatterFeedSegment]
                                    
                                    self.ref.child("users").child(followerID!).child("chatterFeed").updateChildValues(followerChildUpdates) {error, ref in
                                        print("UPDATE PROCESS COMPLETE: \(String(describing: followerID))")
                                    }
                                })
                            }
                        }
                        
                        // Exit the modal
                        print("LOCAL SAVE SUCCESS")
                        self.dismiss(animated: true, completion: nil)
                    }
                }) { (error) in
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func startDirectChatter(selectedFriendsList: [String]) {
        // Generate a new chatterRoomID
        let newChatterRoomID = self.randomString(length: 20)
        let newChatterRoomUsers = self.selectedFriendsList.joined(separator: ",") + ", \(self.userID)"
        
        // Initialize FB storage ref
        let storageRef = storage.reference()
        
        // Get audio url and generate a unique ID for the audio file
        let audioUrl = self.recordedUrl!
        let fullAudioID = "\(self.userID ) | \(self.audioID!)"
        
        // Saving the recording to FB
        let audioRef = storageRef.child("audio/\(fullAudioID)")
        
        audioRef.putFile(from: audioUrl, metadata: nil) { metadata, error in
            if let error = error {
                print(error)
            } else {
                self.ref.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
                    let value = snapshot.value as? NSDictionary
                    
                    // Initiate ChatterRoom with all associated friends
                    for friendID in selectedFriendsList {
                        // Iterate through users to find matching user data with username
                        for user in value! {
                            let currUserDetails = user.value as? NSDictionary
                            let currUserID = user.key as? String
                            
                            if (currUserID == friendID && self.userID != currUserID) {
                                print("FOUND USER: \(user)")
                                
                                // Go into users' DB and add the chatterRoomID
                                let startDirectChatterWithUserID = user.key as? String
                                
                                // Store the new Chatter room in designated user's and the requesting user's DB
                                let chatterRoomDataTo: [String: [String: String]] = [newChatterRoomID: ["users": newChatterRoomUsers]]
                                self.ref.child("users").child(startDirectChatterWithUserID!).child("chatterRooms").updateChildValues(chatterRoomDataTo)
                            }
                        }
                    }
                    
                    // Add ChatterRoom data to own DB
                    let chatterRoomDataFrom: [String: [String: String]] = [newChatterRoomID: ["users": newChatterRoomUsers]]
                    self.ref.child("users").child(self.userID).child("chatterRooms").updateChildValues(chatterRoomDataFrom) { (error, ref) -> Void in
                        // Close modal and redirect to Direct Messages page
                        self.dismiss(animated: true, completion: nil)
                    }
                    
                    let fullAudioID = "\(self.userID) | \(self.audioID!)"
                    
                    // Add ChatterRoomID to overall DB
                    let timestamp = String(Int(NSDate().timeIntervalSince1970))
                    
                    let asset = AVURLAsset(url: audioUrl)
                    let audioDuration = asset.duration
                    let audioDurationSeconds = Float(CMTimeGetSeconds(audioDuration))
                    
                    let chatterRoomData: [String: [String: [String: [String: String]]]] = [newChatterRoomID: ["chatterRoomSegments": [timestamp: ["fullAudioID": fullAudioID, "duration": String(audioDurationSeconds), "readStatus": "unread"]]]]
                    self.ref.child("chatterRooms").updateChildValues(chatterRoomData) { (error, ref) -> Void in
                        // Close modal and redirect to Direct Messages page
                        self.dismiss(animated: true, completion: nil)
                    }
                })
            }
        }
    }
    
    func addSelectedFriend(friendID: String) {
        self.selectedFriendsList.append(friendID)
        print(self.selectedFriendsList)
    }
    
    func removeSelectedFriend(friendID: String) {
        self.selectedFriendsList = self.selectedFriendsList.filter{$0 != friendID}
        print(self.selectedFriendsList)
    }
    
    // Table View Methods --------------------------------------------------------------------------------
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.friendsList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        //Choose your custom row height
        return 70.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendsTableViewCell") as! FriendsTableViewCell
        
        // To turn off darken on select
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        // Allow button clicks on cells
        cell.contentView.isUserInteractionEnabled = true
        
        // Preparing the Cell
        cell.frame.size.height = 70
        cell.friendUsernameLabel.text = friendsList[indexPath.row].userName
        let firstnameLetter = String(describing: friendsList[indexPath.row].userName.first!).uppercased()
        
        // Check if we have profile image downloaded already
        if let currProfileImage = self.checkIfProfileImageLogged(friendID: friendsList[indexPath.row].userID) {
            self.setProfileImageAvatarWithImage(image: currProfileImage, newView: cell.friendAvatarView)
        }   else {
            setProfileImageAvatar(userDetails: friendsList[indexPath.row].userID, newView: cell.friendAvatarView, friendUsername: friendsList[indexPath.row].userName)
        }
        
        cell.friendID = friendsList[indexPath.row].userID
        
        cell.ChooseAudienceVC = self
        return cell
    }
    
    // Avatar Methods ----------------------------------------------------------
    
    func checkIfProfileImageLogged(friendID: String) -> UIImage? {
        for friendItem in self.friendsList {
            if (friendID == friendItem.userID) {
                return friendItem.profileImage
            }
        }
        return nil
    }
    
    func setProfileImageAvatar(userDetails: String, newView: UIView, friendUsername: String) {
        self.ref.child("users").child(userDetails).observeSingleEvent(of: .value) {
            (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            if let profileImageURL = value?["profileImageURL"] as? String {
                self.setProfileImageAvatarWithURL(imageURL: profileImageURL, newView: newView, friendID: userDetails, friendUsername: friendUsername)
            }   else {
                // Doesnt have associated profile image
            }
        }
    }
    
    func setProfileImageAvatarWithURL(imageURL: String, newView: UIView, friendID: String, friendUsername: String) {
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
            
            let currFriendItem = LandingRecord.friendItem(userID: friendID, userName: friendUsername, profileImage: resizedCurrImage)
            self.friendsList.append(currFriendItem)
            
             // Send notification with FriendItem to composeModal
            NotificationCenter.default.post(name: .sendToComposeModalFriendsList, object: nil, userInfo: ["userData": currFriendItem])
        })
    }
    
    func setProfileImageAvatarWithImage(image: UIImage, newView: UIView) {
        let resizedImage = self.resizeImage(image: image, targetSize: CGSize(width: 40, height:  40))
        newView.backgroundColor = UIColor(patternImage: resizedImage)
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
    
    // Utilities ----------------------------------------------
    
    func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
    func getCurrentDate() -> String {
        let date = Date()
        let formatter = DateFormatter()
        
        formatter.dateFormat = "dd.MM.yyyy"
        
        let result = formatter.string(from: date)
        
        return result
    }
}
