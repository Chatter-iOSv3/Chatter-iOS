//
//  DrawWaveForm.swift
//  Chatter
//
//  Created by Austen Ma on 3/7/18.
//  Copyright © 2018 Austen Ma. All rights reserved.
//

import Foundation
import UIKit
import Accelerate

class DrawWaveform: UIView {
    
    var arrayFloatValues:[Float] = []
    var points:[CGFloat] = []
    
    var multiplier: Float?
    
    //This is where we're going to draw the waveform
    override func draw(_ rect: CGRect) {
        //downsample and convert to [CGFloat]
        self.convertToPoints()
        
        var f = 0
        //the waveform on top
        let aPath = UIBezierPath()
        //the waveform on the bottom
        let aPath2 = UIBezierPath()
        
        //lineWidth
        aPath.lineWidth = 3
        aPath2.lineWidth = 3
        
        //start drawing at:
        aPath.move(to: CGPoint(x:0.0 , y:rect.height/2 ))
        aPath2.move(to: CGPoint(x:0.0 , y:rect.height ))
        
        // PLACEHOLDER, SETTING RANDOM COLORS FOR NOW ************************
//        let randomColor = generateRandomColor()
        
        //Loop the array
        for _ in self.points{
            //Distance between points
            var x:CGFloat = 5.0
            //next location to draw
            aPath.move(to: CGPoint(x:aPath.currentPoint.x + x , y:aPath.currentPoint.y ))
            
            //y is the amplitude of each square, 2 is the max height upwards
            var yAmplitude = aPath.currentPoint.y - (self.points[f] * 150) - 1.0
            if (yAmplitude <= 2) {
                yAmplitude = 2
            }
            aPath.addLine(to: CGPoint(x:aPath.currentPoint.x, y:yAmplitude))
            
            aPath.close()
            
            x += 1
            f += 1
        }
        
        aPath.lineJoinStyle = .round
        
        UIColor.white.set()
        aPath.stroke()
        
        //If you want to fill it as well
        aPath.fill()
        
        f = 0
        aPath2.move(to: CGPoint(x:0.0 , y:rect.height/2 ))
        
        //Reflection of waveform
        for _ in self.points{
            var x:CGFloat = 5.0
            aPath2.move(to: CGPoint(x:aPath2.currentPoint.x + x , y:aPath2.currentPoint.y ))
            
            //y is the amplitude of each square, 62 is max height downwards
            var yAmplitude2 = aPath2.currentPoint.y - ((-1.0 * self.points[f]) * 150)
            if (yAmplitude2 > 62.0) {
                yAmplitude2 = 62.0
            }
            aPath2.addLine(to: CGPoint(x:aPath2.currentPoint.x  , y:yAmplitude2))
            
            // aPath.close()
            aPath2.close()
            
            //print(aPath.currentPoint.x)
            x += 1
            f += 1
        }
        
        aPath2.lineJoinStyle = .round
        
        //If you want to stroke it with a Orange color
        UIColor.white.set()
        
        //Reflection and make it transparent
//        aPath2.stroke(with: CGBlendMode.normal, alpha: 0.5)
        aPath2.stroke()
        
        //If you want to fill it as well
        aPath2.fill()
    }
    
    func convertToPoints() {
        var processingBuffer = [Float](repeating: 0.0,
                                       count: Int(self.arrayFloatValues.count))
        let sampleCount = vDSP_Length(self.arrayFloatValues.count)
        //print(sampleCount)
        vDSP_vabs(self.arrayFloatValues, 1, &processingBuffer, 1, sampleCount);
        // print(processingBuffer)
        
        //THIS IS OPTIONAL
        // convert do dB
        //    var zero:Float = 1;
        //    vDSP_vdbcon(floatArrPtr, 1, &zero, floatArrPtr, 1, sampleCount, 1);
        //    //print(floatArr)
        //
        //    // clip to [noiseFloor, 0]
        //    var noiseFloor:Float = -50.0
        //    var ceil:Float = 0.0
        //    vDSP_vclip(floatArrPtr, 1, &noiseFloor, &ceil,
        //                   floatArrPtr, 1, sampleCount);
        //print(floatArr)
        
//        var multiplier = 180.0
//        print(multiplier)
//        if multiplier < 1{
//            multiplier = 1.0
//        }
        
        let samplesPerPixel = Int(75 * self.multiplier!)
        let filter = [Float](repeating: 1.0 / Float(samplesPerPixel),
                             count: Int(samplesPerPixel))
        let downSampledLength = Int(self.arrayFloatValues.count / samplesPerPixel)
        var downSampledData = [Float](repeating:0.0,
                                      count:downSampledLength)
        vDSP_desamp(processingBuffer,
                    vDSP_Stride(samplesPerPixel),
                    filter, &downSampledData,
                    vDSP_Length(downSampledLength),
                    vDSP_Length(samplesPerPixel))
        
        // print(" DOWNSAMPLEDDATA: \(downSampledData.count)")
        
        //convert [Float] to [CGFloat] array
        self.points = downSampledData.map{CGFloat($0)}
        
    }
    
    func generateRandomColor() -> UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from white
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from black
        
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
}
