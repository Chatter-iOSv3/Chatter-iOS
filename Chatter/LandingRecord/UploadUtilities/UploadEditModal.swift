//
//  UploadModal.swift
//  Chatter
//
//  Created by Austen Ma on 5/8/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

class UploadModalViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    @IBOutlet weak var uploadModalView: UIView!
    @IBOutlet weak var uploadWaveFormView: UIView!
    
    // Initialize Audio player vars
    var player : AVAudioPlayer?
    var uploadedUrl: URL?
    var multiplier: Float?
    
    // Initialize Firebase vars
    let storage = Storage.storage()
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        ref = Database.database().reference()
        
        self.uploadModalView.layer.cornerRadius = 20
        self.uploadWaveFormView.layer.cornerRadius = 20
        
        // Generate Audio Wave form and calculate multiplier
        self.multiplier = self.calculateMultiplierWithAudio(audioUrl: self.uploadedUrl!)
        self.generateWaveForm(audioURL: self.uploadedUrl!)
    }
    
    // Actions -------------------------------------------------------------
    
    @IBAction func closeUpload(_ sender: Any) {
        self.eraseFileUploaded()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func playRecording(sender: Any) {
        let url = self.uploadedUrl!
        do {
            // AVAudioPlayer setting up with the saved file URL
            let sound = try AVAudioPlayer(contentsOf: url)
            self.player = sound
            
            // If in the middle of another play
            sound.stop()
            
            // Here conforming to AVAudioPlayerDelegate
            sound.delegate = self
            sound.prepareToPlay()
            //            sound.numberOfLoops = -1
            sound.play()
        } catch {
            print("error loading file")
            // couldn't load file :(
        }
    }
    
    func eraseFileUploaded() {
        do {
            try FileManager.default.removeItem(at: self.uploadedUrl!)
        } catch {
            print(error)
        }
    }
    
    func generateAudioFile(audioURL: URL, id: String) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        let audioRef = storageRef.child("audio/\(id)")
        audioRef.write(toFile: audioURL) { url, error in
            if let error = error {
                print("****** \(error)")
            } else {
                self.uploadedUrl = url
                
                do {
                    self.player = try AVAudioPlayer(contentsOf: self.uploadedUrl!)
                } catch let error as NSError {
                    //self.player = nil
                    print(error.localizedDescription)
                } catch {
                    print("AVAudioPlayer init failed")
                }
                
            }
        }
    }
    
    func generateWaveForm(audioURL: URL) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let file = try! AVAudioFile(forReading: audioURL)//Read File into AVAudioFile
            let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false)//Format of the file
            
            let buf = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: UInt32(file.length))//Buffer
            try! file.read(into: buf!)//Read Floats
            
            let waveForm = DrawWaveform()
            waveForm.frame.size.width = self.uploadWaveFormView.frame.width
            waveForm.frame.size.height = self.uploadWaveFormView.frame.height
            waveForm.backgroundColor = UIColor(white: 1, alpha: 0.0)
            waveForm.contentMode = .scaleAspectFit
            
            waveForm.multiplier = self.multiplier
            
            //Store the array of floats in the struct
            waveForm.arrayFloatValues = Array(UnsafeBufferPointer(start: buf?.floatChannelData?[0], count:Int(buf!.frameLength)))
            
            self.uploadWaveFormView.addSubview(waveForm)
        }
    }
    
    // OTHER UTILITIES --------------------------------------------------
    
    func calculateMultiplierWithAudio(audioUrl: URL) -> Float {
        let asset = AVURLAsset(url: audioUrl)
        let audioDuration = asset.duration
        let audioDurationSeconds = CMTimeGetSeconds(audioDuration)
        
        return Float(audioDurationSeconds * 9.5)
    }
}
