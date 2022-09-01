//
//  Predictor.swift
//  ActDrum
//
//  Created by 유정인 on 2022/08/28.
//

import Foundation
import Vision
import UIKit
import AVFoundation

typealias DrumActionClassifier = DrumSoundAction

protocol PredictorDelegate: AnyObject {
    func predictor(_ predictor: Predictor, didFindNewRecognizedPoints points: [CGPoint])
    func predictor(_ predictor: Predictor, didLabelAction action: String, with confidence: Double)
}

class Predictor {
    weak var delegate: PredictorDelegate?
    
    let predictionWindowSize = 30
    var posesWindow: [VNHumanBodyPoseObservation] = []
    
    init() {
        posesWindow.reserveCapacity(predictionWindowSize)
    }
    
    func estimation(sampleBuffer: CMSampleBuffer) {
        print(#function)
        let requestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up)
        let request = VNDetectHumanBodyPoseRequest(completionHandler: bodyPoseHandler)
        
        do {
            // MARK: - 오류 발생 1
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform this request, with error: \(error)")
        }
    }
    
    func bodyPoseHandler(request: VNRequest, error: Error?) {
        print(#function)
        guard let observations = request.results as? [VNHumanBodyPoseObservation] else { return }
        
        observations.forEach {
            processObservation($0)
        }
        
        if let result = observations.first {
            print(result)
            storeObservation(result)
            labelActionType()
        }
    }
    
    func labelActionType() {
        print(#function)
        guard let drumActionClassifier = try? DrumSoundAction(configuration: MLModelConfiguration()),
              let poseMultiArray = prepareInputWithObservations(posesWindow) else {
            print("A")
            return
        }
        print("B")
        // MARK: - 오류 2
        guard let predictions = try? drumActionClassifier.prediction(poses: poseMultiArray) else {
            print("C")
            return
        }
        print("D")
        
        let label = predictions.label
        let confidence = predictions.labelProbabilities[label] ?? 0
        
        delegate?.predictor(self, didLabelAction: label, with: confidence)
    }
    
    
    func prepareInputWithObservations(_ observations: [VNHumanBodyPoseObservation]) -> MLMultiArray? {
        print(#function)
        let numAvailbleFrames = observations.count
        let observationsNeeded = 5
        var multiArrayBuffer = [MLMultiArray]()
        
        for frameIndex in 0 ..< min(numAvailbleFrames, observationsNeeded) {
            let pose = observations[frameIndex]
            do {
                print("11")
                let oneFrameMultiArray = try pose.keypointsMultiArray()
                multiArrayBuffer.append(oneFrameMultiArray)
                print("12")
            } catch {
                print("13")
                continue
                
            }
        }
        
        if numAvailbleFrames < observationsNeeded {
            for _ in 0 ..< (observationsNeeded - numAvailbleFrames) {
                do {
                    let oneFrameMultiArray = try MLMultiArray(shape: [5, 3, 18], dataType: .double)
                    try resetMultiArray(oneFrameMultiArray)
                    multiArrayBuffer.append(oneFrameMultiArray)
                } catch {
                    continue
                }
            }
        }
        return MLMultiArray(concatenating: [MLMultiArray](multiArrayBuffer), axis: 0, dataType: .float)
    }
    
    func resetMultiArray(_ predictionWindow: MLMultiArray, with value: Double = 0.0) throws {
        print(#function)
        let pointer = try UnsafeMutableBufferPointer<Double>(predictionWindow)
        pointer.initialize(repeating: value)
    }
    
    func storeObservation(_ observation: VNHumanBodyPoseObservation) {
        print(#function)
        if posesWindow.count >= predictionWindowSize {
            posesWindow.removeFirst()
        }
        posesWindow.append(observation)
    }

    func processObservation(_ observation: VNHumanBodyPoseObservation) {
        print(#function)
        do {
            let recognizedPoints = try observation.recognizedPoints(forGroupKey: .all)
            let displayedPoints = recognizedPoints.map {
                CGPoint(x: $0.value.x, y: 1-$0.value.y)
            }
            delegate?.predictor(self, didFindNewRecognizedPoints: displayedPoints)
        } catch {
            print("Error finding recognizedPoints")
        }
    }
}
