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

class MemoriesViewController: UICollectionViewController,
                              UIImagePickerControllerDelegate,
                              UINavigationControllerDelegate,
                              UICollectionViewDelegateFlowLayout {
    var memories = [URL]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(addTapped))
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
            print("Calling FirstRun VC")
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


    // MARK: - Collection View
    /// returns 2 sections, since the collection view has a searchbox in the first section
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    /// returns 0 for the first section since that is the searchbox, the other section contains the memories
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0
            ? 0
            : memories.count
    }

    /// returns a cell with the right thumbnail
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // dequeue cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Memory", for: indexPath) as! MemoryCell

        // set it up
        let memory = memories[indexPath.row]
        let thumbnailName = thumbnailURL(for: memory).path
        let thumbnail = UIImage(contentsOfFile: thumbnailName)
        cell.imageView.image = thumbnail

        // and return it
        return cell
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
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
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
