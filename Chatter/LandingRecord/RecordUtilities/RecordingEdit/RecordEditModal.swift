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
    @IBOutlet weak var filtersPickerView: AKPickerView!
    
    var trashDelegate:TrashRecordingDelegate?
    
    var audioID: String?
    
    // Initialize Audio player vars
    var player : AVAudioPlayer?
    var recordedUrl: URL?
    var multiplier: Float?
    var currFilter: String!
    var engine: AVAudioEngine!
    var filterPlayer: AVAudioPlayerNode!
    
    // Initialize Firebase vars
    let storage = Storage.storage()
    var ref: DatabaseReference!
    
    // Image Asset Items (images and labels must be associated)
    var filterImageArr: [UIImage] = [UIImage(named: "Robot")!, UIImage(named: "BadMouth")!, UIImage(named: "Microphone")!, UIImage(named: "SaturnFilter")!, UIImage(named: "RunningMan")!, UIImage(named: "PoopEmoji")!, UIImage(named: "Plus")!]
    var filterLabelArr: [String] = ["Robot", "BadMouth", "Studio", "Normal", "Running", "Poop", "Emoji"]
    var resizedFilterImageArr: [UIImage] = []
    
    var addIntent: String = ""
    
    var friendsList: [LandingRecord.friendItem]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
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
        
        // Initialize normal player
        self.setupPlayer()
        
        // Initialize filter players
        self.currFilter = "Normal"
        self.engine = AVAudioEngine()
        self.filterPlayer = AVAudioPlayerNode()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ChooseAudienceModal
        {
            let vc = segue.destination as? ChooseAudienceModal
            vc?.recordedUrl = self.recordedUrl
            vc?.trashDelegate = self.trashDelegate
            vc?.friendsList = self.friendsList
        }
    }
    
    @IBAction func playRecording(sender: Any) {
        self.animateWaveView(sender: self.recordWaveFormView.subviews[0])
        
        if (self.currFilter == "Normal") {
            self.handleNormalPlayer()
        }   else {
            self.handleFilterPlayer()
        }
    }
    
    func setupPlayer() {
        let url = self.recordedUrl!
        do {
            // AVAudioPlayer setting up with the saved file URL
            let sound = try AVAudioPlayer(contentsOf: url)
            self.player = sound
        } catch {
            print("error setting up player")
            // couldn't load file :(
        }
    }
    
    func resetFilterPlayer() {
        // If in the middle of another play
        self.player?.stop()
        self.engine = AVAudioEngine()
        self.filterPlayer = AVAudioPlayerNode()
    }
    
    func handleNormalPlayer() {
        // If in the middle of another play
        self.player?.stop()
        
        // Here conforming to AVAudioPlayerDelegate
        self.player?.delegate = self
        self.player?.prepareToPlay()
        // Sound.numberOfLoops = -1
        self.player?.play()
    }
    
    func handleFilterPlayer() {
        // Re-setup engine first
        self.engine.stop()
        self.handleFilterSelected(filterID: self.currFilter!)
    
        // Play
        self.filterPlayer.play()
    }
    
    // Actions --------------------------------------------------------------------------------------
    
    @IBAction func closeRecordEdit(_ sender: Any) {
        trashDelegate?.trashRecording()
        self.player?.stop()
        dismiss(animated: true, completion: nil)
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
    
    // Picker Methods ----------------------------------------------------------------
    
    func numberOfItemsInPickerView(_ pickerView: AKPickerView) -> Int {
        return self.resizedFilterImageArr.count
    }
    
    func pickerView(_ pickerView: AKPickerView, imageForItem item: Int) -> UIImage {
        return self.resizedFilterImageArr[item]
    }
    
    func pickerView(_ pickerView: AKPickerView, didSelectItem item: Int) {
        // Set current filter reference
        self.currFilter = self.filterLabelArr[item]
        
        // Add Emoji picker custom handler
        if (self.filterLabelArr[item] == "Emoji" && self.addIntent != "Emoji") {
            self.addIntent = "Emoji"
        }   else if (self.filterLabelArr[item] == "Emoji" && self.addIntent == "Emoji") {
            self.addIntent = ""
            performSegue(withIdentifier: "showEmojiPicker", sender: nil)
        }   else {
            // Other presets, Pass labels to handler
            self.handleFilterSelected(filterID: self.filterLabelArr[item])
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
            let resizedImage = self.resizeImage(image: image, targetSize: CGSize(width: 35, height: 35))
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
    
    func animateWaveView(sender: UIView) {
        
        sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: CGFloat(0.30),
                       initialSpringVelocity: CGFloat(6.0),
                       options: UIViewAnimationOptions.allowUserInteraction,
                       animations: {
                        sender.transform = CGAffineTransform.identity
        },
                       completion: { Void in()  }
        )
    }
}
