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
                // Refused for unmet rules: report the first rule's code.
                if let rejection = ActionRejection.parse(data: data, request: nil) {
                    completion(.failure(.custom(message: rejection.message)))
                    return
                }

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
    
    /// PATCH api/bank/card/attached/deposit (ipay docs/mobile-api.md): the
    /// amount goes as a JSON number; success is `statusCode` 200 with the
    /// updated wallet as content (or, when the bank wants a form first, a
    /// `formUrl`). Every refusal is an HTTP-200 envelope without content whose
    /// `message` is the code (IPAY_amount_less_then_acceptable,
    /// IPAY_payment_rejected_by_payment_provider, ...) and is reported as is.
    func depositFromAttachedCard2(_ ammout: Double, _ completion: @escaping (Result<(WalletModel?, AttachCardModel?), WalletRequestErrors>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.depositFromAttachedCard(ammount: ammout))) { (result) in
            switch result {
            case .success(let data):
                if let walletData = try? JSONDecoder().decode(BaseResponseModel<WalletModel>.self, from: data),
                   walletData.statusCode == 200, let wallet = walletData.content {
                    completion(.success((wallet, nil)))
                } else if let attachCardData = try? JSONDecoder().decode(BaseResponseModel<AttachCardModel>.self, from: data),
                          attachCardData.statusCode == 200, let attachCard = attachCardData.content {
                    completion(.success((nil, attachCard)))
                } else {
                    VibrateEffectManager.shared.errorVibration()
                    if let envelope = try? JSONDecoder().decode(BaseResponseModel<EmptyModel>.self, from: data),
                       !envelope.message.isEmpty, envelope.message != "SUCCESS" {
                        completion(.failure(.custom(message: envelope.message)))
                    } else {
                        completion(.failure(.custom(message: "Invalid data from server")))
                    }
                }
            case .failure(let error):
                VibrateEffectManager.shared.errorVibration()
                completion(.failure(.custom(message: error.localizedDescription)))
            }
        }
    }
    
    /// PATCH api/telcell/deposit (ipay docs/mobile-api.md): success is an
    /// EMPTY 200 body - this endpoint does not use the envelope for success.
    /// A refusal is the usual HTTP-200 envelope (`statusCode` != 200, message
    /// such as user.not.found.telcell.system), which used to pass as success.
    func depositWithTelCell(amount: Double, phoneNumber: String, completion: @escaping (Result<Void, WalletRequestErrors>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.depositWithTelcell(amount: amount, number: phoneNumber))) { (result) in
            switch result {
            case .success(let data):
                let body = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if body.isEmpty {
                    completion(.success(()))
                } else if let envelope = try? JSONDecoder().decode(BaseResponseModel<EmptyModel>.self, from: data) {
                    if envelope.statusCode == 200 {
                        completion(.success(()))
                    } else {
                        VibrateEffectManager.shared.errorVibration()
                        completion(.failure(.custom(message: envelope.message)))
                    }
                } else {
                    // Not the documented empty body and not an envelope: an
                    // unknown non-refusal answer, treated as before.
                    completion(.success(()))
                }
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

    /// PATCH api/promo-code/{code}: a bare envelope, `statusCode` 200 with
    /// message "SUCCESS" on success; the screen shows its own copy for that.
    func sendPromoCode(code: String, _ completion: @escaping (Result<EmptyModel, WalletRequestErrors>) -> ()) {
        network.request(with: URLBuilder(from: AuthAPI.sendPromoCode(code: code.trimmingCharacters(in: .whitespacesAndNewlines)))) { result in
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
