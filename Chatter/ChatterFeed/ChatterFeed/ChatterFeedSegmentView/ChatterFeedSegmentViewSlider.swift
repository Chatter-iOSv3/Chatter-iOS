//
//  ChatterFeedSegmentViewSlider.swift
//  Chatter
//
//  Created by Austen Ma on 5/5/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import UIKit
import AVFoundation

extension ChatterFeedSegmentView {
    func playSlider() {
        UIView.animate(withDuration: self.audioDurationSeconds,
                       delay: 0.0,
                       options: [.curveLinear],
                       animations: {
                        self.sliderView?.center = CGPoint(x: 300, y: (self.sliderView?.center.y)!)
        },
                       completion: { finished in
                        self.resetSlider()
        })
    }
    
    func resetSlider() {
        self.sliderView?.alpha = 0.0
        self.sliderView?.center = CGPoint(x: 7, y: (self.sliderView?.center.y)!)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("SEGMENT DONE PLAYING")
    }
}
