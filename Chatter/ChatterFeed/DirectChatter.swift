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
    
    override func viewDidLoad() {
        
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Direct")
    }
}

