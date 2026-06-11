//
//  SubscriptionWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.06.24.
//

import Combine

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
