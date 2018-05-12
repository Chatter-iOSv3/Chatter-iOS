//
//  LandingRecordUploadAudio.swift
//  Chatter
//
//  Created by Austen Ma on 5/11/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import AVFoundation

extension LandingRecord {
    func setupUploading() {
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(presentVideoPicker))
        swipeUp.direction = UISwipeGestureRecognizerDirection.up
        self.recordButton.addGestureRecognizer(swipeUp)
        
        // Initialize videoPicker
        self.initializeVideoPicker()
    }
    
    @objc func presentVideoPicker() {
        print("Starting Upload Flow")
        self.present(self.videoPicker, animated: true, completion: nil)
    }
    
    func initializeVideoPicker() {
        // Initialize Video Picker
        self.videoPicker = UIImagePickerController()
        self.videoPicker.delegate = self
        self.videoPicker.sourceType = .photoLibrary
        self.videoPicker.mediaTypes = [kUTTypeMovie as String]
        self.videoPicker.allowsEditing = true
        self.videoPicker.videoMaximumDuration = 20
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        viewController.navigationItem.title = "Videos"
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let videoURL = info["UIImagePickerControllerMediaURL"] as? URL
        print("info", info)
        // Process and extract the video selected
        let videoAsset = AVAsset(url: videoURL!) as AVAsset
        videoAsset._getDataFor(asset: videoAsset, completion: {tempFileURL in
            print("Success", tempFileURL)
            self.uploadedTempURL = tempFileURL
            self.dismiss(animated: true, completion: nil)
            
            // Open uploadEdit modal
            print("Starting Upload Flow")
            self.performSegue(withIdentifier: "showUploadModal", sender: nil)
        })
    }
}

extension AVAsset {
    func _getDataFor(asset: AVAsset, completion: @escaping (URL?) -> ()) {
        guard asset.isExportable else {
            completion(nil)
            return
        }
        
        let composition = AVMutableComposition()
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))
        
        let sourceAudioTrack = asset.tracks(withMediaType: AVMediaType.audio).first!
        do {
            try compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), of: sourceAudioTrack, at: kCMTimeZero)
        } catch(_) {
            completion(nil)
            return
        }
        
        guard
            let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
                completion(nil)
                return
        }
        
        var tempFileUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("currentUpload.m4a", isDirectory: false)
        tempFileUrl = URL(fileURLWithPath: tempFileUrl.path)
        
        exportSession.outputURL = tempFileUrl
        exportSession.outputFileType = AVFileType.m4a
        let startTime = CMTimeMake(0, 1)
        let timeRange = CMTimeRangeMake(startTime, asset.duration)
        exportSession.timeRange = timeRange
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                print("EXPORT SUCCESS")
                
//                let data = try? Data(contentsOf: tempFileUrl)
//                _ = try? FileManager.default.removeItem(at: tempFileUrl)
                completion(tempFileUrl)
            case .unknown, .waiting, .exporting, .failed, .cancelled:
                print("FAILED EXPORT")
            }
        }
    }
}
