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
            let message = TransferMoneyErrors(rawValue: checkModel.message)
            
            guard let unwrapMessage = message else {
                self = .success
                
                return
            }
            
            self = .failure(unwrapMessage)
        } catch {
            self = .failure(nil)
        }
        
    }
}

enum TransferMoneyErrors: String, Error {
    case sameReceiver = "IPAY_duplicate_receiver"
    case notEnoughBalance = "IPAY_no_such_balance"
    case wrongAmount = "IPAY_deposit_local_wrong_amount"
    case other
}
