//
//  LandingStarShowerHelper.swift
//  Chatter
//
//  Created by Austen Ma on 6/13/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit

extension LandingRecord {
    func starShower(num: Int) {
        let starGroup = DispatchGroup()
        
        // Generate stars and star positions
        for n in 0...num-1 {
            starGroup.enter()
            
            let starImage = UIImage(named: "Star")
            let starImageView = UIImageView(image: starImage!)
            starImageView.frame.size.height = 30
            starImageView.frame.size.width = 30
        
            
            let randomX = Int(arc4random_uniform(320) + 50)
            let randomY =  Int(arc4random_uniform(30) + 15)
            let starPos = CGPoint(x: randomX, y:randomY)
            
            starImageView.center = starPos
            self.recordButton.addSubview(starImageView)
            starGroup.leave()
        }
        
        starGroup.notify(queue: DispatchQueue.main, execute: {
            var starSubviews: [UIView] = []
            // Get Stars from Subviews
            for view in self.recordButton.subviews {
                if (view is UIImageView) {
                    starSubviews.append(view)
                }
            }
            
            self.addStarShowerGravity(stars: starSubviews)
            self.addStarShowerBounces(stars: starSubviews)
            self.addStarShowerCollisions(stars: starSubviews)
        })
    }
    
    func addStarShowerGravity(stars: [UIView]) {
        let gravity = UIGravityBehavior(items: stars)
        self.animator.addBehavior(gravity)
    }
    
    func addStarShowerCollisions(stars: [UIView]) {
        let collisionBehavior = UICollisionBehavior(items: stars)
        collisionBehavior.translatesReferenceBoundsIntoBoundary = true
        self.animator.addBehavior(collisionBehavior)
    }
    
    func addStarShowerBounces(stars: [UIView]) {
        let bounce = UIDynamicItemBehavior(items: stars)
        bounce.elasticity = 0.5
        self.animator.addBehavior(bounce)
    }
    
    func clearStars() {
        
    }
}
