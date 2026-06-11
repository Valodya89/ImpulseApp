//
//  SubscriptionService.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.06.24.
//

import Combine

protocol SubscriptionServicable {
    func getPlans(_ endpoint: SubscriptionPlansEndpoint) -> AnyPublisher<[SubscriptionPlan], APIError>
    func activate(_ endpoint: SubscriptionActivateEndpoint) -> AnyPublisher<EmptyResponse, APIError>
    func cancel(_ endpoint: SubscriptionCancelEndpoint) -> AnyPublisher<EmptyResponse, APIError>
}

final class SubscriptionService: NetworkService, SubscriptionServicable {
    
    func getPlans(_ endpoint: SubscriptionPlansEndpoint) -> AnyPublisher<[SubscriptionPlan], APIError> {
        request(endpoint).eraseToAnyPublisher()
    }
    
    func activate(_ endpoint: SubscriptionActivateEndpoint) -> AnyPublisher<EmptyResponse, APIError> {
        request(endpoint).eraseToAnyPublisher()
    }
    
    func cancel(_ endpoint: SubscriptionCancelEndpoint) -> AnyPublisher<EmptyResponse, APIError> {
        request(endpoint).eraseToAnyPublisher()
    }
}
