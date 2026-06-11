//
//  CountryCodeResponse.swift
//  MimoBike
//
//  Created by Vardan on 27.04.21.
//

import Foundation

struct CountryCodeResponse: Codable {
    
    var id: String?
    var country: String?
    var flag: String?
    var code: String?
    var dial_code: String?
    
    var imageFlag: UIImage? {
        
        guard let flag = flag, let data = Data(base64Encoded: flag) else { return nil }
        return UIImage(data: data)
    }
}


