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
    @IBOutlet weak var composeChatterButton: UIButton!
    @IBOutlet weak var directChatterRequests: UIButton!
    
    var chatterViewController: UIViewController?
    var directViewController: UIViewController?
    
    override func viewDidLoad() {
        
//      Styling for bar buttons
        settings.style.buttonBarItemBackgroundColor = .clear
        settings.style.buttonBarItemFont = .boldSystemFont(ofSize: 17)
        settings.style.selectedBarHeight = 2.0
        settings.style.selectedBarBackgroundColor = .white
        settings.style.buttonBarItemLeftRightMargin = 0
        settings.style.buttonBarLeftContentInset = 100
        settings.style.buttonBarRightContentInset = 100
        
        directChatterRequests.layer.cornerRadius = directChatterRequests.frame.height / 2

        changeCurrentIndexProgressive = { [weak self] (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = .lightGray
            newCell?.label.textColor = .white
        }
        super.viewDidLoad()
        
        // Listens for starting Direct Chatter
        NotificationCenter.default.addObserver(self, selector: #selector(goToDirectChatter(notification:)), name: .startDirectChatter, object: nil)
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        self.chatterViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatterFeedChild1")
        self.chatterViewController?.view.layoutSubviews()
        self.directViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatterFeedChild2")
        self.directViewController?.view.layoutSubviews()
        return [self.chatterViewController! , self.directViewController!]
    }
    
    @objc func goToDirectChatter(notification:NSNotification) {
        self.directViewController?.view.layoutSubviews()
        moveToViewController(at: 1)
    }
}
