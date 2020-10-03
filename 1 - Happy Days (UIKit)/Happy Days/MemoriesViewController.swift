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
import CoreSpotlight
import MobileCoreServices

class MemoriesViewController: UICollectionViewController,
                              UIImagePickerControllerDelegate,
                              UINavigationControllerDelegate,
                              UICollectionViewDelegateFlowLayout,
                              UISearchBarDelegate,
                              AVAudioRecorderDelegate {
    var memories = [URL]()
    var filteredMemories = [URL]()
    var searchQuery: CSSearchQuery?
    var activeMemory: URL!
    var audioRecorder: AVAudioRecorder?
    var recordingURL: URL!
    var audioPlayer: AVAudioPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(addTapped))
        recordingURL = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        loadMemories()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        checkPermissions()
    }


    // MARK: - Preparation
    func checkPermissions() {
        // get status for all needed permissions
        let photosAuthorized = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuthorized = AVAudioSession.sharedInstance().recordPermission == .granted
        let transcribingAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized

        // combine all
        let authorized = photosAuthorized && recordingAuthorized && transcribingAuthorized

        // show first run VC if one or more are missing
        if !authorized {
            if let vc = storyboard?.instantiateViewController(withIdentifier: "FirstRun") {
                navigationController?.present(vc, animated: true)
            }
        }
    }

    /// Loads memories from the users documents directory
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

        // fill filtered memories
        filteredMemories = memories

        // reload the collection view
        // using reloadSections so the SearchBox in section 0 does not get reloaded
        collectionView.reloadSections(IndexSet(integer: 1))
    }


    // MARK: - Creating memories
    /// Creates an UIImagePickerController and presents it
    @objc func addTapped() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.modalPresentationStyle = .formSheet
        imagePickerController.delegate = self
        navigationController?.present(imagePickerController, animated: true)
    }

    /// Handles the users selection of media in the UIImagePickerController
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Dismissing is needed regardless of user selection
        dismiss(animated: true)

        // check if an image was selected and save it as a new memory
        if let image = info[.originalImage] as? UIImage {
            saveNewMemory(image: image)
            loadMemories()
        }
    }

    /// Saves a new memory
    /// - Parameter image: The image to save with the memory
    func saveNewMemory(image: UIImage) {
        // Generate a new, unique name for the memory
        let memoryName = "memory-\(Date().timeIntervalSince1970)"

        // Use the unique name to create filenames for the .jpg and the .thumb
        let imageName = memoryName + ".jpg"
        let thumbName = memoryName + ".thumb"

        do {
            // Try to create an absolute URL
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)

            // Convert the UIImage into JPEG data that can be saved
            if let jpgData = image.jpegData(compressionQuality: 0.8) {
                // Write the data to disk
                try jpgData.write(to: imagePath, options: [.atomicWrite])
            }

            // Create a thumbnail
            if let thumbnail = resize(image: image, to: 200) {
                let thumbnailPath = getDocumentsDirectory().appendingPathComponent(thumbName)
                if let jpgData = thumbnail.jpegData(compressionQuality: 0.8) {
                    try jpgData.write(to: thumbnailPath, options: [.atomicWrite])
                }
            }
        } catch {
            print("Failed to save to disk")
        }
    }

    /// Starts the recording process for a memory
    /// - Parameter sender: The UILongPressGestureRecognizer that called this function
    @objc func memoryLongPress(sender: UILongPressGestureRecognizer) {
        // check if the long press just began or ended
        if sender.state == .began {
            // get the cell that was long pressed
            let cell = sender.view as! MemoryCell

            // get the index for that cell
            if let index = collectionView.indexPath(for: cell) {
                // set the active memory and start the recording
                activeMemory = filteredMemories[index.row]
                recordMemory()
            }

        } else if sender.state == .ended {
            // if it ended, attach the audio to a memory
            finishRecording(success: true)
        }
    }

    /// Starts the microphone recording
    func recordMemory() {
        // stop audio from playing if needed
        audioPlayer?.stop()

        // Set the background color to indicate the microphone is recording
        collectionView?.backgroundColor = UIColor(red: 0.5, green: 0, blue: 0, alpha: 1)

        // create a shared session
        let recordingSession = AVAudioSession.sharedInstance()

        do {
            // Configure the app for both playing and recording audio
            try recordingSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try recordingSession.setActive(true)

            // Set up a recording session using high-quality AAC recording
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            // Create an AVAudioRecorder instance pointing at the recordingURL
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            // Set self as the delegate and start recording
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch {
            print("Failed to record: \(error)")
            finishRecording(success: false)
        }
    }

    /// Links the recording to a memory
    /// - Parameter success: The success status of the recording
    func finishRecording(success: Bool) {
        // reset background color
        collectionView.backgroundColor = UIColor.darkGray

        // stop the audio recorder
        audioRecorder?.stop()

        if success {
            do {
                // create the correct file url
                let memoryAudioURL = audioURL(for: activeMemory)

                let fm = FileManager.default

                // delete previous recording if necessary
                if fm.fileExists(atPath: memoryAudioURL.path) {
                    try fm.removeItem(at: memoryAudioURL)
                }

                // move the recording
                try fm.moveItem(at: recordingURL, to: memoryAudioURL)

                // start the transcribing process
                transcribeAudio(memory: activeMemory)
            } catch {
                print("Failure finishing recording: \(error)")
            }
        }
    }

    /// Transcribes the audio recording of a memory to text
    /// - Parameter memory: The URL of the memory
    func transcribeAudio(memory: URL) {
        // get audio and transcription paths
        let audio = audioURL(for: memory)
        let transcription = transcriptionURL(for: memory)

        // create a speech recognizer and point it at the audio
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "de_DE"))
        let request = SFSpeechURLRecognitionRequest(url: audio)

        // start recognition
        recognizer?.recognitionTask(with: request) { [unowned self] (result, error) in
            // check that there is a result
            guard let result = result else { print("Error while retrieving speech recognition result"); return }

            // check that the result is final
            if result.isFinal {
                // and pull out the best transcription
                let resultText = result.bestTranscription.formattedString

                // and write it to the disk
                do {
                    try resultText.write(to: transcription, atomically: true, encoding: .utf8)
                    self.indexMemory(memory: memory, text: resultText)
                } catch {
                    print("Failed to save transcription: \(error)")
                }
            }
        }
    }

    /// Indexes a memory for spotlight search
    /// - Parameters:
    ///   - memory: The URL to the memory
    ///   - text: The transcription or text to index the memory with
    func indexMemory(memory: URL, text: String) {
        // create attribute set for the memory
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = "Happy Days Memory"
        attributeSet.contentDescription = text
        attributeSet.thumbnailURL = thumbnailURL(for: memory)

        // wrap it as a searchable item
        let item = CSSearchableItem(uniqueIdentifier: memory.path,
                                    domainIdentifier: "io.oddmagnet",
                                    attributeSet: attributeSet)

        // no expiration
        item.expirationDate = .distantFuture

        // and index it
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                print("Indexing error: \(error.localizedDescription)")
            } else {
                print("Search item successfully indexed: \(text)")
            }
        }
    }


    // MARK: - Search
    /// Starts the filtering of memories as soon as the text in the searchbar changes
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterMemories(text: searchText)
    }

    /// Dismisses the keyboard then the searchbar button is tapped
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    /// Filters the memories
    /// - Parameter text: The text to filter for
    func filterMemories(text: String) {
        // ensure the search text is not empty
        guard text.count > 0 else {
            // if it's empty, then reset filtered memories and reload the collectionView
            filteredMemories = memories
            UIView.performWithoutAnimation {
                collectionView.reloadSections(IndexSet(integer: 1))
            }
            return
        }

        // create an empty array
        var matchingItems = [CSSearchableItem]()

        // cancel any eventually running searches
        searchQuery?.cancel()

        // create a query string and the query itself
        let queryString = "contentDescription == \"*\(text)*\"c"
        searchQuery = CSSearchQuery(queryString: queryString, attributes: nil)

        // create a handler for found items
        searchQuery?.foundItemsHandler = { items in
            matchingItems.append(contentsOf: items)
        }

        // and a handler for the finished search
        searchQuery?.completionHandler = { error in
            DispatchQueue.main.async { [unowned self] in
                self.activateFilter(matches: matchingItems)
            }
        }

        // finally, start the query
        searchQuery?.start()
    }

    func activateFilter(matches: [CSSearchableItem]) {
        filteredMemories = matches.map { memory in
            // since the unique identifier for searchable items was the URL to the memory, it's easy to map it back
            return URL(fileURLWithPath: memory.uniqueIdentifier)
        }

        // reload the collection view to show the filtered memories
        UIView.performWithoutAnimation {
            collectionView.reloadSections(IndexSet(integer: 1))
        }
    }


    // MARK: - AVAudio
    /// Checks if recording finished successfully and calls finishRecording() if it wasn't
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }


    // MARK: - Collection View
    /// returns 2 sections, since the collection view has a searchbox in the first section
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    /// returns 0 for the first section since that is the searchbox, the other section contains the memories
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0
            ? 0
            : filteredMemories.count
    }

    /// returns a cell with the right thumbnail
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // dequeue cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Memory", for: indexPath) as! MemoryCell

        // set it up
        let memory = filteredMemories[indexPath.row]
        let thumbnailName = thumbnailURL(for: memory).path
        let thumbnail = UIImage(contentsOfFile: thumbnailName)
        cell.imageView.image = thumbnail

        // check for gesture recognizer and create it if necessary
        if cell.gestureRecognizers == nil {
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(memoryLongPress))
            recognizer.minimumPressDuration = 0.25
            cell.addGestureRecognizer(recognizer)
        }

        // make the cell pretty
        cell.layer.borderColor = UIColor.white.cgColor
        cell.layer.borderWidth = 3
        cell.layer.cornerRadius = 10

        // and return it
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let memory = filteredMemories[indexPath.row]
        let fm = FileManager.default

        do {
            let audioName = audioURL(for: memory)
            let transcriptionName = transcriptionURL(for: memory)

            // check if the audio file exists and play it
            if fm.fileExists(atPath: audioName.path) {
                audioPlayer = try AVAudioPlayer(contentsOf: audioName)
                audioPlayer?.play()
            }

            // check if the transcription exists and print it in the console
            if fm.fileExists(atPath: transcriptionName.path) {
                let contents = try String(contentsOf: transcriptionName)
                print(contents)
            }
        } catch {
            print("Error loading audio: \(error)")
        }
    }

    /// returns the header bar
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
    }

    /// returns no height for all but the search bar section
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return section == 1
            ? CGSize.zero
            : CGSize(width: 0, height: 50)
    }


    // MARK: - Helper functions
    /// Returns the URL for the users documents directory
    /// - Returns: The URL for the users documents directory
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    /// Resizes an Image
    /// - Parameters:
    ///   - image: The UIImage to resize
    ///   - width: The target width
    /// - Returns: An UIImage on success, nil otherwise
    func resize(image: UIImage, to width: CGFloat) -> UIImage? {
        // calculate the scale
        let scale = width / image.size.width

        // calculate the height needed
        let height = image.size.height * scale

        // create a new image context to draw into
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        // draw the original image in it
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        // pull out the resized version
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        // end context for UIKit to clean up
        UIGraphicsEndImageContext()

        // return the resized image
        return resizedImage
    }

    func imageURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("jpg")
    }

    func thumbnailURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("thumb")
    }

    func audioURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("m4a")
    }

    func transcriptionURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("txt")
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
