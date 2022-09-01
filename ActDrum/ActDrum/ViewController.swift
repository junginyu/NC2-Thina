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
    let pointsLayer = CAShapeLayer()
    var isLeftDetected = false
    var isRightDetected = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupVideoPreview()
        videoCapture.predictor.delegate = self
    }
    
    private func setupVideoPreview() {
        videoCapture.startCaptureSession()
        
        // initialize preview layer using the capture session which is going to automatically receive data
        previewLayer = AVCaptureVideoPreviewLayer(session: videoCapture.captureSession)
        
        guard let previewLayer = previewLayer else { return }
        
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        view.layer.addSublayer(pointsLayer)
        pointsLayer.frame = view.frame
        pointsLayer.strokeColor = UIColor.green.cgColor
    }
}

extension ViewController: PredictorDelegate {
    func predictor(_ predictor: Predictor, didLabelAction action: String, with confidence: Double) {
        if action == "left" && confidence > 0.95 && isLeftDetected == false {
            print("Left foot Detected")
            isLeftDetected = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.isLeftDetected = false
            }
            DispatchQueue.main.async {
                AudioServicesPlayAlertSound(SystemSoundID(1322))
            }
            
        } else if action == "right" && confidence > 0.95 && isRightDetected == false {
            print("Right foot Detected")
            isRightDetected = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.isRightDetected = false
            }
            DispatchQueue.main.async {
                AudioServicesPlayAlertSound(SystemSoundID(1321))
            }
        }
    }
    
    func predictor(_ predictor: Predictor, didFindNewRecognizedPoints points: [CGPoint]) {
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
