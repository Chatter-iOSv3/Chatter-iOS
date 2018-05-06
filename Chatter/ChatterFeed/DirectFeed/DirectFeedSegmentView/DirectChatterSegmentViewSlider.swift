//
//  DirectChatterSegmentViewSlider.swift
//  Chatter
//
//  Created by Austen Ma on 5/5/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import UIKit
import AVFoundation

extension DirectChatterSegmentView {
    func setupDirectSegmentSlider(imageWidth: CGFloat) {
        self.sliderView = UIView(frame: CGRect(x: 2.5, y: -15, width: 2.5, height: 95))
        self.sliderView?.backgroundColor = UIColor.purple
        self.sliderView?.isUserInteractionEnabled = true
        self.sliderView?.alpha = 0.0
        self.imageWidth = CGFloat(imageWidth)
        self.addSubview(self.sliderView!)
    }
    
    func playSlider() {
        UIView.animate(withDuration: Double(self.audioLength),
                       delay: 0.0,
                       options: [.curveLinear],
                       animations: {
                        self.sliderView?.center = CGPoint(x: self.imageWidth, y: (self.sliderView?.center.y)!)
        },
                       completion: { finished in
                        self.resetSlider()
        })
    }
    
    func resetSlider() {
        self.sliderView?.alpha = 0.0
        self.sliderView?.center = CGPoint(x: 7, y: (self.sliderView?.center.y)!)
    }
    
    func toggleSlider() {
        if (self.sliderView?.alpha == 0.0) {
            self.sliderView?.alpha = 1.0
        }   else {
            self.sliderView?.alpha = 0.0
        }
    }
}
