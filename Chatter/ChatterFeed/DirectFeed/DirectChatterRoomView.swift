//
//  DirectChatterRoomView.swift
//  Chatter
//
//  Created by Austen Ma on 4/6/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import UIKit
import Foundation
import Firebase

class DirectChatterRoomView: UIView{
    var shouldSetupConstraints = true
    var waveView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let waveView = UIView()
        waveView.frame.size.height = 75
        waveView.frame.size.width = 300
        waveView.backgroundColor = UIColor(red: 119/255, green: 211/255, blue: 239/255, alpha: 1.0)
        waveView.layer.cornerRadius = 25
        self.addSubview(waveView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

