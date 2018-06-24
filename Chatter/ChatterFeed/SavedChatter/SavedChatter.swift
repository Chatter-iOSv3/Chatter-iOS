//
//  SavedChatterViewController.swift
//  Chatter
//
//  Created by Austen Ma on 5/15/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import XLPagerTabStrip

// TODO: NOT IMPLEMENTED YET

class SavedChatterViewController: UIViewController, IndicatorInfoProvider {
    
    var ref: DatabaseReference!
    let storage = Storage.storage()
    var userID: String?
    var storageRef: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        self.storageRef = storage.reference()
        self.userID = Auth.auth().currentUser?.uid
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Saved")
    }
}
