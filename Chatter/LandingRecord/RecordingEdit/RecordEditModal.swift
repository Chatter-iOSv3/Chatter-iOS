//
//  RecordEditModal.swift
//  Chatter
//
//  Created by Austen Ma on 3/19/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import AudioToolbox
import Firebase
import AKPickerView_Swift

protocol TrashRecordingDelegate
{
    func trashRecording()
}

class RecordEditModal: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate, AKPickerViewDataSource, AKPickerViewDelegate {
    
    @IBOutlet weak var recordEditModalView: UIView!
    @IBOutlet weak var recordWaveFormView: UIView!
    @IBOutlet weak var saveRecordingButton: UIButton!
    @IBOutlet weak var filtersPickerView: AKPickerView!
    
    var trashDelegate:TrashRecordingDelegate?
    
    var audioID: String?
    
    // Initialize Audio player vars
    var player : AVAudioPlayer?
    var recordedUrl: URL?
    var multiplier: Float?
    
    // Initialize Firebase vars
    let storage = Storage.storage()
    var ref: DatabaseReference!
    
    // Image Asset Items
    var filterImageArr: [UIImage] = [UIImage(named: "Robot")!, UIImage(named: "PoopEmoji")!, UIImage(named: "Microphone")!, UIImage(named: "SaturnFilter")!, UIImage(named: "RunningMan")!, UIImage(named: "BadMouth")!, UIImage(named: "Plus")!]
    var resizedFilterImageArr: [UIImage] = []
    var filterLabelArr: [String] = ["Robot", "Poop", "Studio", "Normal", "Running", "BadMouth", "Emoji"]
    
    var addIntent: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        self.audioID = randomString(length: 10)
        
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
    
    // Actions --------------------------------------------------------------------------------------
    
    @IBAction func closeRecordEdit(_ sender: Any) {
        trashDelegate?.trashRecording()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveRecording(sender: AnyObject) {
        print("SAVING")
        
        // Initialize FB storage ref
        let storageRef = storage.reference()
        let userID = Auth.auth().currentUser?.uid
        
        // Get audio url and generate a unique ID for the audio file
        let audioUrl = self.recordedUrl!
        let fullAudioID = "\(userID ?? "") | \(self.audioID)"
        
        // Saving the recording to FB
        let audioRef = storageRef.child("audio/\(fullAudioID)")
        
        audioRef.putFile(from: audioUrl, metadata: nil) { metadata, error in
            if let error = error {
                print(error)
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                //                    let downloadURL = metadata!.downloadURL()
                
                // Write to the ChatterFeed string in FB-DB
                self.ref.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
                    // Retrieve existing ChatterFeed
                    let value = snapshot.value as? NSDictionary
                    let currChatterFeedCount = (value!["chatterFeed"] as AnyObject).count
                    
                    // Generating chatterFeed # identifier
                    var countIdentifier: Int
                    if ((currChatterFeedCount) != nil) {
                        countIdentifier = currChatterFeedCount!
                    }   else {
                        countIdentifier = 0
                    }
                    
                    // Construct new ChatterFeed segment
                    var chatterFeedSegment = Dictionary<String, Any>()
                    chatterFeedSegment = ["id": fullAudioID, "userDetails": userID!, "dateCreated": self.getCurrentDate()]
                    
                    let childUpdates = ["\(countIdentifier)": chatterFeedSegment]
                    
                    // Get the list of followers
                    let follower = value!["follower"] as? NSDictionary
                    
                    // Update your Chatter feed, then feed in all follower
                    self.ref.child("users").child(userID!).child("chatterFeed").updateChildValues(childUpdates) {error, ref in
                        if (follower != nil) {
                            // Iterate through each follower and update their feed
                            for follower in follower! {
                                let followerID = follower.key as? String
                                self.ref.child("users").child(followerID!).child("chatterFeed").observeSingleEvent(of: .value, with: { (followerSnapshot) in
                                    let followerValue = followerSnapshot.value as? Any
                                    let followerChatterFeedCount = (followerValue! as AnyObject).count
                                    
                                    // Generating follower chatterFeed # identifier
                                    var followerCountIdentifier: Int
                                    if ((followerChatterFeedCount) != nil) {
                                        followerCountIdentifier = followerChatterFeedCount!
                                    }   else {
                                        followerCountIdentifier = 0
                                    }
                                    
                                    // Construct follower ChatterFeed segment
                                    var followerChatterFeedSegment = Dictionary<String, Any>()
                                    followerChatterFeedSegment = ["id": fullAudioID, "userDetails": userID!, "dateCreated": self.getCurrentDate()]
                                    
                                    let followerChildUpdates = ["\(followerCountIdentifier)": followerChatterFeedSegment]
                                    
                                    self.ref.child("users").child(followerID!).child("chatterFeed").updateChildValues(followerChildUpdates) {error, ref in
                                        print("UPDATE PROCESS COMPLETE: \(followerID)")
                                    }
                                })
                            }
                        }
                        
                        // Exit the modal
                        print("LOCAL SAVE SUCCESS")
                        self.trashDelegate?.trashRecording()
                        self.performSegue(withIdentifier: "unwindToLandingRecord", sender: self)
                    }
                }) { (error) in
                    print(error.localizedDescription)
                }
            }
        }
    }
    
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
            performSegue(withIdentifier: "showEmojiPicker", sender: nil)
        }
    }
    
    // OTHER UTILITIES --------------------------------------------------
    
    func calculateMultiplierWithAudio(audioUrl: URL) -> Float {
        let asset = AVURLAsset(url: audioUrl)
        let audioDuration = asset.duration
        let audioDurationSeconds = CMTimeGetSeconds(audioDuration)
        
        return Float(audioDurationSeconds * 9.5)
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
    
    func getCurrentDate() -> String {
        let date = Date()
        let formatter = DateFormatter()
        
        formatter.dateFormat = "dd.MM.yyyy"
        
        let result = formatter.string(from: date)
        
        return result
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
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
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
}
