//
//  SubscriptionPlansViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.06.24.
//

import Combine

final class SubscriptionPlansViewModel: MimoBaseViewModel, ObservableObject {
    
    private var BAG = Set<AnyCancellable>()
    
    private let worker: SubscriptionWorkerProtocol
    
    @Published var plans: [SubscriptionPlan] = []
    @Published var selectedPlan: SubscriptionPlan?
    @Published var activePlan: ActiveSubscriptionPlan?
    @Published var activated: Bool = false
    @Published var canceld: Bool = false
    
    init(worker: SubscriptionWorkerProtocol) {
        self.worker = worker
    }
    
    func loadData() {
        Publishers.Zip(worker.getPlans(), worker.getActivePlan())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.apiError = error
                }
            } receiveValue: { [weak self] plans, activePlan in
                self?.plans = plans
                self?.activePlan = activePlan
                self?.selectedPlan = plans.first(where: { $0.id != activePlan?.subscriptionPlanId })
            }
            .store(in: &BAG)
    }
    
    func activatePlan(id: String) {
        worker.activatePlan(id: id)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    if case .missingData(let statusCode) = error, statusCode == 200 {
                        self?.activated = true
                    } else {
                        self?.apiError = error
                    }
                }
            }, receiveValue: { [weak self] _ in
                self?.activated = true
            })
            .store(in: &BAG)
    }
    
    func cancelActivePlan() {
        guard let id = activePlan?.subscriptionPlanId else { return }
        
        worker.cancelPlan(id: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    if case .missingData(let statusCode) = error, statusCode == 200 {
                        self?.canceld = true
                    } else {
                        self?.apiError = error
                    }
                }
            } receiveValue: { [weak self] _ in
                self?.canceld = true
            }
            .store(in: &BAG)
    }
    
    private func loadPlans() {
        worker.getPlans()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.apiError = error
                }
            } receiveValue: { [weak self] data in
                self?.plans = data
            }
            .store(in: &BAG)
    }
}
