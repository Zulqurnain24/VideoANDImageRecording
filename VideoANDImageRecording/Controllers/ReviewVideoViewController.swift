//
//  File.swift
//  YouVRAssignment
//
//  Created by Mohammad Zulqarnain on 09/07/2019.
//  Copyright © 2019 Mohammad Zulqarnain. All rights reserved.
//

import UIKit
import AVKit
import Photos

class ReviewVideoViewController: UIViewController {
    var videoURL: URL?
    
    @IBOutlet weak var playVideoPreviewButton: UIButton!
    @IBOutlet weak var saveToGalleryButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //assign access identifiers
        playVideoPreviewButton.accessibilityIdentifier = Strings.playVideoPreviewButton.rawValue
        saveToGalleryButton.accessibilityIdentifier = Strings.saveToGalleryButton.rawValue
        shareButton.accessibilityIdentifier = Strings.shareButton.rawValue
        // Do any additional setup after loading the view.
    }
    
    @IBAction func shareVideoAction(_ sender: Any) {
        guard let url = videoURL as URL? else { return }
        let activityItems: [Any] = [url, Strings.currentVideo.rawValue]
        let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        activityController.popoverPresentationController?.sourceView = view
        activityController.popoverPresentationController?.sourceRect = view.frame
        
        self.present(activityController, animated: true, completion: nil)
    }
    @IBAction func saveVideoToGalleryAction(_ sender: Any) {
        guard let url = videoURL as URL? else { return }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { saved, error in
            if saved {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: Strings.yourVideoRecorded.rawValue, message: nil, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: Strings.affirmation.rawValue, style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    @IBAction func playVideoFromURLAction(_ sender: Any) {
        guard let url = videoURL as URL? else { return }
        let player = AVPlayer(url: url)
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true) {
            player.play()
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
