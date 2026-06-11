//
//  UserManager.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/12/21.
//

import Foundation

final class UserManager {
    
    static let share = UserManager()
    let sessionNetwork = SessionNetwork()
    
    var userResponse: UserResponse?
    var userAccooountResponse: UserResponse?
    var debtState: FinancialStateModel?
    var debtAmount: Double?
    var debtWallets: [WalletDebts]?
    var walletModel: WalletModel?
    var isOpenDebtScreen = true
    var isHaveScooterTrip = false
    var isHaveBikeTrip = false
    
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(accountVerified), name: Constant.Notifications.accountVerified, object: nil)
    }
    
    @objc func accountVerified() {
        userResponse?.emailVerified = true
    }
    
    func getUser(completion: @escaping (Result<UserResponse, Error>) -> ()) {
        if let content = userResponse {
            return completion(.success(content))
        }
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.getUser)) { (result) in
            switch result {
            case .success(let data):
                guard let userResponse = MimoConverter<BaseResponseModel<UserResponse>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                if let content = userResponse.content, userResponse.statusCode == 200 {
                    print("UserResponse === \(userResponse)")
                    self.userResponse = content
                    completion(.success(content))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getAccount(completion: @escaping (Result<UserResponse, Error>) -> ()) {
//        if let content = userAccooountResponse {
//            return completion(.success(content))
//        }
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.getAccount)) { (result) in
            switch result {
            case .success(let data):
                guard let userResponse = MimoConverter<BaseResponseModel<UserResponse>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                if let content = userResponse.content, userResponse.statusCode == 200 {
                    print("UserResponse === \(userResponse)")
                    self.userAccooountResponse = content
                    completion(.success(content))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func updateUser(name: String, surname: String, gender: String, email: String, birthday: String, bio: String, settings: UserResponse.SettingsModel?,completion: @escaping (Result<UserResponse, NetworkError>) -> Void) {
//        let locale = StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))
//        guard let settingsData = try? JSONEncoder().encode(settings ?? UserResponse.SettingsModel(locale: locale, sendPush: true, mode: .light)),
//              let settingsDict = try? JSONSerialization.jsonObject(with: settingsData, options: .fragmentsAllowed) as? [String: Any] else {
//            return completion(.failure(NetworkError.invalidParse("Invalid settings")))
//        }
        
        let locale = StorageManager().fetch(key: .language, type: String.self) ?? Locale.current.deviceLanguageCode
        let settingsData = settings ?? UserResponse.SettingsModel(locale: locale, sendPush: true, mode: .light)
        let settingsDict = settingsData.toDictionary()
        
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.updateUser(name: name, surname: surname, gender: gender.uppercased(), email: email, birthday: birthday, bio: bio, settings: settingsDict))) { (result) in
            switch result {
            case .success(let data):
                guard let userResponse = MimoConverter<BaseResponseModel<UserResponse>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                if let content = userResponse.content, userResponse.statusCode == 200 {
                    self.userResponse = content
                    
                    print("SignInReponse === \(userResponse)")
                    completion(.success(content))
                } else {
                    completion(.failure(NetworkError.invalidParse(userResponse.message)))
                }
            case .failure:
                completion(.failure(NetworkError.responseError("Server Error")))
            }
        }
    }
    
    func updateEmail(new email: String, completion: @escaping (Result<UserResponse, NetworkError>) -> Void) {
        if let userModel = userResponse, let name = userModel.name, let surname = userModel.surname, let gender = userModel.gender, let birthday = userModel.birthday {
            updateUser(name: name, surname: surname, gender: gender, email: email, birthday: birthday, bio: userModel.bio ?? "", settings: userModel.settings, completion: completion)
        } 
    }
    
    func updateSettings(settings: UserResponse.SettingsModel?, completion: @escaping (Result<UserResponse, NetworkError>) -> Void) {
        if let userModel = userResponse, let name = userModel.name, let surname = userModel.surname, let gender = userModel.gender, let birthday = userModel.birthday, let email = userModel.email {
            updateUser(name: name, surname: surname, gender: gender, email: email, birthday: birthday
                       , bio: userModel.bio ?? "", settings: settings, completion: completion)
        } else {
            completion(.failure(NetworkError.serverError))
        }
        
    }
}
