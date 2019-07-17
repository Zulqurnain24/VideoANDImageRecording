//
//  YouVR_TestUtilityFunctions.swift
//  YouVRAssignmentTests
//
//  Created by Mohammad Zulqarnain on 10/07/2019.
//  Copyright © 2019 Mohammad Zulqarnain. All rights reserved.
//

import XCTest

@testable import YouVRAssignment

class YouVR_TestUtilityFunctions: XCTestCase {

    func testUtilityFunction() {
        checkStringValue( UtilityFunctions.shared.getNowDateString(),  UtilityFunctions.shared.getNowDateString())
    }
    
    // MARK: - private tests
    
    func checkStringValue(_ value: String,  _ actualVal: String) {
        XCTAssertEqual(value, actualVal)
    }
}
