//
//  Login.swift
//  Chatter
//
//  Created by Austen Ma on 2/26/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class Login: UIViewController {
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginClicked(sender: UIButton) {
        handleLogin()
    }
    
    @objc func handleLogin() {
        guard let email = emailField.text else {return}
        guard let password = passwordField.text else {return}
        
        Auth.auth().signIn(withEmail: email, password: password, completion: {(user, error) in
            if error == nil && user != nil {
                print("Logging In\(user?.uid)")
                self.performSegue(withIdentifier: "loginToLanding", sender: nil)
            }   else {
                print("Error:\(error!.localizedDescription)")
            }
        });
    }
    
    // Unwinds got Logging Out
    @IBAction func unwindToLogin(segue: UIStoryboardSegue) {}
    
}
