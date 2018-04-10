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
        
        self.configureTextFields()
        self.configureButtons()
        self.setupTap()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupTap() {
        let touchDown = UILongPressGestureRecognizer(target:self, action: #selector(didTouchDownLogin))
        touchDown.minimumPressDuration = 0
        self.loginButton.addGestureRecognizer(touchDown)
    }
    
    @objc func didTouchDownLogin(gesture: UILongPressGestureRecognizer) {
        if (gesture.state == .began){
            self.loginButton.backgroundColor = UIColor(red: 139/255, green: 240/255, blue: 249/255, alpha: 1.0)
            
            handleLogin()
        }
    }
    
    @objc func handleLogin() {
        guard let email = emailField.text else {return}
        guard let password = passwordField.text else {return}
        
        Auth.auth().signIn(withEmail: email, password: password, completion: {(user, error) in
            if error == nil && user != nil {
                self.performSegue(withIdentifier: "loginToLanding", sender: nil)
            }   else {
                UIView.animate(withDuration: 0.5, delay: 0.0, options:.curveLinear, animations: {
                    self.loginButton.backgroundColor = UIColor(red: 0/255, green: 212/255, blue: 255/255, alpha: 1.0)
                }, completion:nil)
                print("Error:\(error!.localizedDescription)")
            }
        });
    }
    
    // Unwinds got Logging Out
    @IBAction func unwindToLogin(segue: UIStoryboardSegue) {}
    
    
// View methods -----------------------------------------------------------------------
    
    func configureTextFields() {
        let passwordBottomLine = CALayer()
        passwordBottomLine.frame = CGRect(x: 0.0, y: self.passwordField.frame.height - 1, width: self.passwordField.frame.width, height: 0.5)
        passwordBottomLine.backgroundColor = UIColor.lightGray.cgColor
        self.passwordField.borderStyle = UITextBorderStyle.none
        self.passwordField.layer.addSublayer(passwordBottomLine)
        
        let emailBottomLine = CALayer()
        emailBottomLine.frame = CGRect(x: 0.0, y: self.emailField.frame.height - 1, width: self.emailField.frame.width, height: 0.5)
        emailBottomLine.backgroundColor = UIColor.lightGray.cgColor
        self.emailField.borderStyle = UITextBorderStyle.none
        self.emailField.layer.addSublayer(emailBottomLine)
    }
    
    func configureButtons() {
        self.loginButton.layer.cornerRadius = self.loginButton.frame.size.height / 2
    }
}
