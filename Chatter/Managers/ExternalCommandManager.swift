//
//  ExternalCommandManager.swift
//  Chatter
//
//  Created by Austen Ma on 6/4/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import MediaPlayer

class ExternalCommandManager: NSObject {
    // Reference of `MPRemoteCommandCenter` used to configure and setup remote control events in the application.
    let externalCommandCenter = MPRemoteCommandCenter.shared()
    
    // Activate Handlers
    func activatePlaybackCommands(_ enable: Bool) {
        print("Activating PB Controls")
        if enable {
            externalCommandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(ExternalCommandManager.handleTogglePlayPauseCommandEvent(_:)))
            
        }
        else {
            externalCommandCenter.togglePlayPauseCommand.removeTarget(self, action: #selector(ExternalCommandManager.handleTogglePlayPauseCommandEvent(_:)))
        }
        
        externalCommandCenter.togglePlayPauseCommand.isEnabled = enable
    }
    
    func toggleNextTrackCommand(_ enable: Bool) {
        print("Activating NT")
        if enable {
            externalCommandCenter.nextTrackCommand.addTarget(self, action: #selector(ExternalCommandManager.handleNextTrackCommandEvent(_:)))
        }
        else {
            externalCommandCenter.nextTrackCommand.removeTarget(self, action: #selector(ExternalCommandManager.handleNextTrackCommandEvent(_:)))
        }
        
        externalCommandCenter.nextTrackCommand.isEnabled = enable
    }
    
    func togglePreviousTrackCommand(_ enable: Bool) {
        print("Activating PT")
        if enable {
            externalCommandCenter.previousTrackCommand.addTarget(self, action: #selector(ExternalCommandManager.handlePreviousTrackCommandEvent(event:)))
        }
        else {
            externalCommandCenter.previousTrackCommand.removeTarget(self, action: #selector(ExternalCommandManager.handlePreviousTrackCommandEvent(event:)))
        }
        
        externalCommandCenter.previousTrackCommand.isEnabled = enable
    }
    
    func toggleSeekForwardCommand(_ enable: Bool) {
        print("Activating SF")
        if enable {
            externalCommandCenter.seekForwardCommand.addTarget(self, action: #selector(ExternalCommandManager.handleSeekForwardCommandEvent(event:)))
        }
        else {
            externalCommandCenter.seekForwardCommand.removeTarget(self, action: #selector(ExternalCommandManager.handleSeekForwardCommandEvent(event:)))
        }
        
        externalCommandCenter.seekForwardCommand.isEnabled = enable
    }
    
    func toggleSeekBackwardCommand(_ enable: Bool) {
        print("Activating SB")
        if enable {
            externalCommandCenter.seekBackwardCommand.addTarget(self, action: #selector(ExternalCommandManager.handleSeekBackwardCommandEvent(event:)))
        }
        else {
            externalCommandCenter.seekBackwardCommand.removeTarget(self, action: #selector(ExternalCommandManager.handleSeekBackwardCommandEvent(event:)))
        }
        
        externalCommandCenter.seekBackwardCommand.isEnabled = enable
    }
    
    // Command Handlers ----------------------------------------------
    
    @objc func handleTogglePlayPauseCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        print("TOGGLE PLAY/PAUSE OUTTER HEARD")
        
        return .success
    }
    
    @objc func handleNextTrackCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        print("NEXT TRACK COMMAND HEARD")
        return .success
    }
    
    @objc func handlePreviousTrackCommandEvent(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        print("PREVIOUS TRACK COMMAND HEARD")
        return .success
    }
    
    // MARK: Seek Command Handlers
    @objc func handleSeekForwardCommandEvent(event: MPSeekCommandEvent) -> MPRemoteCommandHandlerStatus {
        print("SKIPPING FORWARD COMMAND SEEK")
        switch event.type {
        case .beginSeeking: print("SKIPPING FORWARD COMMAND BEGIN SEEK")
        case .endSeeking: print("SKIPPING FORWARD COMMAND END SEEK")
        }
        return .success
    }
    
    @objc func handleSeekBackwardCommandEvent(event: MPSeekCommandEvent) -> MPRemoteCommandHandlerStatus {
        print("SKIPPING BACKWARD COMMAND SEEK")
        switch event.type {
        case .beginSeeking: print("SKIPPING BACKWARD COMMAND BEGIN SEEK")
        case .endSeeking: print("SKIPPING BACKWARD COMMAND END SEEK")
        }
        return .success
    }
    
    // Deinit -------------------------------------------------------------------
    
    deinit {
        activatePlaybackCommands(false)
        toggleNextTrackCommand(false)
        togglePreviousTrackCommand(false)
        toggleSeekForwardCommand(false)
        toggleSeekBackwardCommand(false)
    }
}
