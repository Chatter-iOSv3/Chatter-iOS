//
//  FilterHelpers.swift
//  Chatter
//
//  Created by Austen Ma on 6/1/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import AudioKit

extension RecordEditModal {
    func handleFilterSelected(filterID: String) {
        switch filterID {
        case "Robot":
            self.handleRobotFilter()
        case "Poop":
            self.handlePoopFilter()
        case "Studio":
            self.handleStudioFilter()
        default:
            print("Filter malfunction")
        }
    }
    
    func handleRobotFilter() {
        print("Robot Filter")
    }
    
    func handlePoopFilter() {
        print("Poop Filter")
    }
    
    func handleStudioFilter() {
        print("Studio Filter")
    }
}
