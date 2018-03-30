//
//  EmojiViewModalViewController.swift
//  Chatter
//
//  Created by Austen Ma on 3/29/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import UIKit
import Foundation
import ISEmojiView

class EmojiViewModal: UIViewController, ISEmojiViewDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func emojiViewDidSelectEmoji(emojiView: ISEmojiView, emoji: String) {
        dismiss(animated: true, completion: nil)
    }
    
    func emojiViewDidPressDeleteButton(emojiView: ISEmojiView) {
        print("HELLO")
    }
}
