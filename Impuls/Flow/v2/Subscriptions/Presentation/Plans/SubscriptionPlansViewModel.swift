//
//  SubscriptionPlansViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.06.24.
//

import Combine
import Foundation

final class SubscriptionPlansViewModel: MimoBaseViewModel, ObservableObject {
    
    private var BAG = Set<AnyCancellable>()
    
    private let worker: SubscriptionWorkerProtocol
    
    @Published var plans: [SubscriptionPlan] = []
    @Published var selectedPlan: SubscriptionPlan?
    @Published var activePlan: ActiveSubscriptionPlan?
    @Published var activated: Bool = false
    @Published var canceld: Bool = false

    /// Renewal of the active plan was stopped; it stays active until
    /// `activeUntil`. The backend un-cancels it when the same plan is
    /// activated again (no charge), so the active card stays selectable.
    var isActivePlanCancelled: Bool { activePlan?.cancelled ?? false }

    /// The plan `plan` is the one currently active.
    func isActive(_ plan: SubscriptionPlan) -> Bool {
        activePlan?.subscriptionPlanId == plan.id
    }

    /// The selected plan is the cancelled active one: the CTA resumes it.
    var isResumingActivePlan: Bool {
        guard let selectedPlan, isActivePlanCancelled else { return false }
        return isActive(selectedPlan)
    }

    /// "dd.MM.yyyy - dd.MM.yyyy": the active plan's range, shown under its card.
    func activePlanSubtitle() -> String {
        guard let activePlan else { return "" }
        let from = DateFormatter.dayMonthYearFormatter.string(
            from: Date(timeIntervalSince1970: TimeInterval(activePlan.activatedAt / 1000))
        )
        return "\(from) - \(activeUntilDate())"
    }

    /// "dd.MM.yyyy" of the day the active plan runs out.
    func activeUntilDate() -> String {
        guard let activePlan else { return "" }
        return DateFormatter.dayMonthYearFormatter.string(
            from: Date(timeIntervalSince1970: TimeInterval(activePlan.activeUntil / 1000))
        )
    }
    
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
                // Pre-select the first plan that is not the active one; when
                // the active plan's renewal was cancelled, pre-select it so the
                // single tap resumes it.
                if let activePlan, activePlan.cancelled,
                   let active = plans.first(where: { $0.id == activePlan.subscriptionPlanId }) {
                    self?.selectedPlan = active
                } else {
                    self?.selectedPlan = plans.first(where: { $0.id != activePlan?.subscriptionPlanId })
                }
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
