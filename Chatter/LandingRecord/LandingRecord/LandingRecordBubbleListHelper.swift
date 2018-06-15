//
//  LandingRecordBubbleListHelper.swift
//  Chatter
//
//  Created by Austen Ma on 6/12/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit

extension LandingRecord {
    // Bubble list view methods
    
    func initializeBubbleList() {
        self.bubbleListButton?.setTitle(String(self.landingFeedViewArray.count), for: .normal)
        self.bubbleListButton?.layer.cornerRadius = (bubbleListButton?.frame.size.height)! / 2
        
        self.bubbleListPositions = [
            CGPoint(x:290, y:120),
            CGPoint(x:310, y:200),
            CGPoint(x:300, y:280),
            CGPoint(x:290, y:360),
            CGPoint(x:310, y:440),
            CGPoint(x:300, y:520)
        ]
        
        self.currBubbleList = Array(self.landingFeedViewArray.prefix(6))
        
        var bubbleListButtonCenter = self.bubbleListButton.center
        
        // Add bubble list items into subview behind the bubble list button
        for (index, bubbleView) in self.currBubbleList.enumerated() {
            bubbleView.center = bubbleListButtonCenter
            self.recordButton.insertSubview(bubbleView, at: index)
        }
    }
    
    func toggleBubbleListView() {
        let bubbleGroup = DispatchGroup()
        
        // For filtering out other subviews
        var bubbleSubviews: [UIView] = []
        for bubbleView in self.recordButton.subviews {
            if (bubbleView is LandingFeedSegmentView) {
                bubbleSubviews.append(bubbleView)
            }
        }
        
        print(self.expanded)
        if (!self.expanded) {
            self.animator.removeAllBehaviors()
            
            for (index, bubbleView) in bubbleSubviews.enumerated() {
                bubbleGroup.enter()
                self.snapBubbleViewToPos(bubbleView: bubbleView, newPos: self.bubbleListPositions[index], damping: CGFloat(0.5), velocity: CGFloat(8.5), group: bubbleGroup)
            }
            bubbleGroup.notify(queue: DispatchQueue.main, execute: {
                self.expanded = true
            })
        }   else {
            self.animator.removeAllBehaviors()
            
            for (index, bubbleView) in bubbleSubviews.enumerated() {
                let collapseCenter = CGPoint(x: self.bubbleListButton.center.x + 10, y: self.bubbleListButton.center.y + 10)
                
                bubbleGroup.enter()
                self.snapBubbleViewToPos(bubbleView: bubbleView, newPos: collapseCenter, damping: CGFloat(1.5), velocity: CGFloat(12.0), group: bubbleGroup)
            }
            bubbleGroup.notify(queue: DispatchQueue.main, execute: {
                self.expanded = false
            })
        }
    }
    
    func snapBubbleViewToPos(bubbleView: UIView, newPos: CGPoint, damping: CGFloat, velocity: CGFloat, group: DispatchGroup) {
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: damping,
                       initialSpringVelocity: velocity,
                       options: [],
                       animations: {
                        bubbleView.center = newPos
                        
                        if (!self.expanded) {
                            self.increaseBubbleSize(bubbleView: bubbleView)
                        }   else {
                            self.decreaseBubbleSize(bubbleView: bubbleView)
                        }
                        
        },
                       completion: { Void in()  }
        )
        
        group.leave()
    }
    
    func increaseBubbleSize(bubbleView: UIView) {
        bubbleView.frame.size.width = 50
        bubbleView.frame.size.height = 50
        bubbleView.layer.cornerRadius = 25
    }
    
    func decreaseBubbleSize(bubbleView: UIView) {
        bubbleView.frame.size.width = 30
        bubbleView.frame.size.height = 30
        bubbleView.layer.cornerRadius = 15
    }
    
    func reloadBubbleList() {
        if (self.expanded) {
            // Remove first bubble
            (self.recordButton.subviews[0] != nil) ? self.recordButton.subviews[0].removeFromSuperview() : print("No more notifications")
            
            // Push bubbles up to theon previous to them's position
            
            // Cue the 
        }   else {
            
        }
    }
}
