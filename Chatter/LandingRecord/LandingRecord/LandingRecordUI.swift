//
//  LandingRecordUIMethods.swift
//  Chatter
//
//  Created by Austen Ma on 5/10/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit

extension LandingRecord {
    //Init helpers
    func setProfileImageWithURL(imageURL: String, newView: UIView) {
        let profileImageDownloadRef = storage.reference(forURL: imageURL)
        var currImage: UIImage?
        
        print("Querying Image")
        profileImageDownloadRef.downloadURL(completion: { (url, error) in
            var data = Data()
            
            do {
                data = try Data(contentsOf: url!)
            } catch {
                print(error)
            }
            currImage = UIImage(data: data as Data)
            
            let resizedCurrImage = self.resizeImage(image: currImage!, targetSize: CGSize(width: 50, height:  50))
            
            newView.backgroundColor = UIColor(patternImage: resizedCurrImage)
        })
    }
    
    func setBubbleLabel(firstnameLetter: String, newView: UIView) {
        // Label Avatar button
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        label.textAlignment = .center
        label.font = label.font.withSize(20)
        label.textColor = .white
        label.text = firstnameLetter
        newView.addSubview(label)
    }
    
    // View methods ------------------------------------------
    
    @objc func exposeLabels() {
        self.landingRecordLabel.alpha = 1.0
        self.bubbleListButton.alpha = 1.0
    }
    
    @objc func toggleLabels() {
        //Toggle on views after loaded
        self.landingRecordLabel.alpha = CGFloat(self.labelAlpha)
        self.bubbleListButton.alpha = 1.0
        
        if (!isRecording) {
            let labelText = (self.landingRecordLabel.text == "Tap to hear Chatter") ? "Hold to record" : "Tap to hear Chatter"
            
            UIView.transition(with: self.landingRecordLabel, duration: 1.0, options: .transitionCrossDissolve, animations: {
                self.landingRecordLabel.text = labelText
            }, completion: { completion in
                self.blinkLabel()
            })
        }
    }
    
    @objc func blinkLabel() {
        UIView.transition(with: self.landingRecordLabel, duration: 1.5, options: [.repeat, .autoreverse, .transitionCrossDissolve], animations: {
            UIView.setAnimationRepeatCount(6)
            self.landingRecordLabel.textColor = UIColor(red: 160/255, green: 35/255, blue: 232/255, alpha: 1.0)
        }, completion: { completion in
            self.landingRecordLabel.textColor = UIColor(red: 190/255, green: 140/255, blue: 234/255, alpha: 1.0)
        })
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 9.0, execute: self.toggleTask!)
    }
    
//    func configureBubbleListTable() {
//        bubbleListButton?.layer.cornerRadius = (bubbleListButton?.frame.size.height)! / 2
//
//        self.bubbleListTableView.dataSource = self
//        self.bubbleListTableView.tableFooterView = UIView()
//
//        self.bubbleListTableView.rowHeight = 80.0
//        self.bubbleListTableView.allowsSelection = false
//        self.bubbleListTableView.separatorStyle = .none
//
//        self.bubbleListButton?.setTitle(String(self.landingFeedViewArray.count), for: .normal)
//    }
//
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if (self.expanded && self.landingFeedViewArray.count > 6) {
//            return 6
//        } else if (self.expanded) {
//            return self.landingFeedViewArray.count;
//        }   else {
//            return 0
//        }
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "bubbleListCell", for: indexPath) as! BubbleListCell;
//
//        let avatarView = self.landingFeedViewArray[indexPath[1]]
//
//        if (indexPath[1] % 2 == 0) {
//            avatarView.frame.origin.x = 20
//        }   else {
//            avatarView.frame.origin.x = 0
//        }
//
//        cell.landingFeedSegment = avatarView
//        cell.addAvatarView()
//
//        return cell;
//    }
//
//    func toggleTableView() {
//        self.expanded = !self.expanded
//        let range = NSMakeRange(0, self.bubbleListTableView.numberOfSections)
//        let sections = NSIndexSet(indexesIn: range)
//
//        self.bubbleListTableView.reloadSections(sections as IndexSet, with: .automatic)
//
//        print(self.expanded)
//        if (!self.expanded) {
//            self.resetBubbles()
//        }   else {
//            self.animateBubbles()
//        }
//    }
//
//    func animateBubbles() {
//        let cells = self.bubbleListTableView.visibleCells
//
//        for cell in cells {
//            let currCell: BubbleListCell = cell as! BubbleListCell
//            currCell.animateAvatarViews()
//        }
//    }
//
//    func resetBubbles() {
//        let cells = self.landingFeedViewArray
//
//        for cell in cells {
//            cell.frame.size.width = 50
//            cell.frame.size.height = 50
//            cell.layer.cornerRadius = 25
//        }
//    }
//
    @objc func friendsListSetup(notification: NSNotification) {
        if let newFriendItem = notification.userInfo?["userData"] as? friendItem {
            // Checks repetition of friends
            if self.friendsList.index(where: {$0.userID == newFriendItem.userID}) == nil {
                self.friendsList.append(newFriendItem)
            }
        }
    }
    
    func styleRecordProgressBar() {
        // Changing progress bar height
        recordProgress.transform = recordProgress.transform.scaledBy(x: 1, y: 5)
        recordProgress.alpha = 0.0
        
        // Set the rounded edge for the outer bar
        recordProgress.layer.cornerRadius = recordProgress.frame.size.height / 2 - 1
        recordProgress.clipsToBounds = true
        
        // Set the rounded edge for the inner bar
        recordProgress.layer.sublayers![0].cornerRadius = recordProgress.frame.size.height / 2 - 1
        recordProgress.layer.sublayers![1].cornerRadius = recordProgress.frame.size.height / 2 - 1
        recordProgress.subviews[1].clipsToBounds = true
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.scale)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func presentLoadingModal() {
        performSegue(withIdentifier: "showLoadingModal", sender: nil)
    }
    
    // Misc ---------------------------------------------------------------------------
    
    func generateRandomColor() -> UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from white
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.85 // from 0.5 to 1.0 to stay away from black
        
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
}
