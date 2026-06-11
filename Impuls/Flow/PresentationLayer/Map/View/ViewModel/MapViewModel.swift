//
//  MapViewModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/6/21.
//

import Foundation

struct MapViewModel {
    
    let accountRepository = AccountRepository()
    private let walletRepository = WalletRepository()
    private let keychainManager = KeychainManager()
    private let storageManager = StorageManager()
    
    func getUser(completion: @escaping (Result<UserResult, Error>) -> Void) {
        accountRepository.getUser { (result) in
            switch result {
            case .success(let userResponse):
                let userResult = AccountMapper.toUserResult(from: userResponse)
                
                completion(.success(userResult))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getAvatar(completion: @escaping (String) -> Void) {
        if let token = keychainManager.getAccessToken(),
           let avatarUrlString = storageManager.fetch(key: .avatar, type: String.self) {
            completion(avatarUrlString + token)
        }
    }
    
    func walletInfo(result: @escaping (Result<WalletModel, WalletRequestErrors>) -> ()) {
        self.walletRepository.getWallet(completion: result)
    }
}
