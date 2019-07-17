//
//  YouVR_TestEnums.swift
//  YouVRAssignmentTests
//
//  Created by Mohammad Zulqarnain on 10/07/2019.
//  Copyright © 2019 Mohammad Zulqarnain. All rights reserved.
//

import XCTest

@testable import YouVRAssignment

class YouVR_TestEnums: XCTestCase {
    
    func testEnums() {
 
        checkStringValue(Strings.promptTitle.rawValue, "Prompt Title")
        checkStringValue(Strings.enterVideoName.rawValue, "Please enter the video name")
        checkStringValue(Strings.enterImageName.rawValue, "Enter image name")
        checkStringValue(Strings.face.rawValue, "Face")
        checkStringValue(Strings.features.rawValue, "Features")
        checkStringValue(Strings.front.rawValue, "Front")
        checkStringValue(Strings.back.rawValue, "Back")
        checkStringValue(Strings.image.rawValue, "image")
        checkStringValue(Strings.video.rawValue, "video")
        checkStringValue(Strings.flash.rawValue, "Flash")
        checkStringValue(Strings.noFlash.rawValue, "No Flash")
        checkStringValue(Strings.videoExtension.rawValue, "mov")
        checkStringValue(Strings.messageTitle.rawValue, "Message")
        checkStringValue(Strings.defaultFileName.rawValue, "YouVRVideo")
        checkStringValue(Strings.affirmation.rawValue, "Ok")
        checkStringValue(Strings.yourVideoRecorded.rawValue, "Your video has been recorded successfully")
        checkStringValue(Strings.unableToSaveVideo.rawValue, "Unable to save video to the gallery")
        checkStringValue(Strings.unableToFindVideo.rawValue, "Unable to find video")
        checkStringValue(Strings.unableToSaveImage.rawValue, "Unable to save the image to the gallery")
        checkStringValue(Strings.yourImageSuccessfullySaved.rawValue, "Your image has successfully been saved to the gallery")
        checkStringValue(Strings.applicationDoesNothavePermission.rawValue, "The Application doesn't have permission to use the camera, please change privacy settings")
        checkStringValue(Strings.userDenialToCamera.rawValue, "Alert message when the user has denied access to the camera")
        checkStringValue(Strings.alertButton.rawValue, "Alert OK button")
        checkStringValue(Strings.settings.rawValue, "Settings")
        checkStringValue(Strings.alertButtonSettings.rawValue, "Alert button to open Settings")
        checkStringValue(Strings.faceDetection.rawValue, "Face Detection")
        checkStringValue(Strings.unableToCaptureMedia.rawValue, "Unable to capture media")
        checkStringValue(Strings.alertWhenSomethingGoesWrong.rawValue, "Alert message when something goes wrong during capture session configuration")
        checkStringValue( Strings.sampleImageURL .rawValue, "https://i.imgur.com/EoB6uEI.jpg")
        checkStringValue(RouteTo.imageReview.rawValue, "RouteToReviewImageViewController")
        checkStringValue(RouteTo.videoReview.rawValue, "RouteToReviewVideoViewController")
        checkStringValue(Images.videoButtonUnpressed.rawValue, "recordButtonUnpressed")
        checkStringValue(Images.videoButtonPressed.rawValue, "recordButtonPressed")
        checkStringValue(Images.imageCamera.rawValue, "cameraButton")
        checkStringValue(Images.placeHolder.rawValue, "placeHolder")
        
    }
    
    // MARK: - private tests
    
    func checkStringValue(_ value: String,  _ actualVal: String) {
        XCTAssertEqual(value, actualVal)
    }

}
