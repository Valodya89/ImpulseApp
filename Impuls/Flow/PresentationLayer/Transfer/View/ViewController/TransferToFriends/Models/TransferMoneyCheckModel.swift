//
//  TransferMoneyCheckModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 03.06.21.
//

import Foundation

enum TransferMoneyCheckModel {
    
    case success
    case failure(TransferMoneyErrors?)
    
    init(data: Data) {
        do {
            let checkModel = try JSONDecoder().decode(BaseResponseModel<EmptyResponseModel>.self, from: data)

            // The backend reports business failures as HTTP 200 with the real status in
            // the envelope, so the status code is what decides the outcome. Keying off a
            // recognised error message instead treated every unrecognised failure —
            // a wallet lock, an unknown receiver — as a completed transfer.
            guard checkModel.statusCode == 200 else {
                self = .failure(TransferMoneyErrors(rawValue: checkModel.message) ?? .other)
                return
            }

            self = .success
        } catch {
            self = .failure(nil)
        }
        
    }
}

enum TransferMoneyErrors: String, Error {
    case sameReceiver = "IPAY_duplicate_receiver"
    case notEnoughBalance = "IPAY_no_such_balance"
    case wrongAmount = "IPAY_deposit_local_wrong_amount"
    case transferNotAllowed = "IPAY_transfer_not_allowed"
    case noSuchUser = "IPAY_no_such_user"
    case noSuchWallet = "IPAY_no_such_wallet"
    case other
}
