//
//  ContentView.swift
//  Happy Days
//
//  Created by Michael Brünen on 03.10.20.
//

import SwiftUI
import Photos
import Speech

struct ContentView: View {
    @State private var memories = [Memory]()
    @State private var filter = ""
    @State private var filteredMemories = [Memory]()
    @State private var permissionViewShowing = false
    @State private var imagePickerShowing = false
    @State private var selectedImage: UIImage?
    @State private var isRecording = false

    @State private var audioDelegate = AudioRecorder()
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingURL: URL!

    var body: some View {
        NavigationView {
            List {
                TextField("Search...", text: $filter)
                ForEach(filteredMemories) { memory in
                    HStack {
                        Spacer()
                        Image(uiImage: UIImage(contentsOfFile: memory.thumbURL.path)!)
                        Spacer()
                    }
                    .onLongPressGesture(perform: recordMemory)
                    .listRowBackground(isRecording ? Color.red : Color.clear)
                }
            }
            .navigationBarTitle("Happy Days", displayMode: .large)
            .navigationBarItems(trailing: Button(action: addMemory, label: {
                Image(systemName: "plus")
                    .padding()
            }))
            .onAppear(perform: setup)
            .fullScreenCover(isPresented: $permissionViewShowing) {
                PermissionView(permissionsGranted: $permissionViewShowing)
            }
            .sheet(isPresented: $imagePickerShowing, onDismiss: saveNewMemory) {
                ImagePicker(image: self.$selectedImage)
            }
        }
    }

    func setup() {
        recordingURL = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        checkPermissions()
        loadMemories()
    }

    func checkPermissions() {
        // get status for all needed permissions
        let photosAuthorized = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuthorized = AVAudioSession.sharedInstance().recordPermission == .granted
        let transcribingAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized

        // combine all
        let authorized = photosAuthorized && recordingAuthorized && transcribingAuthorized

        // show permission view only if one or more are missing
        permissionViewShowing = !authorized
    }

    func loadMemories() {
        memories.removeAll()

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
                // and a new memory based on that path
                let newMemory = Memory(memoryPath: memoryPath)
                // and add it to the memory array
                memories.append(newMemory)
            }
        }

        // fill filtered memories
        filteredMemories = memories
    }

    func addMemory() {
        self.imagePickerShowing = true
    }

    func saveNewMemory() {
        guard let image = selectedImage else { return }

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

        loadMemories()
    }

    /// Starts the microphone recording
    func recordMemory() {
        // stop audio from playing if needed
        audioPlayer?.stop()

        // Set the recording state
        isRecording = true

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
            audioRecorder?.delegate = audioDelegate
            audioRecorder?.record()
        } catch {
            print("Failed to record: \(error)")
            finishRecording(success: false)
        }
    }

    // MARK: Helper functions
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

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
