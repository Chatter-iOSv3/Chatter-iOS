//
//  ComposeModal.swift
//  Chatter
//
//  Created by Austen Ma on 4/6/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class ComposeModal: UIViewController {
    @IBOutlet weak var xComposeModalButton: UIButton!
    @IBOutlet weak var composeModalView: UIView!
    @IBOutlet weak var startDirectChatterTextField: UITextField!
    @IBOutlet weak var startDirectChatterButton: UIButton!
    
    var ref: DatabaseReference!
    let userID = Auth.auth().currentUser?.uid
    
    override func viewDidLoad() {
        
        // Initialize Firebase
        ref = Database.database().reference()
        
        self.configureViews()
    }
    
    // Actions ---------------------------------------------------------------
    
    @IBAction func closeComposeModal(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func startDirectChatter(_ sender: Any) {
        // Filter through users to find if user in textfield exists
        print("INITIATE DIRECT CHATTER")
        guard let directChatterUsername = startDirectChatterTextField.text else {return}
        
        self.ref.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            
            // Iterate through users to find matching user data with username
            for user in value! {
                let currUserDetails = user.value as? NSDictionary
                let currUserID = user.key as? String
                
                if (String(describing: currUserDetails!["username"]!) == directChatterUsername && self.userID != currUserID) {
                    print("FOUND USER: \(user)")
                    
                    // Generate a new chatterRoomID
                    let newChatterRoomID = self.randomString(length: 20)
                    
                    // Go into both users' DB and add the chatterRoomID
                    
                    let startDirectChatterWithUserID = user.key as? String
                    
                    // Store the new Chatter room in designated user's and the requesting user's DB
                    let chatterRoomDataTo: [String: [String: String]] = [newChatterRoomID: ["chatterRoomSegments": "", "users": self.userID!]]
                    self.ref.child("users").child(startDirectChatterWithUserID!).child("chatterRooms").updateChildValues(chatterRoomDataTo) { (error, ref) -> Void in
                        
                        let chatterRoomDataFrom: [String: [String: String]] = [newChatterRoomID: ["chatterRoomSegments": "", "users": startDirectChatterWithUserID!]]
                        self.ref.child("users").child(self.userID!).child("chatterRooms").updateChildValues(chatterRoomDataFrom) { (error, ref) -> Void in
                            // Close modal and redirect to Direct Messages page
                            self.dismiss(animated: true, completion: nil)
                            NotificationCenter.default.post(name: .startDirectChatter, object: nil)
                        }
                    }
                }
            }
        })
    }
    
    // View Methods ---------------------------------------------------------
    
    func configureViews() {
        composeModalView.layer.cornerRadius = 10
        
        startDirectChatterButton.layer.cornerRadius = 15
    }
    
    // Utilities -----------------------------------------------------------
    
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
}
