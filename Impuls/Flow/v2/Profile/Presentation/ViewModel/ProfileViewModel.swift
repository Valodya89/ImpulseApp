//
//  ProfileViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 15.04.24.
//

import Foundation
import Combine
import UIKit
import FirebaseMessaging

final class ProfileViewModel: MimoBaseViewModel, ObservableObject {
    
    private var BAG = Set<AnyCancellable>()
    
    private let worker: ProfileWorkerProtocol
    private let messageService: MessageServiceProtocol
    
    @Published private(set) var name: String = ""
    @Published private(set) var phoneNumber: String = ""
    @Published private(set) var distance: String = ""
    @Published private(set) var calories: String = ""
    @Published private(set) var carbon: String = ""
    @Published private(set) var isEmailVerified: Bool = false
    
    @Published private(set) var user: UserResponse?
    @Published private(set) var avatarURL: URL?
    @Published private(set) var package: ActivePackage?
    
    @Published private(set) var wallet: WalletModel?
    @Published private(set) var financialState: FinancialStateModel?
    
    @Published private(set) var currency: String = "AMD"
    @Published private(set) var balance: String = "0.0"
    @Published private(set) var isBalanceNegative: Bool = false
    @Published private(set) var freeMinutes: String = "0"
    
    @Published private(set) var isSuccessfullyLogout: Bool?
    
    init(worker: ProfileWorkerProtocol, messageService: MessageServiceProtocol) {
        self.worker = worker
        self.messageService = messageService
        super.init()
        
        messageService.subscribe(self, for: .refreshUser, .balanceUpdated)
    }
    
    func loadData() {
        // User data is loaded independently so that a failure in the
        // balance / financial-state / package calls can't blank the profile.
        worker.getUser()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.mimoError = error
                }
            } receiveValue: { [weak self] user in
                self?.handleUserResponse(user)
            }
            .store(in: &BAG)

        // Wallet / financial-state / package are decoupled from the user fetch.
        // Each error is swallowed (mapped to nil) so one failing call doesn't
        // prevent the others — or the user data above — from showing.
        Publishers.Zip3(
            worker.loadBalance().map(Optional.some).replaceError(with: nil),
            worker.loadFinancialState().map(Optional.some).replaceError(with: nil),
            worker.getActivePackage().replaceError(with: nil)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] wallet, financialState, package in
            if let wallet, let financialState {
                self?.handleWalletResponse(wallet: wallet, financialState: financialState)
            }
            self?.package = package?.package

            self?.freeMinutes = String(format: "%.1f", package?.minutes ?? 0)
        }
        .store(in: &BAG)
    }
    
    /// Pull-to-refresh: reports back once the user (or an error) arrives.
    func reload(completion: @escaping (Bool) -> Void) {
        var delivered = false
        let loaded = $user.dropFirst().map { _ in true }
        let failed = $errorMessage.dropFirst().compactMap { $0 }.map { _ in false }

        loaded.merge(with: failed)
            .first()
            .timeout(.seconds(15), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                // Timed out without a value: end the indicator, no success chime.
                if case .finished = result, !delivered { completion(false) }
            }, receiveValue: { success in
                delivered = true
                completion(success)
            })
            .store(in: &BAG)

        loadData()
    }

    func logout() {
        worker.logout()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.mimoError = error
                }
            } receiveValue: { [weak self] isSuccess in
                KeychainManager().removeData()
                StorageManager().remove(key: .avatar)
                UserManager.share.userResponse = nil
                Self.revokePushToken()

                self?.isSuccessfullyLogout = isSuccess
            }
            .store(in: &BAG)
    }

    func deleteAccount() {
        worker.deleteAccount()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.mimoError = error
                }
            } receiveValue: { [weak self] isSuccess in
                KeychainManager().removeData()
                UserManager.share.userResponse = nil
                Self.revokePushToken()

                self?.isSuccessfullyLogout = isSuccess
            }
            .store(in: &BAG)
    }

    /// There is no unregister endpoint: the device's FCM token is deleted
    /// client-side, so a shared phone stops receiving the previous account's
    /// pushes (accounts docs/push-notifications.md, "Token lifecycle
    /// (mobile)"). Firebase then mints a fresh token, which reaches
    /// `didReceiveRegistrationToken` and is registered by the next signed-in
    /// Home.
    private static func revokePushToken() {
        MimoHomeWorker.forgetAcknowledgedPushToken()
        (UIApplication.shared.delegate as? AppDelegate)?.fcmToken = nil

        Messaging.messaging().deleteToken { error in
            if let error {
                debugPrint("[push] token delete failed: \(error.localizedDescription)")
            }

            // Ask for the replacement right away rather than on the next launch.
            Messaging.messaging().token { _, _ in }
        }
    }
    
    private func handleUserResponse(_ user: UserResponse?) {
        self.user = user
        
        self.avatarURL = user?.avatar?.getURL()
        self.isEmailVerified = user?.emailVerified ?? false
        
        let _distance = user?.distance ?? 1.0
        self.distance = String(format: "%.f", ((_distance / 1000.0)))
        self.calories = String(format: "%.f", ((_distance / 1000.0) * 21))
        self.carbon = String(format: "%.f", ((_distance / 19000)))
        
//        self.freeMinutes = String(format: "%.1f", user?.minutes ?? 0)
        
        formatName()
    }
    
    private func handleWalletResponse(wallet: WalletModel, financialState: FinancialStateModel) {
        self.wallet = wallet
        self.financialState = financialState
        
        self.phoneNumber = wallet.id
        
        self.currency = wallet.currency.currencyName
        let balance = (wallet.balance - (financialState.additional ?? 0))
        self.balance = String(format: "%.2f", balance)
        self.isBalanceNegative = balance < 0
    }
    
    private func formatName() {
        let nameFormatter = PersonNameComponentsFormatter()
        var components = PersonNameComponents()
        components.givenName = user?.name
        components.familyName = user?.surname
        
        self.name = nameFormatter.string(from: components)
    }
    
    override func receive(message: MessageKey) {
        switch message {
        case .refreshUser, .balanceUpdated:
            loadData()
        default:
            break
        }
    }
}
