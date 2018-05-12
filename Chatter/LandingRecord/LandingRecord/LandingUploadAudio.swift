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
        print("*********", videoAsset.duration)
        videoAsset._getDataFor(asset: videoAsset, completion: {_ in
            print("Success")
        }) 
        
        dismiss(animated: true, completion: nil)
        
        // Open uploadEdit modal
        print("Starting Upload Flow")
        performSegue(withIdentifier: "showUploadModal", sender: nil)
    }
}

extension AVAsset {
    func _getDataFor(asset: AVAsset, completion: @escaping (Data?) -> ()) {
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
        
        var tempFileUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("temp_video_data.m4a", isDirectory: false)
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
                
                let data = try? Data(contentsOf: tempFileUrl)
                _ = try? FileManager.default.removeItem(at: tempFileUrl)
                completion(data)
            case .unknown, .waiting, .exporting, .failed, .cancelled:
                print("FAILED EXPORT")
            }
        }
    }
    
    // Provide a URL for where you wish to write
    // the audio file if successful
    func writeAudioTrack(to url: URL,
                         success: @escaping () -> (),
                         failure: @escaping (Error) -> ()) {
        do {
            let asset = try audioAsset()
            asset.write(to: url, success: success, failure: failure)
        } catch {
            failure(error)
        }
    }
    
    private func write(to url: URL,
                       success: @escaping () -> (),
                       failure: @escaping (Error) -> ()) {
        // Create an export session that will output an
        // audio track (M4A file)
        guard let exportSession = AVAssetExportSession(asset: self,
                                                       presetName: AVAssetExportPresetAppleM4A) else {
                                                        // This is just a generic error
                                                        let error = NSError(domain: "domain",
                                                                            code: 0,
                                                                            userInfo: nil)
                                                        failure(error)
                                                        
                                                        return
        }
        
        exportSession.outputFileType = .m4a
        exportSession.outputURL = url
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                success()
            case .unknown, .waiting, .exporting, .failed, .cancelled:
                let error = NSError(domain: "domain", code: 0, userInfo: nil)
                failure(error)
            }
        }
    }
    
    private func audioAsset() throws -> AVAsset {
        // Create a new container to hold the audio track
        let composition = AVMutableComposition()
        // Create an array of audio tracks in the given asset
        // Typically, there is only one
        let audioTracks = tracks(withMediaType: .audio)
        
        // Iterate through the audio tracks while
        // Adding them to a new AVAsset
        for track in audioTracks {
            let compositionTrack = composition.addMutableTrack(withMediaType: .audio,
                                                               preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                // Add the current audio track at the beginning of
                // the asset for the duration of the source AVAsset
                try compositionTrack?.insertTimeRange(track.timeRange,
                                                      of: track,
                                                      at: track.timeRange.start)
            } catch {
                throw error
            }
        }
        
        return composition
    }
}
