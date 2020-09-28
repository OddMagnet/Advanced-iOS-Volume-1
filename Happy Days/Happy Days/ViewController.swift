//
//  ViewController.swift
//  Happy Days
//
//  Created by Michael Brünen on 25.09.20.
//

import UIKit
import AVFoundation
import Photos
import Speech

class ViewController: UIViewController {
    @IBOutlet weak var helpLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func requestPhotosPermission(_ sender: AnyObject) {
        PHPhotoLibrary.requestAuthorization { [unowned self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.requestRecordPermission()
                } else {
                    self.helpLabel.text = "Photos permission was declined; please enable it in Settings, then tap Continue again."
                }
            }
        }
    }

    func requestRecordPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [unowned self] allowed in
            DispatchQueue.main.async {
                if allowed {
                    self.requestTranscribePermission()
                } else {
                    self.helpLabel.text = "Recording permission was declined; please enable it in Settings, then tap Continue again."
                }
            }
        }
    }

    func requestTranscribePermission() {
        SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.authorizationComplete()
                } else {
                    self.helpLabel.text = "Transcription permission was declined; please enable it in Settings, then tap Continue again."
                }
            }
        }
    }

    func authorizationComplete() {
        dismiss(animated: true)
    }
}

