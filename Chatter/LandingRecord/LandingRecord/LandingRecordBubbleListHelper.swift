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
            CGPoint(x:300, y:120),
            CGPoint(x:320, y:200),
            CGPoint(x:300, y:280),
            CGPoint(x:320, y:360),
            CGPoint(x:300, y:440),
            CGPoint(x:320, y:520)
        ]
        
        self.currBubbleList = Array(self.landingFeedViewArray.prefix(6))
        
        var bubbleListButtonCenter = self.bubbleListButton.center
        
        // Add bubble list items into subview behind the bubble list button
        for (index, bubbleView) in self.currBubbleList.enumerated() {
            
            if (!self.expanded) {
                self.decreaseBubbleSize(bubbleView: bubbleView)
            }
            
            bubbleView.center = bubbleListButtonCenter
            self.recordButton.insertSubview(bubbleView, at: index)
        }
    }
    
    func reInitializeBubbleList() {
        let bubbleGroup = DispatchGroup()
        for bubbleView in self.recordButton.subviews {
            bubbleGroup.enter()
            if (bubbleView is LandingFeedSegmentView) {
                bubbleView.removeFromSuperview()
            }
            bubbleGroup.leave()
        }
        
        bubbleGroup.notify(queue: DispatchQueue.main, execute: {
            self.initializeBubbleList()
        })
    }
    
    func reloadCurrBubbleList() {
        self.currBubbleList = Array(self.landingFeedViewArray.prefix(6))
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
        
        if (!self.expanded) {
            self.animator.removeAllBehaviors()
            
            for (index, bubbleView) in bubbleSubviews.enumerated() {
                bubbleGroup.enter()
                self.snapBubbleViewToPos(bubbleView: bubbleView, newPos: self.bubbleListPositions[index], damping: CGFloat(0.5), velocity: CGFloat(8.5), group: bubbleGroup, queuing: false, expanding: true)
            }
            bubbleGroup.notify(queue: DispatchQueue.main, execute: {
                self.expanded = true
            })
        }   else {
            self.animator.removeAllBehaviors()
            
            for (index, bubbleView) in bubbleSubviews.enumerated() {
                let collapseCenter = CGPoint(x: self.bubbleListButton.center.x, y: self.bubbleListButton.center.y)
                
                bubbleGroup.enter()
                self.snapBubbleViewToPos(bubbleView: bubbleView, newPos: collapseCenter, damping: CGFloat(1.5), velocity: CGFloat(12.0), group: bubbleGroup, queuing: false, expanding: false)
            }
            bubbleGroup.notify(queue: DispatchQueue.main, execute: {
                self.expanded = false
            })
        }
    }
    
    func snapBubbleViewToPos(bubbleView: UIView, newPos: CGPoint, damping: CGFloat, velocity: CGFloat, group: DispatchGroup, queuing: Bool, expanding: Bool) {
        if (expanding) {
            self.increaseBubbleSize(bubbleView: bubbleView)
        }   else if (!expanding) {
            self.decreaseBubbleSize(bubbleView: bubbleView)
        }
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: damping,
                       initialSpringVelocity: velocity,
                       options: [],
                       animations: {
                        bubbleView.center = newPos
                        
        },
                       completion: { Void in()  }
        )
        
        if (!self.expanded && queuing) {
            self.decreaseBubbleSize(bubbleView: bubbleView)
        }   else if (self.expanded && queuing) {
            self.increaseBubbleSize(bubbleView: bubbleView)
        }
        
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
    
    func reorderBubbleList() {
        if (self.expanded) {
            
            var bubbleSubviews: [UIView] = []
            // Get bubbles from Subviews
            for view in self.recordButton.subviews {
                if (view is LandingFeedSegmentView) {
                    bubbleSubviews.append(view)
                }
            }
            
            // Remove first bubble
            (bubbleSubviews.count > 0) ? bubbleSubviews[0].removeFromSuperview() : print("No more notifications")
            
            // Push bubbles up to the previous's position
            let bubbleGroup = DispatchGroup()
            
            for (index, bubble) in self.currBubbleList.enumerated() {
                bubbleGroup.enter()
                snapBubbleViewToPos(bubbleView: bubble, newPos: bubbleListPositions[index], damping: CGFloat(1.0), velocity: CGFloat(8.5), group: bubbleGroup, queuing: true, expanding: true)
            }
            
            // Add the newest bubble to curr list
            let incomingBubble = (self.landingFeedViewArray.count > 5) ? self.landingFeedViewArray[5] : nil
            
            if (incomingBubble != nil) {
                // Add to the 6th position
                incomingBubble?.center = self.bubbleListPositions[5]
                incomingBubble?.alpha = 0.0
                self.recordButton.insertSubview(incomingBubble!, at: 5)
                
                UIView.animate(withDuration: 0.3, delay: 0.4, options:.curveLinear, animations: {
                    incomingBubble?.alpha = 1.0
                }, completion:nil)
            }
        }   else {
            
            var bubbleSubviews: [UIView] = []
            // Get Stars from Subviews
            for view in self.recordButton.subviews {
                if (view is LandingFeedSegmentView) {
                    bubbleSubviews.append(view)
                }
            }
            
            // Remove first bubble
            (bubbleSubviews.count > 0) ? bubbleSubviews[0].removeFromSuperview() : print("No more notifications")
            
            // Push bubbles up to the previous's position
            let bubbleGroup = DispatchGroup()
            let collapseCenter = CGPoint(x: self.bubbleListButton.center.x, y: self.bubbleListButton.center.y)
            
            for (index, bubble) in self.currBubbleList.enumerated() {
                bubbleGroup.enter()
                snapBubbleViewToPos(bubbleView: bubble, newPos: collapseCenter, damping: CGFloat(1.0), velocity: CGFloat(8.5), group: bubbleGroup, queuing: true, expanding: false)
            }
            
            // Add the newest bubble to curr list
            let incomingBubble = (self.landingFeedViewArray.count > 5) ? self.landingFeedViewArray[5] : nil
            
            if (incomingBubble != nil) {
                self.decreaseBubbleSize(bubbleView: incomingBubble!)
                incomingBubble?.center = collapseCenter
                incomingBubble?.alpha = 0.0
                self.recordButton.insertSubview(incomingBubble!, at: 5)
                
                UIView.animate(withDuration: 0.3, delay: 0.4, options:.curveLinear, animations: {
                    incomingBubble?.alpha = 1.0
                }, completion:nil)
            }
        }
    }
}
