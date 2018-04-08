//
//  ChatterLoadingModal.swift
//  Chatter
//
//  Created by Austen Ma on 3/21/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class ChatterLoadingModal: UIViewController {
    @IBOutlet weak var loadingIcon: UIImageView!
    
    // Initialize Firebase vars
    let storage = Storage.storage()
    var ref: DatabaseReference!
    var userID: String?
    var storageRef: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        self.storageRef = storage.reference()
        self.userID = Auth.auth().currentUser?.uid
        
        //Warm up Firebase
        self.firebaseWarmup()
    }
    
    func firebaseWarmup() {
        ref.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
            // Check all values exist
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) { // change 2 to desired number of seconds
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
}
