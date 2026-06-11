//
//  SplashViewModel.swift
//  MimoBike
//
//  Created by Vardan on 26.04.21.
//

import Foundation

final class SplashViewModel {
    
    private let authRepository = AuthRepository()
    private let keychain = KeychainManager()
    private let storageManager = StorageManager()
//    private let socketManager = SocketService.shared

    var socketConnected: Bool {
        return false//socketManager.socketManager.connectionStatus == .fullyConnected || socketManager.socketManager.connectionStatus == .socketConnected
    }
   
    func isUserSignIn() -> Bool {
        return keychain.isUserLoggedIn()
    }
    
    func socketConnected(completion: ((Result<Void, Error>) -> Void)?) {
//        if self.socketConnected {
//            completion?(.success(()))
//
//            return
//        }
//
//        socketManager.connect(completion: completion)
    }
    
    func getFinansialState(completion: @escaping (Result<FinancialStateModel, MimoError>) -> Void) {
        authRepository.getFinancialState(completion: completion)
    }
    
    func getState(completion: @escaping (Result<TripActionModel, MimoError>) -> Void) {
        authRepository.getState(completion: completion)
    }
    
    func getScooterState(completion: @escaping (Result<[ScooterStateModel], MimoError>) -> Void) {
        authRepository.getScooterState(completion: completion)
    }
    
    func getGlobalSettings(completion: @escaping (Result<Void, MimoError>) -> Void) {
        authRepository.getGlobalSettings(completion: completion)
    }
    
    func preactivate(completion: @escaping (Result<Void, Error>) -> Void) {
        authRepository.prevalidate(completion: completion)
    }
    
    func isAccountComplete(completion: @escaping (Bool) -> Void) {
        completion(storageManager.fetch(key: .isAccountCompleted, type: Bool.self) ?? true)
    }
    
    func getLanguages(completion: @escaping (Result<[LanguageResult], Error>) -> Void) {
        
        authRepository.getLanguages { (result) in
            switch result {
            case .success(let data):
                print("translation = ", data)
                AuthMapper.toLanguageResults(from: data, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getTranslations(completion: @escaping (Result<Void, Error>) -> Void) {
        let locale = StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))
        print("locale = \(locale)")
            authRepository.getKeyTranslations(lng: locale) { (result) in
                switch result {
                case .success:
                    print("language success")
                    print("result = \(result)")
                    completion(.success(()))
                case .failure(let error):
                    print("language failure")
                    completion(.failure(error))
                }
            }
    }
}
