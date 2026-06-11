//
//  TarrifAPI.swift
//  MimoBike
//
//  Created by Dose on 6/16/21.
//

import UIKit

enum TarrifAPI: APIProtocol, MultipyImageLoad {
    case activateTarrif(id: String, studentCard: UIImage, selfie: UIImage, phone: String, email: String, university: String, addmisionDate: String, graduationDate: String)
    
    var base: String {
        switch self {
        case .activateTarrif:
            return MimoBaseURLs.sharing.rawValue
        }
    }
    
    
    var path: String {
        switch self {
        case .activateTarrif(let id, _,_,_,_,_,_,_):
            return "api/tariff/\(id)/activate"
        }
    }
    
    var header: [String : String] { [:] }
    
    var query: [String : String] {
        switch self {
        case .activateTarrif(_, _, _, let phone, let email, let university, let addmisionDate, let graduationDate):
            return [
                "phone": phone,
                "email": email,
                "university": university,
                "admissionDate": addmisionDate,
                "graduateDate": graduationDate
            ]
        }
    }
    
    var body: [String : Any]? {
        return nil
//        switch self {
//        case .activateTarrif(_, _, _, let phone, let email, let university, let addmisionDate, let graduationDate):
//            return [
//                "phone": phone,
//                "email": email,
//                "university": university,
//                "admissionDate": addmisionDate,
//                "graduateDate": graduationDate
//            ]
//        }
    }
    
    var bodyString: String? {
        return nil
    }
    
    var formData: MultipartFormData? {
        return nil
    }
    
    var method: RequestMethod  { return .patch }
    
    var images: [(key: String, UIImage)] {
        switch self {
        case .activateTarrif( _, studentCard: let studentImage, selfie: let selfie, phone: _, email: _, university: _, addmisionDate: _, graduationDate: _):
            return [("studentCard",studentImage), ("selfie",selfie)]
        }
    }
    
}
