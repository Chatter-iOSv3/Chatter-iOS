//
//  AppDelegate.swift
//  Chatter
//
//  Created by Austen Ma on 2/24/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import UIKit
import Firebase
import IQKeyboardManager

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    // The instance of `ExternalCommandManager` that the app uses for managing external command events.
    var externalCommandManager: ExternalCommandManager!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Initialize Firebase ----------------------------
        FirebaseApp.configure()
        let storage = Storage.storage()
        
        // Initialize Keyboard manager  -------------------------
        IQKeyboardManager.shared().isEnabled = true
        IQKeyboardManager.shared().disabledToolbarClasses.add(EmojiViewModal.self)
        IQKeyboardManager.shared().disabledToolbarClasses.add(DirectEmojiViewModal.self)
        
        // Initialize External Command handlers ----------------------------
        // Initialize the `ExternalCommandManager`.
        externalCommandManager = ExternalCommandManager()
        
        // Always enable playback commands in MPRemoteCommandCenter.
        externalCommandManager.activatePlaybackCommands(true)
        externalCommandManager.toggleNextTrackCommand(true)
        externalCommandManager.togglePreviousTrackCommand(true)
        externalCommandManager.toggleSeekForwardCommand(true)
        externalCommandManager.toggleSeekBackwardCommand(true)
        // Inject dependencies needed by the app.
        
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

