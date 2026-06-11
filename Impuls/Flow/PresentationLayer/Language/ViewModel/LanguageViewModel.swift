//
//  LanguageViewModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/4/21.
//

import Foundation

struct LanguageViewModel {
    
    private let authRepository = AuthRepository()
    
    func getLanguages(completion: (Result<[LanguageResult], Error>) -> ()) {
        authRepository.getLanguages { (result) in
            switch result {
            case .success(let data):
                let languageResult = AuthMapper.toLanguageResults(from: data)
                completion(.success(languageResult))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
