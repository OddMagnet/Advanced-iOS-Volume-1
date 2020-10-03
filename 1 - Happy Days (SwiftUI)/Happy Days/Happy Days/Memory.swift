//
//  Memor.swift
//  Happy Days
//
//  Created by Michael Brünen on 03.10.20.
//

import Foundation

struct Memory: Identifiable {
    var id = UUID()
    var name: String

    var imageURL: URL {
        return getMemoryBaseURL().appendingPathExtension("jpg")
    }
    var thumbURL: URL {
        return getMemoryBaseURL().appendingPathExtension("thumb")
    }
    var audioURL: URL {
        return getMemoryBaseURL().appendingPathExtension("m4a")
    }
    var transcriptionURL: URL {
        return getMemoryBaseURL().appendingPathExtension("txt")
    }

    private func getMemoryBaseURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(name)
    }
}
