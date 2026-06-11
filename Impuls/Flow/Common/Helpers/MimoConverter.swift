//
//  MimoConverter.swift
//  MimoBike
//
//  Created by Vardan on 27.04.21.
//

import Foundation

final class MimoConverter<T: Decodable> : NSObject {
    
    static func toJson(data: Any?) -> String {
        
        guard let jsonByte = data as? Data else { return "" }
        
        let jsonString = String(data: jsonByte, encoding: String.Encoding.utf8)
        
        return jsonString ?? ""
    }
    
    static func parseJson(data: Any) -> T? {
        
        do {
            let jsonString = toJson(data: data)
            let jsonData = Data(jsonString.utf8)
            let decoder = JSONDecoder()
            let result = try decoder.decode(T.self, from: jsonData)
            return result
        } catch let error {
            print(error)
            return nil
        }
    }
}
