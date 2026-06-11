//
//  MultipartFormData.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 01.06.21.
//

import Foundation

struct Blob {
    let mimeType: String
    let fileName: String
    let data: Data?
}

struct MultipartFormData {
    let parameters: [String: Any]?
    let blob: Blob?
    
    
    func getParameterBoundary() -> Data? {
        guard let params = parameters else { return nil }
        let boundary = "Boundary-\(UUID().uuidString)"
        
        var body = Data()
        let boundaryPrefix = " — \(boundary)\r\n"
        
        for (key, value) in params {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
        
        return body
    }
    
    func getBlobBoundary() -> Data? {
        guard let blob = self.blob,
              let data = blob.data else {
            return nil
        }
        
        var body = Data()
        let boundary = "Boundary-\(UUID().uuidString)"

        body.appendString(boundary)
        body.appendString("Content-Disposition: form-data; name=\"image\"; filename=\"\(blob.fileName)\"\r\n")
        body.appendString("Content-Type: \(blob.mimeType)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
        body.appendString(" — ".appending(boundary.appending(" — ")))
        
        return body
    }
}

extension Data {
    mutating func appendString(_ string: String) {
        let data = string.data(
            using: String.Encoding.utf8,
            allowLossyConversion: true)
        guard let unwrapData = data else {
            return
        }
        
        append(unwrapData)
    }
}
