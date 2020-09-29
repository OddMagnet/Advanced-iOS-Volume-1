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
    var memories = [URL]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        loadMemories()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

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

    func loadMemories() {
        memories.removeAll()

        // try to load all files
        guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(),
                                                                       includingPropertiesForKeys: nil,
                                                                       options: []) else { return }
        // loop over them
        for file in files {
            let filename = file.lastPathComponent

            // only check for thumbnails to avoid duplicates
            if filename.hasSuffix(".thumb") {
                // get just the file name
                let memoryName = filename.replacingOccurrences(of: ".thumb", with: "")
                // create the path for that memory
                let memoryPath = getDocumentsDirectory().appendingPathComponent(memoryName)
                // and add it to the memory array
                memories.append(memoryPath)
            }
        }

        // reload the collection view
        // using reloadSections so the SearchBox in section 0 does not get reloaded
        collectionView.reloadSections(IndexSet(integer: 1))
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
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
