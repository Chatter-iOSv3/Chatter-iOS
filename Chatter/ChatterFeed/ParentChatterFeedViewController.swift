//
//  ParentChatterFeedViewController.swift
//  Chatter
//
//  Created by Austen Ma on 4/3/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import XLPagerTabStrip

class ParentChatterFeedViewController: ButtonBarPagerTabStripViewController {
    @IBOutlet weak var curveViewPlaceholder: UIView!
    @IBOutlet weak var feedPageAvatarView: UIView!
    @IBOutlet weak var directChatterInboxBadge: UIButton!
    @IBOutlet weak var directChatterContainerView: UIView!
    
    var directChatterInboxBadgeCount: Int! = 0
    var directChatterUnreadArr: [String]! = []
    
    var chatterViewController: UIViewController?
    var savedViewController: UIViewController?
    
    var profileImage: UIImage?
    
    override func viewDidLoad() {
        // Hide Direct Chatter Initially
        directChatterContainerView.alpha = 0.0
        
        // Styling for Placeholder view
        curveViewPlaceholder.layer.cornerRadius = 20
        feedPageAvatarView.layer.cornerRadius = feedPageAvatarView.frame.size.height / 2
        feedPageAvatarView.layer.borderWidth = 2
        feedPageAvatarView.layer.borderColor = UIColor.white.cgColor
        
        // Styling for bar buttons
        self.configureBarButtons()

        changeCurrentIndexProgressive = { [weak self] (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            
            // Styling Button Bar Cells
            
            if (newCell?.label.text == "Feed" || newCell == nil) {
                self?.configureCellsOnChatter(oldCell: oldCell, newCell: newCell)
            }   else if (newCell?.label.text == "Saved") {
                self?.configureCellsOnDirect(oldCell: oldCell, newCell: newCell)
            }
        }
        
        // Initial styling for inboxBadge
        directChatterInboxBadge.alpha = 0.0
        directChatterInboxBadge.layer.cornerRadius = directChatterInboxBadge.frame.size.height / 2
        
        super.viewDidLoad()
        
        // Listens for starting Direct Chatter and ProfileImage change
        NotificationCenter.default.addObserver(self, selector: #selector(goToSavedChatter(notification:)), name: .startDirectChatter, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(profileImageChanged(notification:)), name: .profileImageChanged, object: nil)

        // Listens for inbox activity
        NotificationCenter.default.addObserver(self, selector: #selector(directChatterInboxChanged(notification:)), name: .directChatterInboxChanged, object: nil)
    }
    
    @IBAction func openDirectChatter(sender: Any) {
        if (self.directChatterContainerView.alpha == 0.0) {
            UIView.animate(withDuration: 0.5, delay: 0.0, options:.curveLinear, animations: {
                self.directChatterContainerView.alpha = 1.0
            }, completion:nil)
        }   else {
            UIView.animate(withDuration: 0.5, delay: 0.0, options:.curveLinear, animations: {
                self.directChatterContainerView.alpha = 0.0
            }, completion:nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.post(name: .stopLandingChatter, object: nil)
    }
    
    func configureCellsOnChatter(oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?) {
        oldCell?.label.textColor = UIColor(red: 151/255, green: 19/255, blue: 232/255, alpha: 1.0)
        oldCell?.label.font = UIFont.boldSystemFont(ofSize: 14.0)
        oldCell?.layer.borderWidth = 1.0
        oldCell?.layer.borderColor = UIColor(red: 151/255, green: 19/255, blue: 232/255, alpha: 1.0).cgColor
        oldCell?.layer.backgroundColor = UIColor.white.cgColor
        oldCell?.frame.size.height = 35
        oldCell?.frame.size.width = 160
        
        if (oldCell !== nil) {
            let oldCellPath = UIBezierPath(roundedRect:(oldCell?.bounds)!,
                                           byRoundingCorners:[.topRight, .bottomRight],
                                           cornerRadii: CGSize(width: 15, height:  15))
            
            let oldCellLayer = CAShapeLayer()
            
            oldCellLayer.path = oldCellPath.cgPath
            oldCell?.layer.mask = oldCellLayer
            
            // Add border
            let borderLayer = CAShapeLayer()
            borderLayer.path = oldCellLayer.path // Reuse the Bezier path
            borderLayer.fillColor = UIColor.clear.cgColor
            borderLayer.strokeColor = UIColor(red: 151/255, green: 19/255, blue: 232/255, alpha: 1.0).cgColor
            borderLayer.lineWidth = 3
            borderLayer.frame = (oldCell?.bounds)!
            oldCell?.layer.addSublayer(borderLayer)
        }
        
        newCell?.label.textColor = .white
        newCell?.label.font = UIFont.boldSystemFont(ofSize: 14.0)
        newCell?.layer.borderWidth = 1.0
        newCell?.layer.borderColor = UIColor(red: 151/255, green: 19/255, blue: 232/255, alpha: 1.0).cgColor
        newCell?.layer.backgroundColor = UIColor(red: 151/255, green: 19/255, blue: 232/255, alpha: 1.0).cgColor
        newCell?.frame.size.height = 35
        newCell?.frame.size.width = 160
        
        if (newCell !== nil) {
            let newCellPath = UIBezierPath(roundedRect:(newCell?.bounds)!,
                                           byRoundingCorners:[.topLeft, .bottomLeft],
                                           cornerRadii: CGSize(width: 15, height:  15))
            
            let newCellLayer = CAShapeLayer()
            
            newCellLayer.path = newCellPath.cgPath
            newCell?.layer.mask = newCellLayer
        }
    }
    
    func configureCellsOnDirect(oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?) {
        oldCell?.label.textColor = UIColor(red: 151/255, green: 19/255, blue: 232/255, alpha: 1.0)
        oldCell?.layer.borderWidth = 1.0
        oldCell?.layer.borderColor = UIColor(red: 151/255, green: 19/255, blue: 232/255, alpha: 1.0).cgColor
        oldCell?.layer.backgroundColor = UIColor.white.cgColor
        oldCell?.frame.size.height = 35
        oldCell?.frame.size.width = 160
        
        if (oldCell !== nil) {
            let oldCellPath = UIBezierPath(roundedRect:(oldCell?.bounds)!,
                                           byRoundingCorners:[.topLeft, .bottomLeft],
                                           cornerRadii: CGSize(width: 15, height:  15))
            
            let oldCellLayer = CAShapeLayer()
            
            oldCellLayer.path = oldCellPath.cgPath
            oldCell?.layer.mask = oldCellLayer
            
            // Add border
            let borderLayer = CAShapeLayer()
            borderLayer.path = oldCellLayer.path // Reuse the Bezier path
            borderLayer.fillColor = UIColor.clear.cgColor
            borderLayer.strokeColor = UIColor(red: 151/255, green: 19/255, blue: 232/255, alpha: 1.0).cgColor
            borderLayer.lineWidth = 3
            borderLayer.frame = (oldCell?.bounds)!
            oldCell?.layer.addSublayer(borderLayer)
        }
        
        newCell?.label.textColor = .white
        newCell?.layer.borderWidth = 1.0
        newCell?.layer.borderColor = UIColor(red: 151/255, green: 19/255, blue: 232/255, alpha: 1.0).cgColor
        newCell?.layer.backgroundColor = UIColor(red: 151/255, green: 19/255, blue: 232/255, alpha: 1.0).cgColor
        newCell?.frame.size.height = 35
        newCell?.frame.size.width = 160
        
        if (newCell !== nil) {
            let newCellPath = UIBezierPath(roundedRect:(newCell?.bounds)!,
                                           byRoundingCorners:[.topRight, .bottomRight],
                                           cornerRadii: CGSize(width: 15, height:  15))
            
            let newCellLayer = CAShapeLayer()
            
            newCellLayer.path = newCellPath.cgPath
            newCell?.layer.mask = newCellLayer
        }
    }
    
    func configureBarButtons() {
        settings.style.buttonBarItemBackgroundColor = .clear
        settings.style.buttonBarItemFont = .boldSystemFont(ofSize: 17)
        settings.style.selectedBarHeight = 2.0
        settings.style.selectedBarBackgroundColor = .white
        settings.style.buttonBarItemLeftRightMargin = 0
        settings.style.buttonBarLeftContentInset = 35
        settings.style.buttonBarRightContentInset = 35
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        self.chatterViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatterFeedChild1")
        self.chatterViewController?.view.layoutSubviews()
        self.savedViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatterFeedChild2")
        self.savedViewController?.view.layoutSubviews()
        return [self.chatterViewController! , self.savedViewController!]
    }
    
    @objc func goToSavedChatter(notification:NSNotification) {
        self.savedViewController?.view.layoutSubviews()
        moveToViewController(at: 1)
    }
    
    @objc func profileImageChanged(notification:NSNotification) {
        if let image = notification.userInfo?["image"] as? UIImage {
            self.feedPageAvatarView.backgroundColor = UIColor(patternImage: image)
        }
    }
    
    @objc func directChatterInboxChanged(notification: NSNotification) {
        let readStatus = notification.userInfo?["readStatus"] as? String
        let id = notification.userInfo?["chatterSegmentID"] as? String
        
        if (!self.directChatterUnreadArr.contains(id!)) {
            if (readStatus == "unread") {
                self.directChatterInboxBadgeCount = self.directChatterInboxBadgeCount + 1
                self.directChatterInboxBadge.setTitle(String(self.directChatterInboxBadgeCount), for: .normal)
                self.directChatterInboxBadge.alpha = 1.0
            }   else if (readStatus == "read") {
                self.directChatterInboxBadgeCount = self.directChatterInboxBadgeCount - 1
                self.directChatterInboxBadge.setTitle(String(self.directChatterInboxBadgeCount), for: .normal)
                
                if (self.directChatterInboxBadgeCount == 0) {
                    self.directChatterInboxBadge.alpha = 0.0
                }
            }
            
            self.directChatterUnreadArr.append(id!)
        }
    }
}
