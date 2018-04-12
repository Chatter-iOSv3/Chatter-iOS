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
    
    // Friends list
    var friendsList: [LandingRecord.friendItem]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        self.audioID = randomString(length: 10)
        
        friendsTableView.delegate = self
        friendsTableView.dataSource = self
        
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
    
    func saveRecording() {
        // Initialize FB storage ref
        let storageRef = storage.reference()
        let userID = Auth.auth().currentUser?.uid
        
        // Get audio url and generate a unique ID for the audio file
        let audioUrl = self.recordedUrl!
        let fullAudioID = "\(userID ?? "") | \(self.audioID)"
        
        // Saving the recording to FB
        let audioRef = storageRef.child("audio/\(fullAudioID)")
        
        audioRef.putFile(from: audioUrl, metadata: nil) { metadata, error in
            if let error = error {
                print(error)
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                //                    let downloadURL = metadata!.downloadURL()
                
                // Write to the ChatterFeed string in FB-DB
                self.ref.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
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
                    chatterFeedSegment = ["id": fullAudioID, "userDetails": userID!, "dateCreated": self.getCurrentDate()]
                    
                    let childUpdates = ["\(countIdentifier)": chatterFeedSegment]
                    
                    // Get the list of followers
                    let follower = value!["follower"] as? NSDictionary
                    
                    // Update your Chatter feed, then feed in all follower
                    self.ref.child("users").child(userID!).child("chatterFeed").updateChildValues(childUpdates) {error, ref in
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
                                    followerChatterFeedSegment = ["id": fullAudioID, "userDetails": userID!, "dateCreated": self.getCurrentDate()]
                                    
                                    let followerChildUpdates = ["\(followerCountIdentifier)": followerChatterFeedSegment]
                                    
                                    self.ref.child("users").child(followerID!).child("chatterFeed").updateChildValues(followerChildUpdates) {error, ref in
                                        print("UPDATE PROCESS COMPLETE: \(followerID)")
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
        
        // Styling the Cell
        cell.frame.size.height = 70
        cell.friendUsernameLabel.text = friendsList[indexPath.row].userName
        let firstnameLetter = String(describing: friendsList[indexPath.row].userName.first!).uppercased()
        cell.friendAvatarButton.setTitle(firstnameLetter, for: .normal)
        let randomColor = generateRandomColor()
        let currCellButton = cell.friendAvatarButton
        configureAvatarButton(button: currCellButton!, color: randomColor)
        return cell
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
