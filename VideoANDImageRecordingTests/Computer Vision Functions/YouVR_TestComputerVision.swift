//
//  YouVR_TestComputerVision.swift
//  YouVRAssignmentTests
//
//  Created by Mohammad Zulqarnain on 10/07/2019.
//  Copyright © 2019 Mohammad Zulqarnain. All rights reserved.
//

import XCTest

@testable import YouVRAssignment

class YouVR_TestComputerVision: XCTestCase {

    //Internet has to be on for this test
    func testComputerVision() {
        testFaceBoundingBoxWithVIDetector()
        testFaceBoundingBoxWithCIDetector()
    }
    
    func testFaceBoundingBoxWithVIDetector() {
        let url = URL(string: Strings.sampleImageURL.rawValue)!
            let data = try! Data(contentsOf: url)
            if let image = UIImage(data: data) {

                // Vision
                let faces_v = image.faces_Vision
                print(faces_v.count)
                checkValue(faces_v.count, 2)
        }
    }
    
    func testFaceBoundingBoxWithCIDetector() {
        let url = URL(string: Strings.sampleImageURL.rawValue)!
        let data = try! Data(contentsOf: url)
        if let image = UIImage(data: data) {
            // CIDetector
            let faces = image.faces
            print(faces.count)
            checkValue(faces.count, 2)
        }
    }
    
    private func checkValue(_ value: Int,  _ actualVal: Int) {
        XCTAssertEqual(value, actualVal)
    }
}
