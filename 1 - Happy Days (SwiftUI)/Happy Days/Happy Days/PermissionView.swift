//
//  PermissionView.swift
//  Happy Days
//
//  Created by Michael Brünen on 03.10.20.
//

import SwiftUI
import Photos
import Speech

struct PermissionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var permissionsGranted: Bool
    @State private var alertMessage = ""
    @State private var alertShowing = false

    var body: some View {
        VStack {
            Spacer()
            Text("In order to work fully, Happy Days needs to read your photo library, record your voice, and transcribe what you said. When you click the button below you will be asked to grant those permissions, but you can change your mind later in Settings.")
                .padding()
                .font(.headline)
            Spacer()
            Button("Continue", action: getPermissions)
                .font(.title)
        }
    }

    func getPermissions() {
        getPhotosPermission()
    }

    func getPhotosPermission() {
        PHPhotoLibrary.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.requestRecordPermission()
                } else {
                    alertMessage = "Photos permission was declined; please enable it in Settings, then tap Continue again."
                    alertShowing = true
                }
            }
        }
    }

    func requestRecordPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { allowed in
            DispatchQueue.main.async {
                if allowed {
                    self.requestTranscribePermission()
                } else {
                    alertMessage = "Recording permission was declined; please enable it in Settings, then tap Continue again."
                    alertShowing = true
                }
            }
        }
    }

    func requestTranscribePermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.authorizationComplete()
                } else {
                    alertMessage = "Transcription permission was declined; please enable it in Settings, then tap Continue again."
                    alertShowing = true
                }
            }
        }
    }

    func authorizationComplete() {
        presentationMode.wrappedValue.dismiss()
    }
}

struct PermissionView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionView(permissionsGranted: .constant(false))
    }
}
