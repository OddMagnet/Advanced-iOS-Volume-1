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
    @State private var permissionViewShowing = false

    var body: some View {
        NavigationView {
            List {
                TextField("Search...", text: $filter)
                ForEach(memories) { memory in
                    VStack {
                        Image(uiImage: UIImage(contentsOfFile: memory.thumbURL.path)!)
                    }
                }
            }
            .navigationBarTitle("Happy Days", displayMode: .large)
            .navigationBarItems(trailing: Button(action: addMemory, label: {
                Image(systemName: "plus")
            }))
            .onAppear(perform: checkPermissions)
            .fullScreenCover(isPresented: $permissionViewShowing) {
                PermissionView(permissionsGranted: $permissionViewShowing)
            }
        }
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

    func addMemory() {

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
