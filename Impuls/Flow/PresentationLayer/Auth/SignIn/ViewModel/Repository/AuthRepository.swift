//
//  AuthRepository.swift
//  MimoBike
//
//  Created by Vardan on 27.04.21.
//

import Foundation
import DeviceCheck

enum AuthErrors: Error {
    
    case invalidPhoneValidatinoCode
    case serverError
    case unknown(description: String)
    
    var localizedDescription: String {
        switch self {
        case .invalidPhoneValidatinoCode:
            return "Wrong verification code. Please, try again."
        case .serverError:
            return "Internal server error. Please, try again."
        case .unknown(description: let text):
            return text
        }
    }
    
    
}

final class AuthRepository {
    
    private let network = SessionNetwork()
    var successCount = 0
    /// Get all country codes
    func getCountryCodes(language: String, completion: @escaping (Result<[CountryCodeResponse], Error>) -> Void) {
                
        network.request(with: URLBuilder(from: AuthAPI.getCountryCode(language))) { (result) in
            switch result {
            case .success(let data):
                guard let countryCodeResponce = MimoConverter<BaseResponseModel<[CountryCodeResponse]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                if let content = countryCodeResponce.content, countryCodeResponce.statusCode == 200 {
                    print("countryCodeResponce === \(countryCodeResponce)")
                    completion(.success(content))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func sendEphemeralToken() {
            //check if DCDevice is available (iOS 11)

            //get the **ephemeral** token
            DCDevice.current.generateToken {
            (data, error) in
            guard let data = data else {
                return
            }

            //send **ephemeral** token to server to
            let token = data.base64EncodedString()
            //Alamofire.request("https://myServer/deviceToken" ...
        }
    }
    
    func getFinancialState(completion: @escaping (Result<FinancialStateModel, MimoError>) -> ()) {
        guard let id = UIDevice.current.identifierForVendor?.uuidString else {
            return
        }
        var token = DeviceCheckManager.shared.deviceUnicToken
        network.request(with: URLBuilder(from: AuthAPI.getFinancialState(deviceID: token))) { (result) in
            switch result {
            case .success(let data):
                print("data = \(data)")
                guard let response = try? JSONDecoder().decode(BaseResponseModel<FinancialStateModel>.self, from: data) else {
                    return completion(.failure(.init(error: .invalidParse("Can not get financial state"))))
                }
                
                if let content = response.content, response.statusCode == 200 {
                    print("Debt = \(content)")
                    return completion(.success(content))
                }
                
                return completion(.failure(MimoError(error: .responseError("Can not get user financial state"))))
            case .failure(let error):
                return completion(.failure(MimoError(error: .responseError(error.description))))
            }
        }
    }
    
    func getState(completion: @escaping (Result<TripActionModel, MimoError>) -> ()) {
        network.request(with: URLBuilder(from: AuthAPI.getState)) { (result) in
            switch result {
            case .success(let data):
                guard let response = try? JSONDecoder().decode(BaseResponseModel<TripActionModel>.self, from: data) else {
                    return completion(.failure(.init(error: .invalidParse("Can not get financial state"))))
                }
                
                if let content = response.content, response.statusCode == 200 {
                    return completion(.success(content))
                }
                
                return completion(.failure(MimoError(error: .responseError("Can not get user financial state"))))
            case .failure(let error):
                return completion(.failure(MimoError(error: .responseError(error.description))))
            }
        }
    }
    
    func getScooterState(completion: @escaping (Result<[ScooterStateModel], MimoError>) -> ()) {
        network.request(with: URLBuilder(from: AuthAPI.getScooterState)) { (result) in
            switch result {
            case .success(let data):
                do {
                 let response = try? JSONDecoder().decode(BaseResponseModel<[ScooterStateModel]>.self, from: data)
                    if let content = response?.content, response?.statusCode == 200 {
                        return completion(.success(content))
                    }
                    
                    return completion(.failure(MimoError(error: .responseError("Can not get user financial state"))))
                } catch let err {
                    print(err)
                    return completion(.failure(.init(error: .invalidParse("Can not get financial state"))))
                }
                
                
            case .failure(let error):
                return completion(.failure(MimoError(error: .responseError(error.description))))
            }
        }
    }
    
    func logout(completion: @escaping (Result<Bool, Error>) -> Void) {
        let id = DeviceCheckManager.shared.deviceUnicToken //UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        network.request(with: URLBuilder(from: AuthAPI.logout( deviceId: id, token: ""))) { (result) in
            switch result {
            case .success(let data):
                UserDefaults.standard.set(true, forKey: "isLoogout")
                guard let signInResponse = MimoConverter<BaseResponseModel<SignInReponse>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                if let content = signInResponse.content, signInResponse.statusCode == 200 {
                    print("SignInReponse === \(signInResponse)")
                    completion(.success(true))
                }
                if signInResponse.statusCode == 412 {
                    completion(.success(false))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func deleteAccount(completion: @escaping (Result<Bool, Error>) -> Void) {
        let id = DeviceCheckManager.shared.deviceUnicToken //UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        network.request(with: URLBuilder(from: AuthAPI.deleteAccount)) { (result) in
            switch result {
            case .success(let data):
                UserDefaults.standard.set(true, forKey: "isLoogout")
                guard let signInResponse = MimoConverter<BaseResponseModel<SignInReponse>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                if let content = signInResponse.content, signInResponse.statusCode == 200 {
                    print("SignInReponse === \(signInResponse)")
                    completion(.success(true))
                }
                if signInResponse.statusCode == 412 {
                    completion(.success(false))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func prevalidate(completion: @escaping (Result<Void, Error>) -> Void) {
        let id = DeviceCheckManager.shared.deviceUnicToken //UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        network.request(with: URLBuilder(from: AuthAPI.preactivate(deviceId: id))) { (result) in
            switch result {
            case .success(let data):
                guard let response = MimoConverter<BaseResponseModel<PreactivateStatusModel>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                
                if let content = response.content, response.statusCode == 200 {
                    switch content.status {
                    case .success:
                        completion(.success(()))
                    case .messageBlocked:
                        completion(.failure(NetworkError.responseError(response.message)))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getGlobalSettings(completion: @escaping (Result<Void, MimoError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getGlobalSettings)) { (result) in
            switch result {
            case .success(let data):
                guard let countryCodeResponce = MimoConverter<BaseResponseModel<GlobalSettings>>.parseJson(data: data as Any) else {
                    completion(.failure(.init(error: .responseError("Can not create global settings"))))
                    
                    return
                }
                if let content = countryCodeResponce.content, countryCodeResponce.statusCode == 200 {
                    GlobalSettings.settings = content
                    print("GlobalSettings.settings = \(GlobalSettings.settings)")
                    completion(.success(()))
                }
            case .failure(let error):
                completion(.failure(.init(error: .responseError(error.localizedDescription))))
            }
        }
    }
    
    /// Get all languages for mimo app
    func getLanguages(completion: @escaping (Result<[LanguageResponse], Error>) -> Void) {
                
        network.request(with: URLBuilder(from: AuthAPI.getLanguage)) { (result) in
            switch result {
            case .success(let data):
                guard let languageResponse = MimoConverter<BaseResponseModel<[LanguageResponse]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                if let content = languageResponse.content, languageResponse.statusCode == 200 {
                    print("languageResponse === \(languageResponse)")
                    completion(.success(content))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getScooterTranslations(language: String, completion: @escaping (Result<[String: String], NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getScoterTranslations(languageCode: language))) { result in
            switch result {
            case .success(let data):
                guard let result = MimoConverter<BaseResponseModel<[String: String]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Invalid Parse")))
                    return
                }
                
                if let translations = result.content, result.statusCode == 200 {
                    completion(.success(translations))
                } else {
                    completion(.failure(.validatorError("Error with code: \(result.statusCode)")))
                }
                
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
    
    func getSharingTranslations(language: String, completion: @escaping (Result<[String: String], NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getSharingTranslations(languageCode: language))) { result in
            switch result {
            case .success(let data):
                guard let result = MimoConverter<BaseResponseModel<[String: String]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Invalid Parse")))
                    return
                }
                
                if let translations = result.content, result.statusCode == 200 {
                    completion(.success(translations))
                } else {
                    completion(.failure(.validatorError("Error with code: \(result.statusCode)")))
                }
                
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
    
    func getChargerTranslations(language: String, completion: @escaping (Result<[String: String], NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getChargerTranslations(languageCode: language))) { result in
            switch result {
            case .success(let data):
                guard let result = MimoConverter<BaseResponseModel<[String: String]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Invalid Parse")))
                    return
                }
                
                if let translations = result.content, result.statusCode == 200 {
                    completion(.success(translations))
                } else {
                    completion(.failure(.validatorError("Error with code: \(result.statusCode)")))
                }
                
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
    
    func getEVChargerTranslations(language: String, completion: @escaping (Result<[String: String], NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getEVChargerTranslations(languageCode: language))) { result in
            switch result {
            case .success(let data):
                guard let result = MimoConverter<BaseResponseModel<[String: String]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Invalid Parse")))
                    return
                }
                
                if let translations = result.content, result.statusCode == 200 {
                    completion(.success(translations))
                } else {
                    completion(.failure(.validatorError("Error with code: \(result.statusCode)")))
                }
                
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
    
    func getMobileTranslations(language: String, completion: @escaping (Result<[String: String], NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getMobileTranslations(languageCode: language))) { result in
            switch result {
            case .success(let data):
                guard let result = MimoConverter<BaseResponseModel<[String: String]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Invalid Parse")))
                    return
                }
                
                if let translations = result.content, result.statusCode == 200 {
                    completion(.success(translations))
                } else {
                    completion(.failure(.validatorError("Error with code: \(result.statusCode)")))
                }
                
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
    
    func getAccountTranslations(language: String, completion: @escaping (Result<[String: String], NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getAccountsTranslations(languageCode: language))) { result in
            switch result {
            case .success(let data):
                guard let result = MimoConverter<BaseResponseModel<[String: String]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Invalid Parse")))
                    return
                }
                
                if let translations = result.content, result.statusCode == 200 {
                    completion(.success(translations))
                } else {
                    completion(.failure(.validatorError("Error with code: \(result.statusCode)")))
                }
                
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
    
    func getiPayTranslations(language: String, completion: @escaping (Result<[String: String], NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getiPayTranslations(languageCode: language))) { result in
            switch result {
            case .success(let data):
                guard let result = MimoConverter<BaseResponseModel<[String: String]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Invalid Parse")))
                    return
                }
                
                if let translations = result.content, result.statusCode == 200 {
                    completion(.success(translations))
                } else {
                    completion(.failure(.validatorError("Error with code: \(result.statusCode)")))
                }
                
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
    
    func getKeyTranslations(lng:  String, completion: @escaping (Result<Void, Error>) -> Void) {
        successCount = 0
        var code = lng
//        getLanguageCode { [weak self] code in
            
            self.network.request(with: URLBuilder(from: AuthAPI.getScoterTranslations(languageCode: code))) { result in
                switch result {
                case .success(let data):
                    do {
                        let val = try LocalizationModel(list: LocalizationModel.shared?.strings ?? [:], data: data)
                        
                        self.successCount += 1
                        print("LocalizationModel scooter")
                        print("scooter = \(val)")
                        if ((self.checkIsAllLanguagesGot()) != nil) {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "translationsGot"), object: nil)
                            completion(.success(()))
                        }
                    } catch {
                        print("err")
                    }
                case .failure(let error):
                    print("Scooter error = \(error)")
//                    completion(.failure(NetworkSessionErrors.unknown(message: "localization error")))
                }
            }
            
            self.network.request(with: URLBuilder(from: AuthAPI.getSharingTranslations(languageCode: code))) { result in
                switch result {
                case .success(let data):
                    do {
                        let val = try LocalizationModel(list: LocalizationModel.shared?.strings ?? [:], data: data)
                        
                        self.successCount += 1
                        print("LocalizationModel sharing")
                        print("sharing = \(val)")
                        if ((self.checkIsAllLanguagesGot()) != nil) {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "translationsGot"), object: nil)
                            completion(.success(()))
                        }
                    } catch {
                        print("err")
                    }
                case .failure(let error):
                    print("Sharing error = \(error)")
//                    completion(.failure(NetworkSessionErrors.unknown(message: "localization error")))
                }
            }
            
            self.network.request(with: URLBuilder(from: AuthAPI.getMobileTranslations(languageCode: code))) { result in
                switch result {
                case .success(let data):
                    do {
                        try LocalizationModel(list: LocalizationModel.shared?.strings ?? [:], data: data)
                        print("LocalizationModel mobille")
                        self.successCount += 1
                        if ((self.checkIsAllLanguagesGot()) != nil) {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "translationsGot"), object: nil)
                            completion(.success(()))
                        }
                    }  catch {
                        print("error")
                    }
                    
                case .failure(let error):
                    print("Mobile error = \(error)")
                    completion(.failure(NetworkSessionErrors.unknown(message: "localization error")))
                }
            }
            
            self.network.request(with: URLBuilder(from: AuthAPI.getAccountsTranslations(languageCode: code))) { result in
                switch result {
                case .success(let data):
                    do {
                        let val = try LocalizationModel(list: LocalizationModel.shared?.strings ?? [:], data: data)
                        print("LocalizationModel account")
                        print("val = \(val)")
                        self.successCount += 1
                        if ((self.checkIsAllLanguagesGot()) != nil) {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "translationsGot"), object: nil)
                            completion(.success(()))
                        }
                    } catch {
                        print("error")
                    }
                case .failure(let error):
                    print("Accounts error = \(error)")
                    completion(.failure(NetworkSessionErrors.unknown(message: "localization error")))
                }
            }
//        }
        
    }
    
    func checkIsAllLanguagesGot() -> Bool {
            return  self.successCount == 4 ? true : false
    }
    
    func getLanguageCode(completed: @escaping (String) -> ()) {
        let languageCode = StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))

        if let token = KeychainManager().getAccessToken() {
            UserManager.share.getUser { result in
                switch result {
                case .success(let user):
                    completed(user.settings?.locale ?? languageCode)
                case .failure:
                    completed(languageCode)
                }
            }
            return
        }
        completed(languageCode)
    }
    
    func getTranslations(completion: @escaping (Result<[LanguageResponse], Error>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getTranslations)) { result in
            switch result {
            case .success(let data):
                guard let languageResponse = MimoConverter<BaseResponseModel<[LanguageResponse]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                print("languageResponse = \(languageResponse)")
                if let content = languageResponse.content, languageResponse.statusCode == 200 {
                    print("languageResponse === \(languageResponse)")
                    completion(.success(content))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// SignIn with phone number and device UUID
    func signIn(userId: String, deviceID: String, completion: @escaping (Result<(Bool, SignInReponse?, OTPMethod?), NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.auth(userId: userId, deviceID: deviceID))) { (result) in
            switch result {
            case .success(let data):
                guard let signInResponse = MimoConverter<BaseResponseModel<SignInReponse>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                if let content = signInResponse.content, signInResponse.statusCode == 200 {
                    print("SignInReponse === \(signInResponse)")
                    completion(.success((true, content, nil)))
                }
                if signInResponse.statusCode == 412 {
                    guard let otpContent = MimoConverter<BaseResponseModel<OTPContent>>.parseJson(data: data as Any) else {
                        completion(.success((false, nil, nil)))
                        return
                    }
                    completion(.success((false, nil, otpContent.content?.method)))
                } else if signInResponse.statusCode == 406 {
                    completion(.failure(NetworkError.invalidParse(signInResponse.message)))
                }
                
            case .failure(let error):
                completion(.failure(NetworkError.invalidParse(error.description)))
            }
        }
    }
    
    /// Verify device with phone number, device UUID and recieved code
    func verifyDevice(userId: String, deviceID: String, code: String, completion: @escaping (Result<SignInReponse, AuthErrors>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.deviceVerification(userId: userId, deviceID: deviceID, code: code))) { (result) in
            switch result {
            case .success(let data):
                guard let signInResponse = MimoConverter<BaseResponseModel<SignInReponse>>.parseJson(data: data as Any) else {
                    completion(.failure(AuthErrors.serverError))
                    return
                }
                if let content = signInResponse.content, signInResponse.statusCode == 200 {
                    print("CodeVerificationResponse === \(signInResponse)")
                    completion(.success(content))
                } else if signInResponse.statusCode == 400 {
                    completion(.failure(.invalidPhoneValidatinoCode))
                } else {
                    completion(.failure(AuthErrors.unknown(description: signInResponse.message)))
                }
            case .failure(let error):
                completion(.failure(.unknown(description: error.localizedDescription)))
            }
        }
    }
    
    /// SignIn with phone number and device UUID
    func sendCodeToEmail(userId: String, deviceID: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.sendCodeToEmail)) { (result) in
            switch result {
            case .success(let data):
                guard let sendCodeToEmailResponse = MimoConverter<BaseResponseModel<EmptyResponse>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                if sendCodeToEmailResponse.statusCode == 200 {
                    print("sendCodeToEmail === \(sendCodeToEmailResponse)")
                    completion(.success(true))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Verify email
    func verifyEmail(userId: String, deviceID: String, code: String, completion: @escaping (Result<CodeVerificationResponse, Error>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.deviceVerification(userId: userId, deviceID: deviceID, code: code))) { (result) in
            switch result {
            case .success(let data):
                guard let codeVerificationResponse = MimoConverter<BaseResponseModel<CodeVerificationResponse>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                if let content = codeVerificationResponse.content, codeVerificationResponse.statusCode == 200 {
                    print("CodeVerificationResponse === \(codeVerificationResponse)")
                    completion(.success(content))
                } else {
                    completion(.failure(NetworkError.serverError))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func isMimoUser(phoneNumber: String, completion: @escaping (Result<MimoUserCheckModel, MimoError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.checkMimoContact(phoneNumber: phoneNumber))) { result in
            switch result {
            case .success(let data):
                do {
                    let responseModel = try JSONDecoder().decode(BaseResponseModel<UserResponse>.self, from: data)
                    let checkModel = MimoUserCheckModel(model: responseModel)
                    completion(.success(checkModel))
                } catch {
                    completion(.failure(.init(error: .invalidParse("Invalid parse"))))
                }
            case .failure(let error):
                completion(.failure(.init(error: .responseError(error.localizedDescription))))
            }
        }
    }
    
    func inviteUser(phoneNumber: String, completion: @escaping (Result<Void, MimoError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.inviteUser(phoneNumber: phoneNumber))) { result in
            switch result {
            case .success(let data):
                do {
                    let responseModel = try JSONDecoder().decode(BaseResponseModel<EmptyResponse>.self, from: data)
                    
                    if responseModel.statusCode == 200 {
                        completion(.success(()))
                        return
                    }
                    
                    return completion(.failure(MimoError(error: .responseError("Can not invite user"))))
                } catch {
                    print("Error happened inviteUser(): \(error)")
                    
                    return completion(.failure(MimoError(error: .responseError("Can not invite user"))))
                }
            case .failure(let error):
                completion(.failure(MimoError(error: NetworkError.responseError(error.localizedDescription))))
            }
        }
    }
    
    func verifyEmailCode(code: String, completion: @escaping (Result<Void, Error>) -> ()) {
        network.request(with: URLBuilder(from: AuthAPI.emailVerification(code: code))) { (result) in
            switch result {
            case .success(let data):
                do {
                    let baseResponseModel = try JSONDecoder().decode(BaseResponseModel<EmptyModel>.self, from: data)
                    
                    if baseResponseModel.statusCode == 200 {
                        return completion(.success(()))
                    }
                    
                    return completion(.failure(NetworkError.validatorError("Failed")))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
