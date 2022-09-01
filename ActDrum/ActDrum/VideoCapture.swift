//
//  VideoCapture.swift
//  ActDrum
//
//  Created by 유정인 on 2022/08/28.
//

import Foundation
import AVFoundation

class VideoCapture: NSObject {
    let captureSession = AVCaptureSession()
    let videoOutput = AVCaptureVideoDataOutput()
    
    // recognize and store data related  to a recognized human body pose within each frame of our video
    // use that data to give us an educated guess on the action that has taken place over the last few frames of that video
    let predictor = Predictor()
    
    override init() {
        super.init()
        
        // default video camera on our phone
        guard let captureDevice = AVCaptureDevice.default(for: .video),
              // take the data from the device
              let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            return
        }
        
        // quality level of our data output to high
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        captureSession.addInput(input)
        captureSession.addOutput(videoOutput)
        
        // frames that are received whlie the queue is already handling another frame are discarded
        videoOutput.alwaysDiscardsLateVideoFrames = true
    }
    
    func startCaptureSession() {
        captureSession.startRunning()
        
        // Add an entry point for that output
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoDispatchQueue"))
    }
}

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        predictor.estimation(sampleBuffer: sampleBuffer)
    }
}
