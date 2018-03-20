//
//  ViewController.swift
//  Chatter
//
//  Created by Austen Ma on 2/24/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

class Landing: UIViewController {
    @IBOutlet weak var recordView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    }
    
    @IBAction func hearChatter(sender: UIButton) {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        // Notify ChatterFeed to start Chatter queue
        NotificationCenter.default.post(name: .queueNextChatter, object: nil)
    }
    
    @IBAction func animateButton(sender: UIButton) {
        
        sender.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 1.25,
                       delay: 0,
                       usingSpringWithDamping: CGFloat(0.40),
                       initialSpringVelocity: CGFloat(6.0),
                       options: UIViewAnimationOptions.allowUserInteraction,
                       animations: {
                        sender.transform = CGAffineTransform.identity
        },
                       completion: { Void in()  }
        )
    }
    
}

extension Notification.Name {
    static let queueNextChatter = Notification.Name("queueNextChatter")
    static let chatterFinishedAndQueue = Notification.Name("chatterFinishedAndQueue")
    static let chatterChangedAndQueue = Notification.Name("chatterChangedAndQueue")
    
    // When invitation is accepted, updates Followers list
    static let invitationAcceptedRerenderFollowers = Notification.Name("invitationAcceptedRerenderFollowers")
}

