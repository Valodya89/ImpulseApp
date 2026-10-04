//
//  SubscriptionWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.06.24.
//

import Combine
import Foundation

/// Country gate for the Subscriptions entry in Profile.
///
/// Remote Config `subscription_enabled_countries` lists the countries where
/// the feature is offered: ISO3 codes ("ARM,RUS"), ISO2 codes ("AM,RU") or a
/// JSON array of either. A missing or empty value falls back to the first live
/// market (ARM), so a market is never switched on by accident; to offer it
/// nowhere publish a value with no country in it (e.g. "NONE").
///
/// The rider's country is the alpha-3 code `ApplicationSettings.isoCountryCode`
/// (resolved from location at sign-in); while it is unknown the row stays
/// hidden. The plan catalogue itself is country/locale-driven by the backend
/// through the `country` and `locale` request headers
/// (accounts docs/mobile-api.md, GET /api/subscription-plan/list).
enum SubscriptionAvailability {

    static let remoteConfigKey = "subscription_enabled_countries"
    static let defaultCountries = ["ARM"]

    /// The configured list, every entry normalised to an upper-case ISO3 code.
    static var enabledCountries: [String] {
        guard let raw = RemoteConfigManager.value(forKey: remoteConfigKey)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else {
            return defaultCountries
        }

        let separators = CharacterSet(charactersIn: ",;[]\"' \n\t")
        return raw
            .components(separatedBy: separators)
            .compactMap(normalised)
    }

    static func isEnabled(forCountry code: String?) -> Bool {
        guard let code = normalised(code ?? "") else { return false }

        return enabledCountries.contains(code)
    }

    /// The gate for the signed-in rider.
    static var isEnabledForCurrentCountry: Bool {
        isEnabled(forCountry: ApplicationSettings.shared.isoCountryCode)
    }

    /// Upper-case ISO3 for an ISO2 or ISO3 input; nil for anything else.
    private static func normalised(_ value: String) -> String? {
        let code = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        switch code.count {
        case 3:
            return code
        case 2:
            return CountryUtilities.getAlphaThreeCode(byAlpha2Code: code)?.uppercased()
        default:
            return nil
        }
    }
}

protocol SubscriptionWorkerProtocol {
    func getPlans() -> AnyPublisher<[SubscriptionPlan], APIError>
    func getActivePlan() -> AnyPublisher<ActiveSubscriptionPlan?, APIError>
    func activatePlan(id: String) -> AnyPublisher<EmptyResponse, APIError>
    func cancelPlan(id: String) -> AnyPublisher<EmptyResponse, APIError>
}

final class SubscriptionWorker: SubscriptionWorkerProtocol {
    
    private let subscriptionService: SubscriptionServicable
    private let userService: UserServicable
    
    init(subscriptionService: SubscriptionServicable, userService: UserServicable) {
        self.subscriptionService = subscriptionService
        self.userService = userService
    }
    
    func getPlans() -> AnyPublisher<[SubscriptionPlan], APIError> {
        subscriptionService.getPlans(SubscriptionPlansEndpoint())
            .map { $0.sorted(by: { $0.price < $1.price }) }
            .eraseToAnyPublisher()
    }
    
    func getActivePlan() -> AnyPublisher<ActiveSubscriptionPlan?, APIError> {
        userService.getUser(UserEndpoint())
            .compactMap({ $0.activePlan })
            .eraseToAnyPublisher()
    }
    
    func activatePlan(id: String) -> AnyPublisher<EmptyResponse, APIError> {
        subscriptionService.activate(SubscriptionActivateEndpoint(id: id))
            .eraseToAnyPublisher()
    }
    
    func cancelPlan(id: String) -> AnyPublisher<EmptyResponse, APIError> {
        subscriptionService.cancel(SubscriptionCancelEndpoint(id: id))
            .eraseToAnyPublisher()
    }
}
