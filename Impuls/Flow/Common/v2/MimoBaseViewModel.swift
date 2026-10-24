//
//  MimoBaseViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 21.05.23.
//

import Foundation
import Combine

class MimoBaseViewModel: SubscriberProtocol {
    
    var id: String = UUID().uuidString
    
    var networkError: NetworkError? {
        didSet {
            guard let networkError else { return }
            present(networkError, message: Self.alertMessage(for: networkError))
        }
    }
    
    var mimoError: MimoError? {
        didSet {
            guard let mimoError else {
                errorMessage = nil
                return
            }
            present(mimoError, message: mimoError.message)
        }
    }
    
    var apiError: APIError? {
        didSet {
            if case .authorizationError = apiError {
                BaseRouter.shared.showLoginView()
                return
            }
            
            guard let apiError else {
                errorMessage = nil
                return
            }
            present(apiError, message: apiError.message)
        }
    }
    
    /// What the rider is told about, as an alert card. Stays nil for a failure
    /// that is not worth one (see `isConnectivityFailure`).
    @Published var errorMessage: String?

    /// Every failure handed to this view model, alert or not. An owner that
    /// has to stop a loader, end a pull-to-refresh or re-arm a scan listens
    /// here, not on `errorMessage`, which stays nil for a lost connection.
    let requestFailed = PassthroughSubject<Error, Never>()

    /// The one path from a failed request to an alert, for view models that
    /// hold an `Error` rather than one of the typed setters' values.
    /// - Parameter message: the alert text when it is not the error's own
    ///   (a screen-specific mapping of the backend code, for example).
    func handle(_ error: Error, message: String? = nil) {
        if let apiError = error as? APIError, case .authorizationError = apiError {
            BaseRouter.shared.showLoginView()
            return
        }
        present(error, message: message ?? Self.alertMessage(for: error))
    }

    /// Tells the owners, then either shows the alert or - for a request that
    /// got no answer from the network - swallows it: no alert card, but the
    /// blocking loader the screens hide on the alert is hidden here instead; a
    /// loader that stays up over a timed-out request would be worse than the
    /// alert was.
    private func present(_ error: Error, message: String) {
        requestFailed.send(error)
        guard !Self.isConnectivityFailure(error) else {
            DispatchQueue.main.async { MILoader.hide() }
            return
        }
        errorMessage = message
    }

    /// A lost connection, a timed-out request, the phone offline: nothing is
    /// shown for it. A dropped poll on the map or home recovers with the next
    /// one, and alerts about it only stacked up on riders with a weak signal.
    /// Business refusals, HTTP errors and decoding failures are not covered.
    /// Pure; the rule itself lives in `ConnectivityFailure` (MimoError.swift).
    static func isConnectivityFailure(_ error: Error) -> Bool {
        ConnectivityFailure.matches(error)
    }

    /// The alert text of an error, as the typed setters have always shown it.
    static func alertMessage(for error: Error) -> String {
        switch error {
        case let mimoError as MimoError:
            return mimoError.message
        case let networkError as NetworkError:
            if case .serverError = networkError { return "Server Error" }
            return MimoError(error: networkError).message
        case let apiError as APIError:
            return apiError.message
        case let sessionError as NetworkSessionErrors:
            return sessionError.description
        case let walletError as WalletRequestErrors:
            return walletError.localizedDescription
        default:
            return error.localizedDescription
        }
    }
    
    deinit {
        print("deinit - \(String(describing: self))")
        unsubscribe()
    }
    
    open func receive(message: MessageKey) { }
    open func unsubscribe() { }
}
