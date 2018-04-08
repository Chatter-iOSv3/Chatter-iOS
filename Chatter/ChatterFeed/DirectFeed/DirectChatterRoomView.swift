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
    var chatterRoomSegments: NSDictionary?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let waveView = UIView()
        waveView.frame.size.height = 65
        waveView.frame.size.width = 300
        waveView.backgroundColor = UIColor(red: 119/255, green: 211/255, blue: 239/255, alpha: 1.0)
        waveView.layer.cornerRadius = 20
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // change 2 to desired number of seconds
            if (self.chatterRoomSegments?.count == 0) {
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 65))
                label.textAlignment = .center
                label.font = label.font.withSize(15)
                label.textColor = .white
                label.text = "Press and Hold to send Chatter!"
                waveView.addSubview(label)
            }
        }
        
        self.addSubview(waveView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

