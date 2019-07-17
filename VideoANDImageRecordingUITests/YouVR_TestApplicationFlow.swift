//
//  YouVR_TestApplicationFlow.swift
//  YouVRAssignmentUITests
//
//  Created by Mohammad Zulqarnain on 10/07/2019.
//  Copyright © 2019 Mohammad Zulqarnain. All rights reserved.
//

import XCTest

class YouVR_TestApplicationFlow: XCTestCase {
    var app: XCUIApplication!
    
    // MARK: - XCTestCase
    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = true
        
        app = XCUIApplication()
        
        app.launchArguments.append("--uitesting")
        
    }
    
    // MARK: - Tests
  
    //test toggle flash/no flash camera
    func testCameraButton() {
        //launch app
        app.launch()
        
        // Make sure we're displaying onboarding
        XCTAssertTrue(app.exists)
        let app = XCUIApplication()
        let recordButton = app.buttons["recordButton"]
        recordButton.tap()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
            app.segmentedControls.buttons["Image"].tap()
            recordButton.tap()
        })
    }

}
