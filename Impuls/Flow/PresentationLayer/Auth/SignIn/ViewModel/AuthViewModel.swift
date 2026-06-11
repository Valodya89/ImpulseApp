//
//  AuthViewModel.swift
//  MimoBike
//
//  Created by Vardan on 27.04.21.
//

import UIKit

final class AuthViewModel {
    
    private let authRepository = AuthRepository()
    private let keychainManager = KeychainManager()
    private let storageManager = StorageManager()
    
    
    func signIn(phoneNumber: String, completion: @escaping (Result<(Bool, Bool), NetworkError>) -> Void) {
        
        let deviceID = DeviceCheckManager.shared.deviceUnicToken //UIDevice.current.identifierForVendor?.uuidString
        let phone = phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        
        authRepository.signIn(userId: phone, deviceID: deviceID) { (result) in
            switch result {
            case .success(let response):
                let isDeviceVerified = response.0
                var isAccountComplete = false
                if let signInResponse = response.1, isDeviceVerified {
                    self.keychainManager.parse(from: signInResponse)
                    self.storeAvatar(signInResponse.user?.avatar)
                    isAccountComplete = signInResponse.user?.name != ""
                }
                UserDefaults.standard.set(false, forKey: "isLoogout")
                self.storageManager.store(isAccountComplete, key: .isAccountCompleted)
                self.storageManager.store(phone, key: .phoneNumber)
                completion(.success((isDeviceVerified, isAccountComplete)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func verifyDevice(phoneNumber: String, code: String, completion: @escaping (Result<Bool, AuthErrors>) -> Void) {
        
        let deviceID = DeviceCheckManager.shared.deviceUnicToken //UIDevice.current.identifierForVendor?.uuidString
        let phone = phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        
        authRepository.verifyDevice(userId: phone, deviceID: deviceID, code: code) { (result) in
            switch result {
            case .success(let signInResponse):
                self.keychainManager.parse(from: signInResponse)
                self.storeAvatar(signInResponse.user?.avatar)
                let isAccountComplete = signInResponse.user?.name != nil
                self.storageManager.store(isAccountComplete, key: .isAccountCompleted)
                completion(.success(isAccountComplete))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func storeLanguage(_ language: LanguageResult) {
        storageManager.store(language.id, key: .language)
    }
    
    func getLanguage() -> String {
        let language = storageManager.fetch(key: .language, type: String.self)
        switch language {
        case "English":
            return "en"
        case "Русский":
            return "ru"
        case "Հայերեն":
            return "am"
        case "ru":
            return "ru"
        case  "hy":
            return "am"
        case "en":
            return "en"
        default:
            return String(Locale.preferredLanguages[0].prefix(2))
        }
    }
    
    private func storeAvatar(_ avatar: AvatarResponse?) {
        guard let avatarId = avatar?.id,
              let node = avatar?.node else { return }
        let avatar = "https://\(node).impulsepower.ru/files?id=\(avatarId)&token="
        storageManager.store(avatar, key: .avatar)
    }
}
