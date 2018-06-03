//
//  BubbleListCell.swift
//  Chatter
//
//  Created by Austen Ma on 3/22/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit

class BubbleListCell: UITableViewCell {
    @IBOutlet weak var landingFeedSegment: LandingFeedSegmentView!
    
    func addAvatarView() {
        self.addSubview(self.landingFeedSegment)
    }
    
    func animateAvatarViews() {
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: CGFloat(0.15),
                       initialSpringVelocity: CGFloat(12.0),
                       options: [],
                       animations: {
                        self.landingFeedSegment.frame.size.width = 50
                        self.landingFeedSegment.frame.size.height = 50
                        self.landingFeedSegment.layer.cornerRadius = 25
        },
                       completion: { Void in()  }
        )
    }
    
    override func awakeFromNib() {
    }
}
