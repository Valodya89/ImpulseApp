//
//  TransferToFriendsViewModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/2/21.
//

import Foundation

struct TransferToFriendsViewModel {
    let repository = TransferToFriendsRepository()
    let keychainManager = KeychainManager()
    let storageManager = StorageManager()
    
    func transferMoney(amount: Double, phoneNumber: String, completion: @escaping (Result<Void, TransferMoneyErrors>) -> ()) {
        repository.transferMoney(amount: amount, phoneNumber: phoneNumber, completion: completion)
    }
    
    func getUserPhoneNumber() -> String {
        return storageManager.fetch(key: .phoneNumber, type: String.self) ?? ""
    }
    
    func getTransferAvatar(avatarUrlString: String,completion: @escaping (String) -> Void) {
        if let token = keychainManager.getAccessToken() {
            completion(avatarUrlString + token)
        }
    }
}
