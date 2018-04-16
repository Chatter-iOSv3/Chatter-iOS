//
//  DirectEmojiViewModal.swift
//  Chatter
//
//  Created by Austen Ma on 4/15/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Foundation
import ISEmojiView

class DirectEmojiViewModal: UIViewController, ISEmojiViewDelegate {
    @IBOutlet weak var emojiTextView: UITextView!
    @IBOutlet weak var pickedEmojiView: UIView!
    @IBOutlet weak var pickedEmojiOutterView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize emojiView
        let emojiView = ISEmojiView()
        emojiView.delegate = self
        
        // Click on textfield programmatically to bring up emojiView
        emojiTextView.tintColor = UIColor(red: 68/255, green: 14/255, blue: 112/255, alpha: 1.0)
        emojiTextView.becomeFirstResponder()
        
        // Open emojiView with programmatic click
        emojiTextView.inputView = emojiView
    }
    
    func emojiViewDidSelectEmoji(emojiView: ISEmojiView, emoji: String) {
        print(emoji)
        self.pickedEmojiView.layer.borderWidth = 7
        self.pickedEmojiView.layer.borderColor = UIColor.lightGray.cgColor
        self.pickedEmojiView.layer.cornerRadius = self.pickedEmojiView.frame.size.height / 2
        self.pickedEmojiOutterView.layer.borderWidth = 1
        self.pickedEmojiOutterView.layer.borderColor = UIColor.lightGray.cgColor
        self.pickedEmojiOutterView.layer.cornerRadius = self.pickedEmojiOutterView.frame.size.height / 2
        
        self.emojiTextView.insertText(emoji)
    }
    
    func emojiViewDidPressDeleteButton(emojiView: ISEmojiView) {
        dismiss(animated: true, completion: nil)
    }
}
