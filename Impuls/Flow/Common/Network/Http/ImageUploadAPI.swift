//
//  ImageUploadAPI.swift
//  MimoBike
//
//  Created by Dose on 5/21/21.
//

import UIKit

enum ImageUploadAPI: ImageUplaoder {
    
    case upload(image: UIImage)
    case finish(tripId: String, image: UIImage)
    
    var image: UIImage?  {
        switch self {
        case .upload(image: let image):
            return image
        case let .finish(_, image):
            return image
        }
    }
    
    var base: String {
        switch self {
        case .upload:
            return MimoBaseURLs.accounts.rawValue
        case .finish:
            return MimoBaseURLs.scooter.rawValue
        }
        
    }
    
    var path: String {
        switch self {
        case .upload:
            return "api/user/avatar"
        case let .finish(tripId, _):
            return "api/trip/\(tripId)/finish"
        }
        
    }
    
    var header: [String : String] { [:] }
    
    var query: [String : String] {
        return [:]
    }
    
    var bodyString: String? {
        return nil
    }
    var body: [String : Any]? { nil }
    
    var method: RequestMethod  {
        switch self {
        case .upload:
            return .put
        case .finish:
            return .post
        }
        
    }
    
    var formData: MultipartFormData? {
        return nil
    }
}
