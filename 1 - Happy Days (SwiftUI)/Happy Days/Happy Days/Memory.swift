//
//  Memor.swift
//  Happy Days
//
//  Created by Michael Brünen on 03.10.20.
//

import Foundation

struct Memory: Identifiable {
    var id = UUID()
    var memoryPath: URL

    var imageURL: URL {
        return memoryPath.appendingPathExtension("jpg")
    }
    var thumbURL: URL {
        return memoryPath.appendingPathExtension("thumb")
    }
    var audioURL: URL {
        return memoryPath.appendingPathExtension("m4a")
    }
    var transcriptionURL: URL {
        return memoryPath.appendingPathExtension("txt")
    }
}
