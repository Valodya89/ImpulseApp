//
//  AccountViewModel.swift
//  MimoBike
//
//  Created by Albert on 20.05.21.
//

import Foundation

final class AccountViewModel {
    
    private let accountRepository = AccountRepository()
    private let outhRepository = AuthRepository()
    private let keychainManager = KeychainManager()
    private let storageManager = StorageManager()
    
    func getUser(completion: @escaping (Result<UserResponse, Error>) -> Void) {
        accountRepository.getUser { (result) in
            switch result {
            case .success(let userResponse):
                self.storeAvatar(userResponse.avatar)
                completion(.success(userResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getAvatar(completion: (String) -> Void) {
        if let token = keychainManager.getAccessToken(),
           let avatarUrlString = storageManager.fetch(key: .avatar, type: String.self) {
            completion(avatarUrlString + token)
        }
    }
    
    func logout(complation: @escaping (() -> Void)) {
        outhRepository.logout { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let isOK):
                if isOK {
                    self.storageManager.remove(key: .avatar)
                    self.keychainManager.removeData()
                    UserManager.share.userResponse = nil
                    complation()
                }
            case .failure(let error):
                print("logout failed \(error.localizedDescription)")
            }
        }
    }
    
    func deleteAccount(complation: @escaping (() -> Void)) {
        outhRepository.deleteAccount { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let isOK):
                if isOK {
                    self.storageManager.remove(key: .avatar)
                    self.keychainManager.removeData()
                    UserManager.share.userResponse = nil
                    complation()
                }
            case .failure(let error):
                print("logout failed \(error.localizedDescription)")
            }
        }
    }
    
    private func storeAvatar(_ avatar: AvatarResponse?) {
        guard let avatarId = avatar?.id,
              let node = avatar?.node else { return }
        let avatar = "https://\(node).impulsepower.ru/files?id=\(avatarId)&token="
        storageManager.store(avatar, key: .avatar)
    }
    
    func getPhoneNumber(completion: (String) -> ()) {
        let phoneNumber = storageManager.fetch(key: .phoneNumber, type: String.self) ?? ""
        completion(phoneNumber)
    }
}
