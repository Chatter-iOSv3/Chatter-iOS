//
//  DirectRecordEditModal.swift
//  Chatter
//
//  Created by Austen Ma on 4/15/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import AudioToolbox
import Firebase
import AKPickerView_Swift

class DirectRecordEditModal: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate, AKPickerViewDataSource, AKPickerViewDelegate {
    
    @IBOutlet weak var recordEditModalView: UIView!
    @IBOutlet weak var recordWaveFormView: UIView!
    @IBOutlet weak var filtersPickerView: AKPickerView!
    
    var audioID: String?
    
    // Initialize Audio player vars
    var player : AVAudioPlayer?
    var recordedUrl: URL?
    var multiplier: Float?
    var chatterRoom: DirectChatterRoomView!
    var chatterRoomID: String!
    
    // Initialize Firebase vars
    let storage = Storage.storage()
    var ref: DatabaseReference!
    var userID: String!
    
    // Image Asset Items
    var filterImageArr: [UIImage] = [UIImage(named: "Robot")!, UIImage(named: "PoopEmoji")!, UIImage(named: "Microphone")!, UIImage(named: "SaturnFilter")!, UIImage(named: "RunningMan")!, UIImage(named: "BadMouth")!, UIImage(named: "Plus")!]
    var resizedFilterImageArr: [UIImage] = []
    var filterLabelArr: [String] = ["Robot", "Poop", "Studio", "Normal", "Running", "BadMouth", "Emoji"]
    
    var addIntent: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        userID = Auth.auth().currentUser?.uid
        
        recordEditModalView.layer.cornerRadius = 20
        recordWaveFormView.layer.cornerRadius = 20
        
        // Initialize Filter pickerView
        self.filtersPickerView.delegate = self
        self.filtersPickerView.dataSource = self
        self.filtersPickerView.interitemSpacing = 50.0
        self.filtersPickerView.layer.backgroundColor = UIColor.clear.cgColor
        
        // Generate Audio Wave form and calculate multiplier
        self.multiplier = self.calculateMultiplierWithAudio(audioUrl: self.recordedUrl!)
        self.generateWaveForm(audioURL: self.recordedUrl!)
        
        // Regulate size of FilterImageArr
        self.sizeControlFilterImageArr()
        self.loadPickerLabelArray()
    }
    
        // Actions --------------------------------------------------------------------------------------
    
    
    @IBAction func playRecording(sender: Any) {
        let url = self.recordedUrl!
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
    
    @IBAction func confirmRecording(sender: AnyObject) {}
    
    @IBAction func animateButton(sender: UIButton) {
        
        sender.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        
        UIView.animate(withDuration: 1.25,
                       delay: 0,
                       usingSpringWithDamping: CGFloat(0.20),
                       initialSpringVelocity: CGFloat(8.0),
                       options: UIViewAnimationOptions.allowUserInteraction,
                       animations: {
                        sender.transform = CGAffineTransform.identity
        },
                       completion: { Void in()  }
        )
    }
    
    @IBAction func closeDirectRecordModal(_ sender: Any) {
        self.player?.stop()
        
        self.chatterRoom.finishedRecording = false
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveDirectRecording(_ sender: Any) {
        // Initialize FB storage ref
        let storageRef = storage.reference()
        self.audioID = self.randomString(length: 10)
        
        // Get audio url and generate a unique ID for the audio file
        let audioUrl = self.recordedUrl!
        let fullAudioID = "\(self.userID ?? "") | \(self.audioID!)"
        
        // Saving the recording to FB
        let audioRef = storageRef.child("audio/\(fullAudioID)")
        
        self.chatterRoom.finishedRecording = false
        
        audioRef.putFile(from: audioUrl, metadata: nil) { metadata, error in
            if let error = error {
                print(error)
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                //                    let downloadURL = metadata!.downloadURL()
                
                self.ref.child("chatterRooms").child(self.chatterRoomID).child("chatterRoomSegments").observeSingleEvent(of: .value, with: { (snapshot) in
                    let timestamp = String(Int(NSDate().timeIntervalSince1970))
                    
                    let asset = AVURLAsset(url: audioUrl)
                    let audioDuration = asset.duration
                    let audioDurationSeconds = Float(CMTimeGetSeconds(audioDuration))
                    
                    let childUpdates = [timestamp: ["fullAudioID": fullAudioID, "duration": String(audioDurationSeconds), "readStatus": "unread"]]
                    
                    self.ref.child("chatterRooms").child(self.chatterRoomID).child("chatterRoomSegments").updateChildValues(childUpdates) {error, ref in
                        self.dismiss(animated: true, completion: nil)
                        print("UPDATE PROCESS COMPLETE: \(childUpdates)")
                    }
                })
            }
        }
    }
    
    // Waveform Methods -------------------------------------------------------
    
    func generateAudioFile(audioURL: URL, id: String) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        let audioRef = storageRef.child("audio/\(id)")
        audioRef.write(toFile: audioURL) { url, error in
            if let error = error {
                print("****** \(error)")
            } else {
                self.recordedUrl = url
                
                do {
                    self.player = try AVAudioPlayer(contentsOf: self.recordedUrl!)
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
            waveForm.frame.size.width = self.recordWaveFormView.frame.width
            waveForm.frame.size.height = self.recordWaveFormView.frame.height
            waveForm.backgroundColor = UIColor(white: 1, alpha: 0.0)
            waveForm.contentMode = .scaleAspectFit
            
            waveForm.multiplier = self.multiplier
            
            //Store the array of floats in the struct
            waveForm.arrayFloatValues = Array(UnsafeBufferPointer(start: buf?.floatChannelData?[0], count:Int(buf!.frameLength)))
            
            self.recordWaveFormView.addSubview(waveForm)
        }
    }
    
    // View Methods ----------------------------------------------------------------
    
    func numberOfItemsInPickerView(_ pickerView: AKPickerView) -> Int {
        return self.resizedFilterImageArr.count
    }
    
    func pickerView(_ pickerView: AKPickerView, imageForItem item: Int) -> UIImage {
        return self.resizedFilterImageArr[item]
    }
    
    func pickerView(_ pickerView: AKPickerView, didSelectItem item: Int) {
        // Temporary: TODO -> Refer to notes
        if (item == 6 && self.addIntent != 6) {
            self.addIntent = 6
        }   else if (item == 6 && self.addIntent == 6) {
            self.addIntent = 0
            performSegue(withIdentifier: "showDirectEmojiPicker", sender: nil)
        }
    }
    
    // OTHER UTILITIES --------------------------------------------------
    
    func calculateMultiplierWithAudio(audioUrl: URL) -> Float {
        let asset = AVURLAsset(url: audioUrl)
        let audioDuration = asset.duration
        let audioDurationSeconds = CMTimeGetSeconds(audioDuration)
        
        return Float(audioDurationSeconds * 9.5)
    }
    
    func sizeControlFilterImageArr() {
        for image in self.filterImageArr {
            var resizedImage = self.resizeImage(image: image, targetSize: CGSize(width: 35, height: 35))
            self.resizedFilterImageArr.append(resizedImage)
        }
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
    
    func loadPickerLabelArray() {
        for label in self.filterLabelArr {
            self.filtersPickerView.labelArray.append(label)
        }
    }
    
    func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
}
