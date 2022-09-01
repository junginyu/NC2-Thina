//
//  ViewController.swift
//  ActDrum
//
//  Created by 유정인 on 2022/08/28.
//

import UIKit
import AVFoundation
import AudioToolbox

class ViewController: UIViewController {
    @IBOutlet weak var previewImageView: UIImageView!
    let videoCapture = VideoCapture()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var pointsLayer = CAShapeLayer()
    var isLeftDetected = false
    var isRightDetected = false

    override func viewDidLoad() {
        print(#function)
        super.viewDidLoad()
        setupVideoPreview()
        print("9")
        videoCapture.predictor.delegate = self
        print("10")
    }
    
    private func setupVideoPreview() {
        print(#function)
        videoCapture.startCaptureSession()
        
        // initialize preview layer using the capture session which is going to automatically receive data
        print("1")
        previewLayer = AVCaptureVideoPreviewLayer(session: videoCapture.captureSession)
        print("2")
        guard let previewLayer = previewLayer else { return }
        print("3")
        view.layer.addSublayer(previewLayer)
        print("4")
        previewLayer.frame = view.frame
        print("5")
        view.layer.addSublayer(pointsLayer)
        print("6")
        pointsLayer.frame = view.frame
        print("7")
        pointsLayer.strokeColor = UIColor.green.cgColor
        print("8")
    }
}

extension ViewController: PredictorDelegate {
    func predictor(_ predictor: Predictor, didLabelAction action: String, with confidence: Double) {
        print(#function)
        if action == "left" && confidence > 0.95 && isLeftDetected == false {
            print("Left foot Detected")
            isLeftDetected = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.isLeftDetected = false
            }
            DispatchQueue.main.async {
                AudioServicesPlayAlertSound(SystemSoundID(1322))
                
                print("왼발!")
            }
            
        } else if action == "right" && confidence > 0.95 && isRightDetected == false {
            print("Right foot Detected")
            isRightDetected = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.isRightDetected = false
            }
            DispatchQueue.main.async {
                AudioServicesPlayAlertSound(SystemSoundID(1321))
                print("오른발!")
            }
        }
    }
    
    func predictor(_ predictor: Predictor, didFindNewRecognizedPoints points: [CGPoint]) {
        print(#function)
        guard let previewLayer = previewLayer else { return }
        
        let convertedPoints = points.map {
            previewLayer.layerPointConverted(fromCaptureDevicePoint: $0)
        }
        let combinedPath = CGMutablePath()
        
        for point in convertedPoints {
            let dotPath = UIBezierPath(ovalIn: CGRect(x: point.x, y: point.y, width: 10, height: 10))
            combinedPath.addPath(dotPath.cgPath)
        }
        
        pointsLayer.path = combinedPath
        
        DispatchQueue.main.async {
            self.pointsLayer.didChangeValue(for: \.path)
        }
    }
}
