//
//  AuthMapper.swift
//  MimoBike
//
//  Created by Vardan on 27.04.21.
//

import Foundation

final class AuthMapper {
    
    static func toLanguageResults(from response: [LanguageResponse], completion: @escaping (Result<[LanguageResult], Error>) -> ()) {
        
        guard let _ = KeychainManager().getAccessToken(), KeychainManager().isUserLoggedIn() else {
            var languageResults = [LanguageResult]()
            
            let selectedLanguageCode = StorageManager().fetch(key: .language, type: String.self) ?? Locale.current.deviceLanguageCode //String(Locale.preferredLanguages[0].prefix(2))
            response.forEach { (languageResponse) in
                if let flag = languageResponse.flag, let flagData = Data(base64Encoded: flag.replacingOccurrences(of: "data:image/png;base64,", with: "")), !flagData.isEmpty {
                    let languageResult = LanguageResult(id: languageResponse.id ?? "", name: languageResponse.name ?? "", flag: flagData, isSelected: languageResponse.id == selectedLanguageCode)
                    languageResults.append(languageResult)
                } else if let flag = languageResponse.flag, let flagData = Data(base64Encoded: flag.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")), !flagData.isEmpty {
                    let languageResult = LanguageResult(id: languageResponse.id ?? "", name: languageResponse.name ?? "", flag: flagData, isSelected: languageResponse.id == selectedLanguageCode)
                    languageResults.append(languageResult)
                }
//                else if let flag = languageResponse.flag, let flagData = Data(base64Encoded: flag.replacingOccurrences(of: "data:image/svg+xml;base64,", with: "")), !flagData.isEmpty {
//                    let languageResult = LanguageResult(id: languageResponse.id ?? "", name: languageResponse.name ?? "", flag: flagData, isSelected: languageResponse.id == selectedLanguageCode)
//                    languageResults.append(languageResult)
//                }
            
            }
            completion(.success(languageResults))
            
            return
        }
        
        var languageResults = [LanguageResult]()
        let selectedLanguageCode = StorageManager().fetch(key: .language, type: String.self) ?? Locale.current.deviceLanguageCode //String(Locale.preferredLanguages[0].prefix(2))
        response.forEach { (languageResponse) in
            if let flag = languageResponse.flag, let flagData = Data(base64Encoded: flag.replacingOccurrences(of: "data:image/png;base64,", with: "").replacingOccurrences(of: "data:image/jpeg;base64,", with: "")), !flagData.isEmpty {
                let languageResult = LanguageResult(id: languageResponse.id ?? "", name: languageResponse.name ?? "", flag: flagData, isSelected: languageResponse.id == selectedLanguageCode)
                languageResults.append(languageResult)
            }
        }
        
        completion(.success(languageResults))
//        UserManager.share.getUser { result in
//            switch result {
//            case .success:
//
//                completion(.success(languageResults)) 
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
    }
}
