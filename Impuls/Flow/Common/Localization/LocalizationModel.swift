//
//  LocalizationModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/3/21.
//

import Foundation

final class LocalizationModel {
    
     var strings: [String: String] = [:]
    private(set) static var shared: LocalizationModel?
    
    @discardableResult
    init(list: [String: String], data: Data) throws {
        guard let contents = try JSONDecoder().decode(BaseResponseModel<[String: String]>.self, from: data).content else { return }
         
        for (key, value) in list {
            let newKey = key.replacingOccurrences(of: "__", with: "_")
            self.strings[newKey] = value
        }
        for (key, value) in contents {
            let newKey = key.replacingOccurrences(of: "__", with: "_")
            self.strings[newKey] = value
        }
        print("contents = \(self.strings)")
        LocalizationModel.shared =  self
    }
    
    private init() {}
    
    func getText(for key: String) -> String {
        return strings[key] ?? key
    }
    
    func getKey(from value: String) -> String {
        return (strings as NSDictionary?)?.allKeys(for: value).first as? String ?? value
    }
}

struct LocalizableContent: Decodable {
    
    let key: String
    let language: String
    let value: String
}
