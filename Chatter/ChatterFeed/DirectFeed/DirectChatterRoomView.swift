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
    var recordingURLArr: NSArray!
    var chatterRoomView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
//        initializeChatterRoomScrollView()
    }
    
    func initializeChatterRoomScrollView() {
        let imageWidth:CGFloat = 100
        var imageHeight:CGFloat = 60
        var xPosition:CGFloat = 0
        var scrollViewContentSize:CGFloat=0;
        
        let chatterRoomView = UIView()
        chatterRoomView.frame.size.height = 65
        chatterRoomView.frame.size.width = 300
        chatterRoomView.backgroundColor = UIColor(red: 119/255, green: 211/255, blue: 239/255, alpha: 1.0)
        chatterRoomView.layer.cornerRadius = 20
        
        let chatterRoomScrollView = UIScrollView()
        chatterRoomScrollView.frame.size.height = 65
        chatterRoomScrollView.frame.size.width = 300
        chatterRoomScrollView.backgroundColor = .clear
        
        for chatterRoomSegment in self.recordingURLArr {
            let chatterRoomSegment = chatterRoomSegment as! String
            
            var chatterRoomSegmentView = DirectChatterSegmentView()
            chatterRoomSegmentView.frame.size.height = 65
            chatterRoomSegmentView.frame.size.width = 98
            chatterRoomSegmentView.backgroundColor = .clear
            
            chatterRoomSegmentView.frame.origin.x = xPosition + 2
            
            chatterRoomScrollView.addSubview(chatterRoomSegmentView)
            xPosition+=imageWidth
            scrollViewContentSize+=imageWidth
            
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let localURL = documentsURL.appendingPathComponent("\(chatterRoomSegment.suffix(10)).m4a")
            chatterRoomSegmentView.generateAudioFile(audioURL: localURL, id: chatterRoomSegment)
            
            // Calculates running total of how long the scrollView needs to be with the variables
            chatterRoomScrollView.contentSize = CGSize(width: scrollViewContentSize, height: imageHeight)
        }
        
        //        waveView.addSubview(waveScrollView)
        
        self.addSubview(chatterRoomView)
        self.addSubview(chatterRoomScrollView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

