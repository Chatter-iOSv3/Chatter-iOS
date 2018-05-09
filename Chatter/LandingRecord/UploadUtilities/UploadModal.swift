//
//  UploadModal.swift
//  Chatter
//
//  Created by Austen Ma on 5/8/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class UploadModalViewController: UIViewController {
    @IBOutlet weak var uploadFromVideosButton: UIButton!
    @IBOutlet weak var uploadModalView: UIView!
    
    override func viewDidLoad() {
        self.uploadModalView.layer.cornerRadius = 20
    }
    
    @IBAction func closeUpload(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func uploadFromVideos(_ sender: Any) {
        print("LALALA")
    }
}
