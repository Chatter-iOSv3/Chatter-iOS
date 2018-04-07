//
//  LandingPageViewController.swift
//  Chatter
//
//  Created by Austen Ma on 2/26/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import UIKit

class LandingPageViewController: UIPageViewController {

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate lazy var pages: [UIViewController] = {
        let menuViewController = self.getViewController(withIdentifier: "Menu")
        let landingRecordViewController = self.getViewController(withIdentifier: "LandingRecord")
        let parentChatterFeedViewController = self.getViewController(withIdentifier: "ParentChatterFeed")
        
        menuViewController.view.layoutSubviews()
        landingRecordViewController.view.layoutSubviews()
        parentChatterFeedViewController.view.layoutSubviews()
        
        return [
            menuViewController,
            landingRecordViewController,
            parentChatterFeedViewController
        ]
    }()
    
    fileprivate func getViewController(withIdentifier identifier: String) -> UIViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: identifier)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate   = self
        
        setViewControllers([pages[1]], direction: .forward, animated: true, completion: nil)
    }

}


extension LandingPageViewController: UIPageViewControllerDataSource
{
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let viewControllerIndex = pages.index(of: viewController) else { return nil }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0          else { return nil }
        guard pages.count > previousIndex else { return nil }

        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        guard let viewControllerIndex = pages.index(of: viewController) else { return nil }
        
        let nextIndex = viewControllerIndex + 1
        
        guard nextIndex < pages.count else { return nil }
        guard pages.count > nextIndex else { return nil }
        
        return pages[nextIndex]
    }
}

extension LandingPageViewController: UIPageViewControllerDelegate { }


// For Tapping Out of Keyboard View

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension UIView {
    
    enum ViewSide {
        case Left, Right, Top, Bottom
    }
    
    func addBorder(toSide side: ViewSide, withColor color: CGColor, andThickness thickness: CGFloat) {
        
        let border = CALayer()
        border.backgroundColor = color
        
        switch side {
        case .Left: border.frame = CGRect(x: frame.minX, y: frame.minY, width: thickness, height: frame.height); break
        case .Right: border.frame = CGRect(x: frame.maxX, y: frame.minY, width: thickness, height: frame.height); break
        case .Top: border.frame = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: thickness); break
        case .Bottom: border.frame = CGRect(x: frame.minX, y: frame.maxY, width: frame.width, height: thickness); break
        }
        
        layer.addSublayer(border)
    }
}

extension Notification.Name {
    // When invitation is accepted, updates Followers list
    static let invitationAcceptedRerender = Notification.Name("invitationAcceptedRerender")
    
    // When compose modal/start direct Chatter is fired
    static let startDirectChatter = Notification.Name("startDirectChatter")
}
