//
//  UserWalletManager.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/12/21.
//

import UIKit

enum IDramSucces {
    case redirectedToApp
}

enum IDramFailure: Error {
    case showIdramAlert(UIAlertController)
    case error(Error)
}

enum PaymentSuccess {
    case attachCard(AttachCardModel)
    case visa(WalletModel)
    case telcell
    case idram(IDramSucces)
}

enum PaymentFailures: Error {
    case error(WalletPaymentError)
    case idram(IDramFailure)
    case attachCardError(WalletPaymentError)
}

enum WalletPaymentError: Error {
    case paymentRejected
    case unknown(message: String)
    var description: String {
        switch self {
        case .paymentRejected:
            return "Payment rejected by payment provider try again later."
        case .unknown(message: let message):
            return "Unknown error: \(message)"
        }
    }
}

final class UserWalletManager {

    static let shared = UserWalletManager()

    let sessionNetwork = SessionNetwork()
    let storageManager = StorageManager()
    private weak var userManager = UserManager.share
    
    func getWallet(completion: @escaping (Result<WalletModel, Error>) -> Void) {
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.getWallet)) { (result) in
            switch result {
            case .success(let data):
                guard let countryCodeResponce = MimoConverter<BaseResponseModel<WalletModel>>.parseJson(data: data as Any) else {
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
    
    func payWallet(paymentMethod: WalletFillOptions, amount: Double, phoneNumber: String? = nil, completion: @escaping (Result<PaymentSuccess, PaymentFailures>) -> ()) {
        switch paymentMethod {
        case .attachCard:
            self.depositFromUnattachedCard(amount) { (result) in
                switch result {
                case .success(let model):
                    completion(.success(.attachCard(model)))
                case .failure(let error):
                    completion(.failure(.error(error)))
                }
            }
        case .card:
            self.depositFromAttachedCard(amount) { (result) in
                switch result {
                case .success(let model):
                    completion(.success(.visa(model)))
                case .failure(let error):
                    completion(.failure(.attachCardError(error)))
                }
            }
        case .iDram:
            self.depositFromIdram(amount: amount) { (result) in
                switch result {
                case .success(let success):
                    completion(.success(.idram(success)))
                case .failure(let error):
                    completion(.failure(.idram(error)))
                }
            }
        case .tellCell:
            guard let phoneNumber = phoneNumber else {
                return completion(.failure(.error(.unknown(message: "Failed to get users phone number."))))
            }
            self.depositWithTelcell(amount, phoneNumber: phoneNumber) { (result) in
                switch result {
                case .success:
                    completion(.success(.telcell))
                case .failure(let error):
                    completion(.failure(.error(.unknown(message: error.localizedDescription))))
                }
            }
        case .crypto:
            break
        }
    }
    
    private func depositFromIdram(amount: Double, completion: (Result<IDramSucces, IDramFailure>) -> ()) {
        guard let phoneNumber = storageManager.fetch(key: .phoneNumber, type: String.self) else {
            return completion(.failure(.error(NetworkError.responseError("Failed to get phone number"))))
        }
        
        if UIApplication.shared.canOpenURL(URL(string: "idramapp://launch?itm=558788989")!) {
            IdramPaymentManager.pay(withReceiverName: "MIMO Bike", receiverId: "110000222", title: phoneNumber, amount: amount as NSNumber, hasTip: false, callbackURLScheme: "mimo://")
            completion(.success(.redirectedToApp))
        } else {
            // idram.error
            completion(.failure(.showIdramAlert(self.showIDramAlert())))
        }
    }
    
    func showIDramAlert() -> UIAlertController {
        let actionViewController = UIAlertController(title: "", message: NSLocalizedString("idram.error", comment: ""), preferredStyle: .alert)
        
        actionViewController.addAction(UIAlertAction(title: NSLocalizedString("download.idram", comment: ""), style: .default, handler: { (actions) in
            //https://apps.apple.com/ug/app/idram/id558788989
            UIApplication.shared.open(URL(string: "https://apps.apple.com/am/app/idram/id558788989")!, completionHandler: nil)
            
        }))
        
        actionViewController.addAction(UIAlertAction(title: "MOBILE_global_cancel".localized(), style: .default, handler: { (actions) in
            actionViewController.dismiss(animated: true, completion: nil)
        }))
        
        return actionViewController
    }
    
    private func depositWithTelcell(_ amount: Double, phoneNumber: String, completion: @escaping (Result<Void, Error>) -> ()) {
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.depositWithTelcell(amount: amount, number: phoneNumber))) { (result) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func depositFromAttachedCard(_ ammout: Double, _ completion: @escaping (Result<WalletModel, WalletPaymentError>) -> Void) {
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.depositFromAttachedCard(ammount: ammout))) { (result) in
            switch result {
            case .success(let data):
                guard let countryCodeResponce = try? JSONDecoder().decode(BaseResponseModel<WalletModel>.self, from: data)  else {
                    completion(.failure(.unknown(message: "Unable to parse json from server.")))
                    return
                }
                if let content = countryCodeResponce.content, countryCodeResponce.statusCode == 200 {
                    completion(.success(content))
                } else {
                    completion(.failure(.paymentRejected))
                }
            case .failure(let error):
                completion(.failure(.unknown(message: error.localizedDescription)))
            }
        }
    }
    
    func depositFromUnattachedCard(_ ammout: Double, _ completion: @escaping (Result<AttachCardModel, WalletPaymentError>) -> Void) {
        guard let locale = storageManager.fetch(key: .language, type: String.self) else { return completion(.failure(.unknown(message: "Language localization error, try again later."))) }
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.depositFromUnAttachedCard(ammount: ammout, locale: locale))) { (result) in
            switch result {
            case .success(let data):
                guard let countryCodeResponce = try? JSONDecoder().decode(BaseResponseModel<AttachCardModel>.self, from: data) else {
                    completion(.failure(.unknown(message: "Internal error, try again later.")))
                    return
                }
                if let content = countryCodeResponce.content, countryCodeResponce.statusCode == 200 {
                    completion(.success(content))
                } else {
                    completion(.failure(.unknown(message: countryCodeResponce.message)))
                }
            case .failure(let error):
                completion(.failure(.unknown(message: error.localizedDescription)))
            }
        }
    }
    
    func depositFromCrypto(_ ammout: Double, _ completion: @escaping (Result<AttachCardModel, WalletPaymentError>) -> Void) {
        
    }
}
