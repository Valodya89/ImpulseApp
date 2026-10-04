//
//  StoryAPI.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.12.23.
//

import Foundation

enum StoryAPI: APIProtocol {
    
    /// `locale` nil asks in the rider's language; a value asks in that language
    /// instead, which is how content missing for the rider's language is found.
    case getStories(locale: String? = nil)
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
        case .getStories(let locale):
            let header = [
                "Content-Type": "application/json",
                "locale": locale ?? Self.riderLocale,
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
    
    /// The language chosen in the app, or the device's when none was chosen.
    static var riderLocale: String {
        StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))
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
