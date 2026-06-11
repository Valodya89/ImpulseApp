//
//  WalletRepository.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 02.06.21.
//

import Foundation
import AudioToolbox

enum WalletRequestErrors: Error {
    case custom(message: String)
    case internalError
    case parseError
    
    var localizedDescription: String {
        switch self {
        case .custom(message: let message):
            return message
        
        default:
            return "Internal error".localized()
        }
    }
}

final class WalletRepository {
    
    private let network = SessionNetwork()
    
    /// Get all country codes
    func getWallet(completion: @escaping (Result<WalletModel, WalletRequestErrors>) -> Void) {
        
        network.request(with: URLBuilder(from: AuthAPI.getWallet)) { (result) in
            switch result {
            case .success(let data):
                guard let countryCodeResponce = MimoConverter<BaseResponseModel<WalletModel>>.parseJson(data: data as Any) else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(WalletRequestErrors.parseError))
                    return
                }
                if let content = countryCodeResponce.content, countryCodeResponce.statusCode == 200 {
                    print("countryCodeResponce === \(countryCodeResponce)")
                    UserManager.share.walletModel = content
                    completion(.success(content))
                } else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: countryCodeResponce.message)))
                }
            case .failure(let error):
                print("WalletRepository.getWallet failed: \(error.localizedDescription)")
                VibrateEffectManager.shared.errorVibration()
                completion(.failure(.internalError))
            }
        }
    }

    func getPaymentMethods(completion: @escaping (Result<[PaymentMethodModel], WalletRequestErrors>) -> Void) {
        
        network.request(with: URLBuilder(from: AuthAPI.getPaymentMethods)) { (result) in
            switch result {
            case .success(let data):
                guard let paymentMethodsResponce = MimoConverter<BaseResponseModel<[PaymentMethodModel]>>.parseJson(data: data as Any) else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(WalletRequestErrors.parseError))
                    return
                }
                if let content = paymentMethodsResponce.content, paymentMethodsResponce.statusCode == 200 {
                    print("paymentMethodsResponce === \(paymentMethodsResponce)")
//                    UserManager.share.walletModel = content
                    completion(.success(content))
                } else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: paymentMethodsResponce.message)))
                }
            case .failure(let error):
                VibrateEffectManager.shared.errorVibration()
                completion(.failure(.internalError))
            }
        }
    }
    
    
    func checkPromoStatus(completion: @escaping (Result<PromoStatus, WalletRequestErrors>) -> Void) {
        
        network.request(with: URLBuilder(from: AuthAPI.checkPromoStatus)) { (result) in
            switch result {
            case .success(let data):
                guard let countryCodeResponce = MimoConverter<BaseResponseModel<PromoStatus>>.parseJson(data: data as Any) else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(WalletRequestErrors.parseError))
                    return
                }
                if let content = countryCodeResponce.content, countryCodeResponce.statusCode == 200 {
                    print("countryCodeResponce === \(countryCodeResponce)")
                    completion(.success(content))
                } else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: countryCodeResponce.message)))
                }
            case .failure(let error):
                print("WalletRepository.checkPromoStatus failed: \(error.localizedDescription)")
                VibrateEffectManager.shared.errorVibration()
                completion(.failure(.internalError))
            }
        }
    }


    func attachCard(provider: String, _ completion: @escaping (Result<AttachCardModel, WalletRequestErrors>) -> Void ) {
        
        network.request(with: URLBuilder(from: AuthAPI.attachCard(provider: provider))) { (result) in
            switch result {
            case .success(let data):
                guard let countryCodeResponce = MimoConverter<BaseResponseModel<AttachCardModel>>.parseJson(data: data as Any) else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.parseError))
                    return
                }
                if let content = countryCodeResponce.content, countryCodeResponce.statusCode == 200 {
                    completion(.success(content))
                } else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: countryCodeResponce.message)))
                }
            case .failure(let error):
                print("WalletRepository.attachCard failed: \(error.localizedDescription)")
                VibrateEffectManager.shared.errorVibration()
                completion(.failure(.internalError))
            }
        }
    }

    // Fix This model
    
    func depositFromAttachedCard(_ ammout: Double, _ completion: @escaping (Result<AttachCardModel, WalletRequestErrors>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.depositFromAttachedCard(ammount: ammout))) { (result) in
            switch result {
            case .success(let data):
                guard let countryCodeResponce = try? JSONDecoder().decode(BaseResponseModel<AttachCardModel>.self, from: data)  else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: "Invalid data from server")))
                    return
                }
                if let content = countryCodeResponce.content, countryCodeResponce.statusCode == 200 {
                    completion(.success(content))
                } else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: countryCodeResponce.message)))
                }
            case .failure(let error):
                VibrateEffectManager.shared.errorVibration()
                completion(.failure(.custom(message: error.localizedDescription)))
            }
        }
    }
    
    func depositFromAttachedCard2(_ ammout: Double, _ completion: @escaping (Result<(WalletModel?, AttachCardModel?), WalletRequestErrors>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.depositFromAttachedCard(ammount: ammout))) { (result) in
            switch result {
            case .success(let data):
                if let walletData = try? JSONDecoder().decode(BaseResponseModel<WalletModel>.self, from: data), let wallet = walletData.content {
                    completion(.success((wallet, nil)))
                } else if let attachCardData = try? JSONDecoder().decode(BaseResponseModel<AttachCardModel>.self, from: data), let attachCard = attachCardData.content {
                    completion(.success((nil, attachCard)))
                } else {
                    if let content = try? JSONDecoder().decode(BaseResponseModel<EmptyModel>.self, from: data) {
                        VibrateEffectManager.shared.errorVibration()
                        completion(.failure(.custom(message: content.message)))
                    } else {
                        VibrateEffectManager.shared.errorVibration()
                        completion(.failure(.custom(message: "Invalid data from server")))
                    }
                }
            case .failure(let error):
                VibrateEffectManager.shared.errorVibration()
                completion(.failure(.custom(message: error.localizedDescription)))
            }
        }
    }
    
    func depositWithTelCell(amount: Double, phoneNumber: String, completion: @escaping (Result<Void, WalletRequestErrors>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.depositWithTelcell(amount: amount, number: phoneNumber))) { (result) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                VibrateEffectManager.shared.errorVibration()
                completion(.failure(.custom(message: error.localizedDescription)))
            }
        }
    }
    
    func depositWithFastshift(amount: Double, phoneNumber: String, completion: @escaping (Result<FastshiftFormModel, WalletRequestErrors>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.depositWithFastshift(amount: amount, number: phoneNumber))) { (result) in
            switch result {
            case .success(let data):
                guard let countryCodeResponce = try? JSONDecoder().decode(BaseResponseModel<FastshiftFormModel>.self, from: data) else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: "Invalid data from server")))
                    return
                }
                if let content = countryCodeResponce.content, countryCodeResponce.statusCode == 200 {
                    completion(.success(content))
                } else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: countryCodeResponce.message)))
                }
            case .failure(let error):
                VibrateEffectManager.shared.errorVibration()
                completion(.failure(.custom(message: error.localizedDescription)))
            }
        }
    }
    
    func depositWithMyAmeria(amount: Double, completion: @escaping (Result<MyAmeriaFormModel, WalletRequestErrors>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.depositWithMyAmeria(amount: amount))) { (result) in
            switch result {
            case .success(let data):
                guard let countryCodeResponce = try? JSONDecoder().decode(BaseResponseModel<MyAmeriaFormModel>.self, from: data) else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: "Invalid data from server")))
                    return
                }
                if let content = countryCodeResponce.content, countryCodeResponce.statusCode == 200 {
                    completion(.success(content))
                } else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: countryCodeResponce.message)))
                }
            case .failure(let error):
                VibrateEffectManager.shared.errorVibration()
                completion(.failure(.custom(message: error.localizedDescription)))
            }
        }
    }
    
    func depositWithEasyPay(amount: Double, phoneNumber: String, completion: @escaping (Result<FastshiftFormModel, WalletRequestErrors>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.depositWithEasyPay(amount: amount, number: phoneNumber))) { (result) in
            switch result {
            case .success(let data):
                guard let countryCodeResponce = try? JSONDecoder().decode(BaseResponseModel<FastshiftFormModel>.self, from: data) else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: "Invalid data from server")))
                    return
                }
                if let content = countryCodeResponce.content, countryCodeResponce.statusCode == 200 {
                    completion(.success(content))
                } else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: countryCodeResponce.message)))
                }
            case .failure(let error):
                VibrateEffectManager.shared.errorVibration()
                completion(.failure(.custom(message: error.localizedDescription)))
            }
        }
    }
    
    func depostFromUnattachedCard(_ ammout: Double, _ completion: @escaping (Result<AttachCardModel, WalletRequestErrors>) -> Void) {
        let locale = StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))
//        else { return completion(.failure(.custom(message: ("Failed to get application language")))) }

        network.request(with: URLBuilder(from: AuthAPI.depositFromUnAttachedCard(ammount: ammout, locale: locale))) { (result) in
            switch result {
            case .success(let data):
                guard let countryCodeResponce = try? JSONDecoder().decode(BaseResponseModel<AttachCardModel>.self, from: data) else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: "Invalid data from server")))
                    return
                }
                if let content = countryCodeResponce.content, countryCodeResponce.statusCode == 200 {
                    completion(.success(content))
                } else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: countryCodeResponce.message)))
                }
            case .failure(let error):
                print("WalletRepository.depostFromUnattachedCard failed: \(error.localizedDescription)")
                VibrateEffectManager.shared.errorVibration()
                completion(.failure(.custom(message: error.localizedDescription)))
            }
        }
    }

    func depositFromCrypto(_ ammout: Double, _ completion: @escaping (Result<AttachCardModel, WalletRequestErrors>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.depositFromCrypto(ammount: ammout))) { (result) in
            switch result {
            case .success(let data):
                guard let countryCodeResponce = try? JSONDecoder().decode(BaseResponseModel<AttachCardModel>.self, from: data)  else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: "Invalid data from server")))
                    return
                }
                if let content = countryCodeResponce.content, countryCodeResponce.statusCode == 200 {
                    completion(.success(content))
                } else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: countryCodeResponce.message)))
                }
            case .failure(let error):
                VibrateEffectManager.shared.errorVibration()
                completion(.failure(.custom(message: error.localizedDescription)))
            }
        }
    }
    
    func deleteAttachedCard(_ completion: @escaping (Result<EmptyModel, WalletRequestErrors>) -> ()) {
        network.request(with: URLBuilder(from: AuthAPI.deleteCard)) { result in
            switch result {
            case .success(let data):
                guard let countryCodeResponce = try? JSONDecoder().decode(BaseResponseModel<EmptyModel>.self, from: data) else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.parseError))
                    return
                }
                if let content = countryCodeResponce.content, countryCodeResponce.statusCode == 200 {
                    completion(.success(content))
                } else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: countryCodeResponce.message)))
                }
            case .failure(let error):
                print("WalletRepository.deleteAttachedCard failed: \(error.localizedDescription)")
                VibrateEffectManager.shared.errorVibration()
                completion(.failure(.internalError))
            }
        }
    }

    func getGatewayList(_ completion: @escaping (Result<[GatewayModel], WalletRequestErrors>) -> ()) {
        network.request(with: URLBuilder(from: AuthAPI.getGateway)) { result in
            switch result {
            case .success(let data):
                guard let countryCodeResponce = try? JSONDecoder().decode(BaseResponseModel<[GatewayModel]>.self, from: data) else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.parseError))
                    return
                }
                if let content = countryCodeResponce.content, countryCodeResponce.statusCode == 200 {
                    completion(.success(content))
                } else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: countryCodeResponce.message)))
                }
            case .failure(let error):
                print("WalletRepository.getGatewayList failed: \(error.localizedDescription)")
                VibrateEffectManager.shared.errorVibration()
                completion(.failure(.internalError))
            }
        }
    }

    func attachNewCard(type: String, _ completion: @escaping (Result<GatewayFormModel, WalletRequestErrors>) -> ()) {
        network.request(with: URLBuilder(from: AuthAPI.attachNewCard(type: type))) { result in
            switch result {
            case .success(let data):
                guard let countryCodeResponce = try? JSONDecoder().decode(BaseResponseModel<GatewayFormModel>.self, from: data) else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.parseError))
                    return
                }
                if let content = countryCodeResponce.content, countryCodeResponce.statusCode == 200 {
                    completion(.success(content))
                } else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: countryCodeResponce.message)))
                }
            case .failure(let error):
                print("WalletRepository.attachNewCard failed: \(error.localizedDescription)")
                VibrateEffectManager.shared.errorVibration()
                completion(.failure(.internalError))
            }
        }
    }

    func sendPromoCode(code: String, _ completion: @escaping (Result<EmptyModel, WalletRequestErrors>) -> ()) {
        network.request(with: URLBuilder(from: AuthAPI.sendPromoCode(code: code))) { result in
            switch result {
            case .success(let data):
                guard let countryCodeResponce = try? JSONDecoder().decode(BaseResponseModel<EmptyModel>.self, from: data) else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.parseError))
                    return
                }
                if countryCodeResponce.statusCode == 200 {
                    completion(.success(EmptyModel()))
                } else {
                    VibrateEffectManager.shared.errorVibration()
                    completion(.failure(.custom(message: countryCodeResponce.message)))
                }
            case .failure(let error):
                print("WalletRepository.sendPromoCode failed: \(error.localizedDescription)")
                VibrateEffectManager.shared.errorVibration()
                completion(.failure(.internalError))
            }
        }
    }
}
