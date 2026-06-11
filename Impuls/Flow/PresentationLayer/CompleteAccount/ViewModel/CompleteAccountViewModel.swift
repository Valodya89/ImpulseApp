//
//  CompleteAccountViewModel.swift
//  MimoBike
//
//  Created by Vardan on 12.05.21.
//

import Foundation

final class CompleteAccountViewModel {
    
    private let completeAccountValidator = CompleteAccountValidator()
    private let accountRepository = AccountRepository()
    private let storageManager = StorageManager()
    
    
    func validate(firstName: String?, lastName: String?, email: String?, dob: Date?, sex: String?, bio: String?, completion: @escaping  (Result<Any, MimoError>) -> ()) {
        
        let dobString = dob?.toString(format: .custom("dd-MM-yyyy"))
        
        let validatorResult = completeAccountValidator.validateCompleteAccount(firstName: firstName, lastName: lastName, email: email, dateOfBirth: dobString, sex: sex, bio: bio)
        
        if validatorResult.isValid {
            completion(.success(""))
        } else {
            completion(.failure(MimoError(error: .validatorError(validatorResult.message))))
        }
    }
    
    func completeAccount(firstName: String?, lastName: String?,
                         email: String?, dob: Date?, sex: UserGender?,
                         bio: String?, settings: UserResponse.SettingsModel,
                         completion: @escaping (Result<UserResult, MimoError>) -> ()) {
        
        let dobString = dob?.toString(format: .custom("dd-MM-yyyy"))
        
        let validatorResult = completeAccountValidator.validateCompleteAccount(firstName: firstName, lastName: lastName, email: email, dateOfBirth: dobString, sex: sex?.rawValue.localized(), bio: bio)
        
        guard validatorResult.isValid else {
            completion(.failure(MimoError(error: .validatorError(validatorResult.message))))
            return
        }
        
        accountRepository.updateUser(name: firstName ?? "", surname: lastName ?? "", gender: (sex ?? UserGender.male).key, email: email ?? "", birthday: dobString ?? "", bio: bio ?? "", settings: settings) { (result) in
            switch result {
            case .success(let userResponse):
                let userResult = AccountMapper.toUserResult(from: userResponse)
                self.storeAvatar(userResponse.avatar)
                let isAccountComplete = userResult.name != ""
                self.storageManager.store(isAccountComplete, key: .isAccountCompleted)
                completion(.success(userResult))
            case .failure(let error):
                completion(.failure(MimoError(error: .responseError(error.localizedDescription))))
            }
        }
    }
    
    func getPhoneNumber(completion: (String) -> ()) {
        let phoneNumber = storageManager.fetch(key: .phoneNumber, type: String.self) ?? ""
        completion(phoneNumber)
    }
    
    private func storeAvatar(_ avatar: AvatarResponse?) {
        guard let avatarId = avatar?.id,
              let node = avatar?.node else { return }
        let avatar = "https://\(node).impulsepower.ru/files?id=\(avatarId)&token="
        storageManager.store(avatar, key: .avatar)
    }
}
