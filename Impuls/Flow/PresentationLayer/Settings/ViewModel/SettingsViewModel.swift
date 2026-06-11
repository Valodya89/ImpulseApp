//
//  SettingsViewModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/4/21.
//

import Foundation

struct SettingsViewModel {
    
    let authRepository = AuthRepository()
    
    func enableNotification(completion: (Result<Bool, Error>) -> ()) {
        completion(.success(true))
    }
    
    func getLanguages(completion: @escaping (Result<[LanguageResult], Error>) -> Void) {
        authRepository.getLanguages { (result) in
            switch result {
            case .success(let data):
                AuthMapper.toLanguageResults(from: data, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func enableDarkMode(completion: (Result<Bool, Error>) -> ()) {
        
    }
}
