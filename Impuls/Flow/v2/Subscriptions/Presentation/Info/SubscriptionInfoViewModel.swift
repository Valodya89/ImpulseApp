//
//  SubscriptionInfoViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.06.24.
//

import Combine

final class SubscriptionInfoViewModel: MimoBaseViewModel, ObservableObject {
    
    private var BAG = Set<AnyCancellable>()
    
    private let worker: SubscriptionWorkerProtocol
    
    @Published var plans: [SubscriptionPlan] = []
    @Published var activePlan: ActiveSubscriptionPlan?
    /// True once the first load has answered (plans or an error), so the
    /// "no plans in your region" state is never shown while loading.
    @Published var isLoaded: Bool = false

    /// The catalogue is empty for this country/locale: nothing to buy.
    var hasNoPlans: Bool { isLoaded && plans.isEmpty }

    /// The rider has a plan whose renewal was stopped: it stays active until
    /// `activeUntil` and is not charged again.
    var isActivePlanCancelled: Bool { activePlan?.cancelled ?? false }
    
    let points = [
        "MOBILE_subscriptions_point_1",
        "MOBILE_subscriptions_point_2",
        "MOBILE_subscriptions_point_3",
        "MOBILE_subscriptions_point_4",
        "MOBILE_subscriptions_point_5"
    ]
    
    init(worker: SubscriptionWorkerProtocol) {
        self.worker = worker
    }
    
    func loadData() {
        Publishers.Zip(worker.getPlans(), worker.getActivePlan())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoaded = true
                if case .failure(let error) = completion {
                    self?.apiError = error
                }
            } receiveValue: { [weak self] plans, activePlan in
                self?.plans = plans
                self?.activePlan = activePlan
                self?.isLoaded = true
            }
            .store(in: &BAG)
    }
    
    private func loadPlans() {
        worker.getPlans()
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.apiError = error
                }
            } receiveValue: { [weak self] data in
                self?.plans = data
            }
            .store(in: &BAG)
    }
    
    private func getActivePlan() {
        worker.getActivePlan()
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.apiError = error
                }
            }, receiveValue: { [weak self] data in
                self?.activePlan = data
            })
            .store(in: &BAG)
    }
    
    /// "dd.MM.yyyy" of the day the active plan runs out.
    func activeUntilDate() -> String {
        guard let activePlan else { return "" }
        return DateFormatter.dayMonthYearFormatter.string(
            from: Date(timeIntervalSince1970: TimeInterval(activePlan.activeUntil / 1000))
        )
    }

    func activePlanDate() -> String {
        guard let activePlan else { return "" }
        var date = DateFormatter.dayMonthYearFormatter.string(
            from: Date(
                timeIntervalSince1970: TimeInterval(activePlan.activatedAt/1000)
            )
        )
        
        date.append(" - ")
        
        date.append(
            DateFormatter.dayMonthYearFormatter.string(
                from: Date(
                    timeIntervalSince1970: TimeInterval(activePlan.activeUntil/1000)
                )
            )
        )
        
        return date
    }
}
