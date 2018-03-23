//
//  SignUp.swift
//  Chatter
//
//  Created by Austen Ma on 2/27/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class SignUp: UIViewController {
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var firstnameField: UITextField!
    @IBOutlet weak var lastnameField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        signUpButton.addTarget(self, action: #selector(handleSignup), for: .touchUpInside)
        
        // Initialize Firebase Reference
        ref = Database.database().reference()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func handleSignup() {
        guard let firstname = firstnameField.text else {return}
        guard let lastname = lastnameField.text else {return}
        guard let username = usernameField.text else {return}
        guard let email = emailField.text else {return}
        guard let password = passwordField.text else {return}
        
        Auth.auth().createUser(withEmail: email, password: password) { user, error in
            if error == nil && user != nil {
                print("User created! \n\(String(describing: user ?? nil))")
                
                // Initialize user object in Firebase with basic data
                self.ref.child("users").child((user?.uid)!).setValue(["username": username, "firstname": firstname, "lastname": lastname])
            }   else {
                print("Error:\(error!.localizedDescription)")
            }
        }
    }
}
