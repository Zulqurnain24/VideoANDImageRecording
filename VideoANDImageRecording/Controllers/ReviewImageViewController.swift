//
//  ReviewImageViewController.swift
//  YouVRAssignment
//
//  Created by Mohammad Zulqarnain on 09/07/2019.
//  Copyright © 2019 Mohammad Zulqarnain. All rights reserved.
//

import UIKit

class ReviewImageViewController: UIViewController {
    @IBOutlet weak var saveToGalleryButton: UIButton!
    
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    var imageURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Assign access identifiers
        saveToGalleryButton.accessibilityIdentifier = Strings.saveToGalleryButton.rawValue
        shareButton.accessibilityIdentifier = Strings.shareButton.rawValue
        // Do any additional setup after loading the view.
    }
    
    func saveImageDocumentDirectoryAndReturnURL(image: UIImage, imageName: String) -> NSURL? {
        let fileManager = FileManager.default
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(Strings.directoryFolderName.rawValue)
        if !fileManager.fileExists(atPath: path) {
            try! fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        let url = NSURL(string: path)
        let imagePath = url!.appendingPathComponent(imageName)
        let urlString: String = imagePath!.absoluteString
        let imageData = image.pngData()
        fileManager.createFile(atPath: urlString as String, contents: imageData, attributes: nil)
        return url
    }
    
    @IBAction func shareImageAction(_ sender: Any) {
         guard let image = imageView.image as UIImage? else { return }
        self.imageURL = self.saveImageDocumentDirectoryAndReturnURL(image: image, imageName: "\(Strings.imageNamePostFix.rawValue)\(UtilityFunctions.shared.getNowDateString().trimmingCharacters(in: .whitespaces))") as URL?
        guard let url = imageURL as URL?, let urlString = "file://\(imageURL?.absoluteString)" as! String? else { return }
        print("url: \(urlString)")
        let activityItems: [Any] = [URL(string: urlString), Strings.imageShareGalleryname.rawValue]
        let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        activityController.popoverPresentationController?.sourceView = view
        activityController.popoverPresentationController?.sourceRect = view.frame
        
        self.present(activityController, animated: true, completion: nil)
    }
    
    @IBAction func saveImageToGalleryAction(_ sender: Any) {
        guard let image = imageView.image as UIImage? else { return }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    //MARK: - Add image to Library
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            // we got back an error!
            let ac = UIAlertController(title: Strings.messageTitle.rawValue, message:  Strings.unableToSaveImage.rawValue, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: Strings.affirmation.rawValue, style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: Strings.messageTitle.rawValue, message:  Strings.yourImageSuccessfullySaved.rawValue, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: Strings.affirmation.rawValue, style: .default))
            present(ac, animated: true)
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
