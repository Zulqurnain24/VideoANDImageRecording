//
//  Extensions.swift
//  YouVRAssignment
//
//  Created by Mohammad Zulqarnain on 09/07/2019.
//  Copyright © 2019 Mohammad Zulqarnain. All rights reserved.
//

import AVKit
import Vision
import UIKit

// Extension for Orientation
extension UIDeviceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        default: return nil
        }
    }
}

extension UIInterfaceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        default: return nil
        }
    }
}

extension UIImage {
    var ciImage: CIImage? {
        guard let data = self.pngData() else { return nil }
        return CIImage(data: data)
    }
    
    // Face Detection with CIDetector
    var faces: [UIImage] {
        guard let ciImage = ciImage else { return [] }
        return (CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])?
            .features(in: ciImage) as? [CIFaceFeature])?
            .map {
                let ciimage = ciImage.cropped(to: $0.bounds)
                return UIImage(ciImage: ciimage)
            }  ?? []
    }
    
    // Face Detection with Vision Framework
    var faces_Vision: [UIImage] {
        guard let ciImage = ciImage else { return [] }
        
        let faceDetectionRequest = VNDetectFaceRectanglesRequest()
        try! VNImageRequestHandler(ciImage: ciImage).perform([faceDetectionRequest])
        
        guard let results = faceDetectionRequest.results as? [VNFaceObservation] else { return [] }
        
        return results.map {
            let translate = CGAffineTransform.identity.scaledBy(x: size.width, y: size.height)
            let bounds = $0.boundingBox.applying(translate)
            let ciimage = ciImage.cropped(to: bounds)
            return UIImage(ciImage: ciimage)
        }
    }
    
    
}
