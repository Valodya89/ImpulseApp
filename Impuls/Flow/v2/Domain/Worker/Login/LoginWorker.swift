//
//  LoginWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 17.09.23.
//

import Foundation
import Combine

class LoginWorker: LoginWorkerProtocol {
    
    private let authRepository = AuthRepository()
    private let accountRepository = AccountRepository()
    private let keychainManager = KeychainManager()
    private let storageManager = StorageManager()
    
    var userDataPublisher: AnyPublisher<UserResponse?, Never> { userDataSubject.eraseToAnyPublisher() }
    private var userDataSubject = PassthroughSubject<UserResponse?, Never>()
    
    func signIn(phoneNumber: String) -> AnyPublisher<(Bool, Bool, Bool, OTPMethod?), MimoError> {
        let deviceID = DeviceCheckManager.shared.deviceUnicToken
        let phone = phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        
        return Deferred {
            Future<(Bool, Bool, Bool, OTPMethod?), MimoError> { promise in
                self.authRepository.signIn(userId: phone, deviceID: deviceID) { result in
                    switch result {
                    case .success(let data):
                        let isDeviceVerified = data.0
                        var isAccountComplete = false
                        var isEmailVerified = false
                        let otpMethod: OTPMethod? = data.2
                        if let signInResponse = data.1, isDeviceVerified {
                            self.keychainManager.parse(from: signInResponse)
                            self.storeAvatar(signInResponse.user?.avatar)
                            isAccountComplete = signInResponse.user?.isAccountComplated ?? false
                            isEmailVerified = signInResponse.user?.emailVerified ?? false
                        }
                        self.storageManager.store(isAccountComplete, key: .isAccountCompleted)
                        self.storageManager.store(phone, key: .phoneNumber)
                        self.userDataSubject.send(data.1?.user)
                        promise(.success((isDeviceVerified, isAccountComplete, isEmailVerified, otpMethod)))
                    case .failure(let error):
                        promise(.failure(MimoError(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func verifyDevice(phoneNumber: String, code: String) -> AnyPublisher<SignInReponse, MimoError> {
        let deviceID = DeviceCheckManager.shared.deviceUnicToken
        
        return Deferred {
            Future<SignInReponse, MimoError> { promise in
                self.authRepository.verifyDevice(userId: phoneNumber, deviceID: deviceID, code: code) { result in
                    switch result {
                    case .success(let data):
                        self.keychainManager.parse(from: data)
                        self.userDataSubject.send(data.user)
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(MimoError(error: NetworkError.responseError(error.localizedDescription))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updatePersonalInfo(name: String, surename: String, birthday: String, gender: String, email: String) -> AnyPublisher<UserResponse, MimoError> {
        Deferred {
            Future<UserResponse, MimoError> { promise in
                self.accountRepository.updateUser(
                    name: name,
                    surname: surename,
                    gender: gender,
                    email: email,
                    birthday: birthday,
                    bio: "",
                    settings: UserResponse.SettingsModel(locale: "en", sendPush: true, mode: .light)) { result in
                        switch result {
                        case .success(let data):
                            promise(.success(data))
                        case .failure(let error):
                            promise(.failure(MimoError.init(error: NetworkError.responseError(error.localizedDescription))))
                        }
                    }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func sendEmailCode() -> AnyPublisher<Bool, MimoError> {
        Deferred {
            Future<Bool, MimoError> { promise in
                self.authRepository.sendCodeToEmail(userId: "", deviceID: "") { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(MimoError.init(error: NetworkError.responseError(error.localizedDescription))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getAvailableServices(countryCode: String) -> AnyPublisher<[MimoProductType], MimoError> {
        Deferred {
            Future<[MimoProductType], MimoError> { promise in
                self.accountRepository.getAvailableServices(countryCode: countryCode) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data.compactMap({ service in
                            return MimoProductType.allCases.first(where: { $0.service == service })
                        })))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateAllowedServices(_ services: [String]) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.accountRepository.updateAllowedServices(services: services) { result in
                    switch result {
                    case .success(let success):
                        promise(.success(()))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func storeAvatar(_ avatar: AvatarResponse?) {
        guard let avatarId = avatar?.id,
              let node = avatar?.node else { return }
        let avatar = "https://\(node).impulsepower.ru/files?id=\(avatarId)&token="
        storageManager.store(avatar, key: .avatar)
    }
}
