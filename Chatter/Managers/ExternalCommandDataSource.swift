//
//  ExternalCommandDataSource.swift
//  Chatter
//
//  Created by Austen Ma on 6/4/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation

class ExternalCommandDataSource: NSObject {
    
    let externalCommandManager: ExternalCommandManager
    
    init(externalCommandManager: ExternalCommandManager) {
        self.externalCommandManager = externalCommandManager
    }
    
    /// Enumeration of the different sections of the UITableView.
    private enum commandSection: Int {
        case trackChanging, seek
        
        func sectionTitle() -> String {
            switch self {
            case .trackChanging: return "Track Changing Commands"
            case .seek: return "Seek Commands"
            }
        }
    }
    
    /// Enumeration of the various commands supported by `MPExternalCommandCenter`.
    private enum command {
        case nextTrack, previousTrack, seekForward, seekBackward
//        skipForward, skipBackward, seekForward, seekBackward, changePlaybackPosition, like, dislike, bookmark
        
        init?(_ section: Int, row: Int) {
            guard let section = commandSection(rawValue: section) else { return nil }
            
            switch section {
            case .trackChanging:
                if row == 0 {
                    self = .nextTrack
                }
                else {
                    self = .previousTrack
                }
            case .seek:
                if row == 0 {
                    self = .seekForward
                }
                else {
                    self = .seekBackward
                }
            }
        }
        
        func commandTitle() -> String {
            switch self {
            case .nextTrack: return "Next Track Command"
            case .previousTrack: return "Previous Track Command"
            case .seekForward: return "Seek Forward Command"
            case .seekBackward: return "Seek Backward Command"
            }
        }
    }
    
    func numberOfExternalCommandSections() -> Int {
        #if os(iOS)
        return 4
        #else
        return 3
        #endif
    }
    
    func titleForSection(_ section: Int) -> String {
        guard let commandSection = commandSection(rawValue: section) else { return "Invalid Section" }
        
        return commandSection.sectionTitle()
    }
    
    func titleStringForCommand(at section: Int, row: Int) -> String {
        guard let externalCommand = command(section, row: row) else { return "Invalid Command" }
        
        return externalCommand.commandTitle()
    }
    
//    func numberOfItemsInSection(_ section: Int) -> Int {
//        switch section {
//        case 0: return 2
//        case 1: return 2
//        case 2: return 3
//        case 3: return 3
//        default: return 0
//        }
//    }
    
    func toggleCommandHandler(with section: Int, row: Int, enable: Bool) {
        guard let externalCommand = command(section, row: row) else { return }
        
        switch externalCommand {
        case .nextTrack: externalCommandManager.toggleNextTrackCommand(enable)
        case .previousTrack: externalCommandManager.togglePreviousTrackCommand(enable)
        case .seekForward: externalCommandManager.toggleSeekForwardCommand(enable)
        case .seekBackward: externalCommandManager.toggleSeekBackwardCommand(enable)
        }
    }
}
