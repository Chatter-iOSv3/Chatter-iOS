//
//  DirectChatter.swift
//  Chatter
//
//  Created by Austen Ma on 4/3/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import XLPagerTabStrip

class DirectChatter: UIViewController, IndicatorInfoProvider {
    @IBOutlet weak var placeholderCurveView: UIView!
    
    override func viewDidLoad() {
        // Initial styling
        self.placeholderCurveView.layer.cornerRadius = 37.5
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Direct")
    }
}

