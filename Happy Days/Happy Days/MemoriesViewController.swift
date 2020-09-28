//
//  MemoriesViewController.swift
//  Happy Days
//
//  Created by Michael Brünen on 26.09.20.
//

import UIKit
import AVFoundation
import Photos
import Speech

class MemoriesViewController: UICollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        checkPermissions()
    }

    func checkPermissions() {
        // get status for all needed permissions
        let photosAuthorized = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuthorized = AVAudioSession.sharedInstance().recordPermission == .granted
        let transcribingAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized

        // combine all
        let authorized = photosAuthorized && recordingAuthorized && transcribingAuthorized

        // show first run VC if one or more are missing
        if !authorized {
            print("Calling FirstRun VC")
            if let vc = storyboard?.instantiateViewController(withIdentifier: "FirstRun") {
                navigationController?.present(vc, animated: true)
            }
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
