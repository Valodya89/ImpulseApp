//
//  StoryAPI.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.12.23.
//

import Foundation

enum StoryAPI: APIProtocol {
    
    case getStories
    case like(id: String)
    case options(id: String, pageNumber: Int, options: [String])
    
    var base: String { MimoBaseURLs.accounts.rawValue }
    
    var path: String {
        switch self {
        case .getStories:
            return "api/stories"
        case let .like(id: id):
            return "api/stories/\(id)/like"
        case let .options(id: id, pageNumber: _, options: _):
            return "api/stories/\(id)/options"
        }
    }
    
    var header: [String : String] {
        switch self {
        case .getStories:
            let header = [
                "Content-Type": "application/json",
                "locale": StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2)),
            ]
            
            return header
        case .options:
            let header = [
                "Content-Type": "application/json",
            ]
            
            return header
        default:
            return [:]
        }
    }
    
    var query: [String : String] { [:] }
    var body: [String : Any]? {
        switch self {
        case let .options(id: _, pageNumber: pageNumber, options: options):
            let params = ["pageNumber": pageNumber, "options": options] as [String : Any]
            return params
        default:
            return nil
        }
    }
    var bodyString: String? { nil }
    var formData: MultipartFormData? { nil }
    
    var method: RequestMethod {
        switch self {
        case .getStories:
            return .get
        case .like, .options:
            return .patch
        }
    }
}
