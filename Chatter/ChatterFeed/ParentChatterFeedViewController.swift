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
    
    override func viewDidLoad() {
        
//      Styling for bar buttons
        settings.style.buttonBarItemBackgroundColor = .clear
        settings.style.buttonBarItemFont = .boldSystemFont(ofSize: 17)
        settings.style.selectedBarHeight = 2.0
        settings.style.selectedBarBackgroundColor = .white
        settings.style.buttonBarItemLeftRightMargin = 0
        settings.style.buttonBarLeftContentInset = 100
        settings.style.buttonBarRightContentInset = 100

        changeCurrentIndexProgressive = { [weak self] (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = .lightGray
            newCell?.label.textColor = .white
        }
        super.viewDidLoad()
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let child_1 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatterFeedChild1")
        let child_2 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatterFeedChild2")
        return [child_1, child_2]
    }
}
