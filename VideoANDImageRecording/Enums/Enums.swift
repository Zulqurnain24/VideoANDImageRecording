//
//  Enums.swift
//  YouVRAssignment
//
//  Created by Mohammad Zulqarnain on 09/07/2019.
//  Copyright © 2019 Mohammad Zulqarnain. All rights reserved.
//

enum Strings: String {
    
    case promptTitle = "Prompt Title"
    case enterVideoName = "Please enter the video name"
    case enterImageName = "Enter image name"
    case face = "Face"
    case features = "Features"
    case front = "Front"
    case back = "Back"
    case image = "image"
    case video = "video"
    case flash = "Flash"
    case noFlash = "No Flash"
    case videoExtension = "mov"
    case messageTitle = "Message"
    case defaultFileName = "YouVRVideo"
    case affirmation = "Ok"
    case yourVideoRecorded = "Your video has been recorded successfully"
    case unableToSaveVideo = "Unable to save video to the gallery"
    case unableToFindVideo = "Unable to find video"
    case unableToSaveImage = "Unable to save the image to the gallery"
    case yourImageSuccessfullySaved = "Your image has successfully been saved to the gallery"
    case applicationDoesNothavePermission = "The Application doesn't have permission to use the camera, please change privacy settings"
    case userDenialToCamera = "Alert message when the user has denied access to the camera"
    case alertButton = "Alert OK button"
    case settings = "Settings"
    case alertButtonSettings = "Alert button to open Settings"
    case faceDetection = "Face Detection"
    case unableToCaptureMedia = "Unable to capture media"
    case alertWhenSomethingGoesWrong = "Alert message when something goes wrong during capture session configuration"
    case sampleImageURL = "https://i.imgur.com/EoB6uEI.jpg"
    case playVideoPreviewButton = "playVideoPreviewButton"
    case saveToGalleryButton = "saveToGalleryButton"
    case shareButton =  "shareButton"
    case currentVideo = "Current Video"
    case directoryFolderName = "YouVR_Images_Folder"
    case imageNamePostFix = "YouVRImage_"
    case imageShareGalleryname = "Current Image"
    case queueName = "session queue"
    case queueLabel = "VideoDataOutputQueue"
    case accessIdentifierForRecordButton = "recordButton"
    case accessIdentifierMediaCaptureTypeSegmentControl = "mediaCaptureTypeSegmentControl"
    case flashToggleSegmentControl = "flashToggleSegmentControl"
    case captureSessionError = "Capture session runtime error:"
}

enum RouteTo: String {
    case imageReview = "RouteToReviewImageViewController"
    case videoReview = "RouteToReviewVideoViewController"
}

enum Images: String {
    case videoButtonUnpressed = "recordButtonUnpressed"
    case videoButtonPressed = "recordButtonPressed"
    case imageCamera = "cameraButton"
    case placeHolder = "placeHolder"
}
