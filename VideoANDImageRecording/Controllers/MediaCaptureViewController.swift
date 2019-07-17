//
//  ViewController.swift
//  YouVRAssignment
//
//  Created by Mohammad Zulqarnain on 09/07/2019.
//  Copyright © 2019 Mohammad Zulqarnain. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class MediaCaptureViewController: UIViewController {
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var featureExtractionSegmentControl: UISegmentedControl!
    @IBOutlet weak var flashToggleSegmentControl: UISegmentedControl!
    @IBOutlet weak var mediaCaptureTypeSegmentControl: UISegmentedControl!
    @IBOutlet weak var cameraOrientationSegmentControl: UISegmentedControl!

    // VNRequest: Either Retangles or Landmarks
    private var faceDetectionRequest: VNRequest!
    
    // TODO: Decide camera position --- front or back
    private var devicePosition: AVCaptureDevice.Position = .back
    
    private var isFlashOn = false
    
    private var isCaptureingImage = false
    
    // Session Management
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private let session = AVCaptureSession()
    private var isSessionRunning = false
    
    var videoCaptureDevice : AVCaptureDevice?
    
    // Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: Strings.queueName.rawValue, attributes: [], target: nil)
    
    private var setupResult: SessionSetupResult = .success
    
    private var videoDeviceInput:   AVCaptureDeviceInput!
    
    private var videoDataOutput:    AVCaptureVideoDataOutput!
    
    private var audioDataOutput:    AVCaptureAudioDataOutput!
    
    private var videoDataOutputQueue = DispatchQueue(label: Strings.queueLabel.rawValue)
    
    private var requests = [VNRequest]()
    var outputFileLocation: URL?
    var videoWriter: AVAssetWriter?
    var audioWriterInput: AVAssetWriterInput?
    // add video input
    var videoWriterInput: AVAssetWriterInput?
    var isRecording = false
    var sessionAtSourceTime: CMTime?
    let faceLandmarks = VNDetectFaceLandmarksRequest()
    let faceLandmarksDetectionRequest = VNSequenceRequestHandler()
    var mediaURL: URL?
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup default image
        image = UIImage(named: Images.placeHolder.rawValue)
        
        //assign accessibility specifier to record button
        recordButton.accessibilityIdentifier = Strings.accessIdentifierForRecordButton.rawValue
        
        //assign accessibility specifier to toggle media type segment control
        mediaCaptureTypeSegmentControl.accessibilityIdentifier = Strings.accessIdentifierMediaCaptureTypeSegmentControl.rawValue
        
        //assign accessibility specifier to toggle flash segment control
        flashToggleSegmentControl.accessibilityIdentifier = Strings.flashToggleSegmentControl.rawValue
        
        // Set up the video preview view.
        previewView.session = session
        
        // Set up Vision Request
        faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: self.handleFaces) // Default
        setupVision()
        
        /*
         Check video authorization status. Video access is required and audio
         access is optional. If audio access is denied, audio is not recorded
         during movie recording.
         */
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video){
        case .authorized:
            // The user has previously granted access to the camera.
            break
            
        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant
             video access. We suspend the session queue to delay session
             setup until the access request has completed.
             */
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { [unowned self] granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
            
        default:
            // The user has previously denied access.
            setupResult = .notAuthorized
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sessionQueue.async { [unowned self] in
            self.configureSession()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //update UI each time user comes to this viewcontroller
        unHideUI()
        
        sessionQueue.async { [unowned self] in
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session running if setup succeeded.
                self.addObservers()
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                
            case .notAuthorized:
                DispatchQueue.main.async { [unowned self] in
                    let message = NSLocalizedString(Strings.applicationDoesNothavePermission.rawValue, comment: Strings.userDenialToCamera.rawValue)
                    let    alertController = UIAlertController(title: Strings.faceDetection.rawValue, message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString( Strings.affirmation.rawValue, comment: Strings.alertButton.rawValue), style: .cancel, handler: nil))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString(Strings.settings.rawValue, comment: Strings.settings.rawValue), style: .`default`, handler: { action in
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                    }))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                
            case .configurationFailed:
                DispatchQueue.main.async { [unowned self] in
                    let message = NSLocalizedString(Strings.unableToCaptureMedia.rawValue, comment: Strings.alertWhenSomethingGoesWrong.rawValue)
                    let alertController = UIAlertController(title: Strings.faceDetection.rawValue, message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString(Strings.affirmation.rawValue, comment: Strings.alertButton.rawValue), style: .cancel, handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async { [unowned self] in
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
                self.removeObservers()
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = deviceOrientation.videoOrientation, deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                return
            }
            
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
            
        }
    }
    
    func toggleFlash(isFlashOn: Bool) {
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        if (device!.hasTorch) {
            do {
                try device?.lockForConfiguration()
                if (!isFlashOn) {
                    device?.torchMode = AVCaptureDevice.TorchMode.off
                } else {
                    do {
                        try device?.setTorchModeOn(level: 1.0)
                    } catch {
                        print(error)
                    }
                }
                device?.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }
    
    //Toggle flash settings
    @IBAction func UpdateFlashSetting(_ sender: UISegmentedControl) {
        isFlashOn = sender.selectedSegmentIndex == 0 ? true : false
        toggleFlash(isFlashOn: isFlashOn)
    }
    
    //Toggle record type settings
    @IBAction func UpdateRecordingType(_ sender: UISegmentedControl) {
        isCaptureingImage = sender.selectedSegmentIndex == 0 ? true : false
        updateUI()
    }
    
    //Toggle camera orientation settings(i.e. back or front)
    @IBAction func UpdateCameraOrientation(_ sender: UISegmentedControl) {
        devicePosition = sender.selectedSegmentIndex == 0 ? .front : .back
        
        session.removeInput(videoDeviceInput)
        
        guard let camera = getDevice(position: devicePosition) else { return }
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: camera)
        } catch let error as NSError {
            print(error)
            videoDeviceInput = nil
        }
        // Add video input.
        addVideoDataInput()
        
        session.commitConfiguration()

    }
    
    //Get the device (Front or Back)
    func getDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: position)
    }
    
    //open alert for recording video name
    func openAlertWithString(withText: String, completionhandler: ((String) -> Void)? = nil) {
        let alert = UIAlertController(title: Strings.messageTitle.rawValue, message: withText, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.text = Strings.defaultFileName.rawValue
        }
        
        alert.addAction(UIAlertAction(title: Strings.affirmation.rawValue, style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            guard completionhandler != nil else {return}
            completionhandler!(textField?.text! ?? Strings.defaultFileName.rawValue)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func unHideUI() {
        featureExtractionSegmentControl.isHidden = false
        flashToggleSegmentControl.isHidden = false
        mediaCaptureTypeSegmentControl.isHidden = false
        cameraOrientationSegmentControl.isHidden = false
    }
    
    func updateUI() {
        guard isRecording else {
            recordButton.setImage(UIImage(named: isCaptureingImage ? Images.imageCamera.rawValue : Images.videoButtonPressed.rawValue), for: .normal)
            featureExtractionSegmentControl.isHidden = false
            flashToggleSegmentControl.isHidden = false
            mediaCaptureTypeSegmentControl.isHidden = false
            cameraOrientationSegmentControl.isHidden = false
            return }
        recordButton.setImage(UIImage(named: isCaptureingImage ? Images.imageCamera.rawValue : Images.videoButtonUnpressed.rawValue), for: .normal)
        featureExtractionSegmentControl.isHidden = true
        flashToggleSegmentControl.isHidden = true
        mediaCaptureTypeSegmentControl.isHidden = true
        cameraOrientationSegmentControl.isHidden = true
    }
    
    //Record media functionality
    @IBAction func RecordMedia(_ sender: Any) {
        updateUI()
        guard isCaptureingImage else {
        isRecording ? stop() : start()
            return
        }
        self.videoDataOutputQueue.async {
            self.image = nil
        }
    }
    
    // Segmente Control to switch over FaceOnly or FaceLandmark
    @IBAction func UpdateDetectionType(_ sender: UISegmentedControl) {
        faceDetectionRequest = sender.selectedSegmentIndex == 0 ? VNDetectFaceRectanglesRequest(completionHandler: handleFaces) : VNDetectFaceLandmarksRequest(completionHandler: handleFaceLandmarks)
        
        setupVision()
    }
    
    
}

// Video Sessions
extension MediaCaptureViewController {
    private func configureSession() {

        if setupResult != .success { return }
        
        session.beginConfiguration()
        session.sessionPreset = .high
        
        // Add video input.
        addVideoDataInput()
        
        // Add video output.
        addVideoDataOutput()
        
        session.commitConfiguration()
    }
    
    private func addVideoDataInput() {
        do {

            if devicePosition == .front {
                if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
                    videoCaptureDevice = frontCameraDevice
                }
            }
            else {
                // Choose the back dual camera if available, otherwise default to a wide angle camera.
                if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: AVMediaType.video, position: .back) {
                    videoCaptureDevice = dualCameraDevice
                }
                    
                else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
                    videoCaptureDevice = backCameraDevice
                }
            }
            
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoCaptureDevice!)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                DispatchQueue.main.async {
                    /*
                     Why are we dispatching this to the main queue?
                     Because AVCaptureVideoPreviewLayer is the backing layer for PreviewView and UIView
                     can only be manipulated on the main thread.
                     Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                     
                     Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
                     handled by CameraViewController.viewWillTransition(to:with:).
                     */
                    let statusBarOrientation = UIApplication.shared.statusBarOrientation
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if statusBarOrientation != .unknown {
                        if let videoOrientation = statusBarOrientation.videoOrientation {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    self.previewView.videoPreviewLayer.connection!.videoOrientation = initialVideoOrientation
                }
            }
            
        }
        catch {
            print("Could not add video device input to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
    }
    
    private func addVideoDataOutput() {
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32BGRA)]

        if session.canAddOutput(videoDataOutput) {
            videoDataOutput.alwaysDiscardsLateVideoFrames = false
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
            session.addOutput(videoDataOutput)
        }
        else {
            print("Could not add metadata output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
    }
}

// MARK: -- Observers and Event Handlers
extension MediaCaptureViewController {
    private func addObservers() {
        /*
         Observe the previewView's regionOfInterest to update the AVCaptureMetadataOutput's
         rectOfInterest when the user finishes resizing the region of interest.
         */
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: Notification.Name("AVCaptureSessionRuntimeErrorNotification"), object: session)

        NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted), name: Notification.Name("AVCaptureSessionWasInterruptedNotification"), object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded), name: Notification.Name("AVCaptureSessionInterruptionEndedNotification"), object: session)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func sessionRuntimeError(_ notification: Notification) {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else { return }
        
        let error = AVError(_nsError: errorValue)
        print("\(Strings.captureSessionError.rawValue) \(error)")
        
        /*
         Automatically try to restart the session running if media services were
         reset and the last start running succeeded. Otherwise, enable the user
         to try to resume the session running.
         */
        if error.code == .mediaServicesWereReset {
            sessionQueue.async { [unowned self] in
                if self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                }
            }
        }
    }
    
    @objc func sessionWasInterrupted(_ notification: Notification) {
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?, let reasonIntegerValue = userInfoValue.integerValue, let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")
        }
    }
    
    @objc func sessionInterruptionEnded(_ notification: Notification) {
        print("Capture session interruption ended")
    }
}

// MARK: -- Helpers
extension MediaCaptureViewController {
    func setupVision() {
        self.requests = [faceDetectionRequest]
    }
    
    func handleFaces(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            //perform all the UI updates on the main queue
            guard let results = request.results as? [VNFaceObservation] else { return }
            self.previewView.removeMask()
            for face in results {
                self.previewView.drawFaceboundingBox(face: face)
            }
        }
    }
    
    func handleFaceLandmarks(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            //perform all the UI updates on the main queue
            guard let results = request.results as? [VNFaceObservation] else { return }
            self.previewView.removeMask()
            for face in results {
                self.previewView.drawFaceWithLandmarks(face: face)
            }
        }
    }
    
}

// Camera Settings & Orientation
extension MediaCaptureViewController {
    func availableSessionPresets() -> [String] {
        let allSessionPresets = [AVCaptureSession.Preset.photo,
                                 AVCaptureSession.Preset.low,
                                 AVCaptureSession.Preset.medium,
                                 AVCaptureSession.Preset.high,
                                 AVCaptureSession.Preset.cif352x288,
                                 AVCaptureSession.Preset.vga640x480,
                                 AVCaptureSession.Preset.hd1280x720,
                                 AVCaptureSession.Preset.iFrame960x540,
                                 AVCaptureSession.Preset.iFrame1280x720,
                                 AVCaptureSession.Preset.hd1920x1080,
                                 AVCaptureSession.Preset.hd4K3840x2160]
        
        var availableSessionPresets = [String]()
        for sessionPreset in allSessionPresets {
            if session.canSetSessionPreset(sessionPreset) {
                availableSessionPresets.append(sessionPreset.rawValue)
            }
        }
        
        return availableSessionPresets
    }
    
    func exifOrientationFromDeviceOrientation() -> UInt32 {
        enum DeviceOrientation: UInt32 {
            case top0ColLeft = 1
            case top0ColRight = 2
            case bottom0ColRight = 3
            case bottom0ColLeft = 4
            case left0ColTop = 5
            case right0ColTop = 6
            case right0ColBottom = 7
            case left0ColBottom = 8
        }
        var exifOrientation: DeviceOrientation
        
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            exifOrientation = .left0ColBottom
        case .landscapeLeft:
            exifOrientation = devicePosition == .front ? .bottom0ColRight : .top0ColLeft
        case .landscapeRight:
            exifOrientation = devicePosition == .front ? .top0ColLeft : .bottom0ColRight
        default:
            exifOrientation = devicePosition == .front ? .left0ColTop : .right0ColTop
        }
        return exifOrientation.rawValue
    }
    
    func imageFromSampleBuffer(sampleBuffer : CMSampleBuffer) -> UIImage
    {
        // Get a CMSampleBuffer's Core Video image buffer for the media data
        let  imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);
        
        
        // Get the number of bytes per row for the pixel buffer
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer!);
        
        // Get the number of bytes per row for the pixel buffer
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!);
        // Get the pixel buffer width and height
        let width = CVPixelBufferGetWidth(imageBuffer!);
        let height = CVPixelBufferGetHeight(imageBuffer!);
        
        // Create a device-dependent RGB color space
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        
        // Create a bitmap graphics context with the sample buffer data
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        //let bitmapInfo: UInt32 = CGBitmapInfo.alphaInfoMask.rawValue
        let context = CGContext.init(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        // Create a Quartz image from the pixel data in the bitmap graphics context
        let quartzImage = context?.makeImage();
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);
        
        guard let qzImage = quartzImage as CGImage? else {
            return UIImage(named: Images.placeHolder.rawValue)!
        }
        
        // Create an image object from the Quartz image
        let image = UIImage(cgImage: qzImage, scale: 1.0, orientation: .right)
        return (image);
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case RouteTo.imageReview.rawValue:
            let reviewImageViewController = segue.destination as! ReviewImageViewController
            
            self.videoDataOutputQueue.async {
                guard let image = self.image as UIImage? else {return }
                DispatchQueue.main.async {
                    reviewImageViewController.imageView.image = image
                }
            }
        case RouteTo.videoReview.rawValue:
            let reviewVideoViewController = segue.destination as! ReviewVideoViewController
            reviewVideoViewController.videoURL = mediaURL
        case .none:
            break
        case .some(_):
            break
        }
    }
}

// MARK: -  Video recording methods
extension MediaCaptureViewController {
    
    func setUpWriter() {
        openAlertWithString(withText: Strings.enterVideoName.rawValue) { videoName in
            //record video here
            do {
                self.outputFileLocation = self.videoFileLocation(videoName: videoName)
                self.videoWriter = try AVAssetWriter(outputURL: self.outputFileLocation!, fileType: AVFileType.mov)
                
                // add video input
                self.videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: [
                    AVVideoCodecKey : AVVideoCodecType.h264,
                    AVVideoWidthKey : 720,
                    AVVideoHeightKey : 1280,
                    AVVideoCompressionPropertiesKey : [
                        AVVideoAverageBitRateKey : 2300000,
                    ],
                    ])
                
                self.videoWriterInput?.expectsMediaDataInRealTime = true
                
                if (self.videoWriter?.canAdd(self.videoWriterInput!))! {
                    self.videoWriter?.add(self.videoWriterInput!)
                    print("video input added")
                } else {
                    print("no input added")
                }
                
                // add audio input
                self.audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: nil)
                
                self.audioWriterInput?.expectsMediaDataInRealTime = true
                
                if (self.videoWriter?.canAdd(self.audioWriterInput!))! {
                    self.videoWriter?.add(self.audioWriterInput!)
                    print("audio input added")
                }
                
                
                self.videoWriter?.startWriting()
            } catch let error {
                debugPrint(error.localizedDescription)
            }
        }
    }
    
    func canWrite() -> Bool {
        return isRecording && videoWriter != nil && videoWriter?.status == .writing
    }
    
    
    //video file location method
    func videoFileLocation(videoName: String) -> URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let videoOutputUrl = URL(fileURLWithPath: documentsPath.appendingPathComponent(videoName)).appendingPathExtension(Strings.videoExtension.rawValue)
        do {
            if FileManager.default.fileExists(atPath: videoOutputUrl.path) {
                try FileManager.default.removeItem(at: videoOutputUrl)
                print("file removed")
            }
        } catch {
            print(error)
        }
        
        return videoOutputUrl
    }
    
    // MARK: Start recording
    func start() {
        guard !isRecording else { return }
        isRecording = true
        sessionAtSourceTime = nil
        setUpWriter()
        
        if videoWriter?.status == .writing {
            print("status writing")
        } else if videoWriter?.status == .failed {
            print("status failed")
        } else if videoWriter?.status == .cancelled {
            print("status cancelled")
        } else if videoWriter?.status == .unknown {
            print("status unknown")
        } else {
            print("status completed")
        }
        
    }
    
    // MARK: Stop recording
    func stop() {
        guard isRecording else { return }
        isRecording = false
        videoWriterInput?.markAsFinished()
        
        videoWriter?.finishWriting { [weak self] in
            self?.sessionAtSourceTime = nil
            guard let url = self?.videoWriter?.outputURL as URL? else { return }
            self?.mediaURL = url
        }
        
        self.session.stopRunning()
        
        performSegue(withIdentifier: RouteTo.videoReview.rawValue, sender: nil)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension MediaCaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard isCaptureingImage else {
            
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            
            var requestOptions: [VNImageOption : Any] = [:]
            
            if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
                requestOptions = [.cameraIntrinsics : cameraIntrinsicData]
            }
            
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer!, orientation: .up, options: requestOptions)
            
            do {
                
                try imageRequestHandler.perform(requests)
                
                //Video recording logic
                let writable = canWrite()
                
                if writable,
                    sessionAtSourceTime == nil {
                    // start writing
                    sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                    guard let sessionAtST = sessionAtSourceTime as CMTime? else { return }
                    videoWriter?.startSession(atSourceTime: sessionAtST)
                }
                
                if output == videoDataOutput {
                    connection.videoOrientation = .portrait
                    
                    connection.isVideoMirrored = false
                }
                
                if writable,
                    output == videoDataOutput,
                    (videoWriterInput!.isReadyForMoreMediaData) {
                    // write video buffer
                    self.videoWriterInput?.append(sampleBuffer)
                } else if writable,
                    output == audioDataOutput,
                    (audioWriterInput!.isReadyForMoreMediaData) {
                    // write audio buffer
                    audioWriterInput?.append(sampleBuffer)
                }
                
            }
            catch {
                print(error)
            }
            return}
        
        guard let outputImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) as UIImage?, image == nil else {
            return
        }
        videoDataOutputQueue.async {
            self.image = outputImage
        }
        DispatchQueue.main.async {
            self.session.stopRunning()
            self.performSegue(withIdentifier: RouteTo.imageReview.rawValue, sender: nil)
        }
    }
    
   
}
