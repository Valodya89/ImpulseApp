//
//  WalletViewModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 02.06.21.
//

import Foundation

final class WalletViewModel {
    
    private let walletRepository = WalletRepository()
    
    func checkPromo(result: @escaping (Result<PromoStatus, WalletRequestErrors>) -> ()) {
        self.walletRepository.checkPromoStatus(completion: result)
    }
    
    func walletInfo(result: @escaping (Result<WalletModel, WalletRequestErrors>) -> ()) {
        self.walletRepository.getWallet(completion: result)
    }
    
    func attachCard(result: @escaping (Result<AttachCardModel, WalletRequestErrors>) -> ()) {
        self.walletRepository.attachCard(provider: "", result)
    }
    
    func depositWithoutCard(ammount: Double, result: @escaping (Result<AttachCardModel, WalletRequestErrors>) -> ()) {
        self.walletRepository.depostFromUnattachedCard(ammount, result)
    }
    
    func depositWithCard(amount: Double, result: @escaping (Result<AttachCardModel, WalletRequestErrors>) -> ()) {
        self.walletRepository.depositFromAttachedCard(amount, result)
    }
    
    func depositWithCripto(amount: Double, result: @escaping (Result<AttachCardModel, WalletRequestErrors>) -> ()) {
        self.walletRepository.depositFromCrypto(amount, result)
    }
    
    func deleteCard(result: @escaping (Result<EmptyModel, WalletRequestErrors>) -> ()) {
        self.walletRepository.deleteAttachedCard(result)
    }
    
    func getGateway(result: @escaping (Result<[GatewayModel], WalletRequestErrors>) -> ()) {
        self.walletRepository.getGatewayList(result)
    }
    
    func attachNeweCard(type: String, result: @escaping (Result<GatewayFormModel, WalletRequestErrors>) -> ()) {
        self.walletRepository.attachNewCard(type: type, result)
    }
    
    func sendPromoCode(code: String, result: @escaping (Result<EmptyModel, WalletRequestErrors>) -> ()) {
        self.walletRepository.sendPromoCode(code: code, result)
    }
}
