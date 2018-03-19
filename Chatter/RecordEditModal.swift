//
//  RecordEditModal.swift
//  Chatter
//
//  Created by Austen Ma on 3/19/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit

protocol TrashRecordingDelegate
{
    func trashRecording()
}

class RecordEditModal: UIViewController {
    
    @IBOutlet weak var recordEditModalView: UIView!
    
    var trashDelegate:TrashRecordingDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recordEditModalView.layer.cornerRadius = 10
    }
    
    @IBAction func closeRecordEdit(_ sender: Any) {
        trashDelegate?.trashRecording()
        dismiss(animated: true, completion: nil)
    }
}
