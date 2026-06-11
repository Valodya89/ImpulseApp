//
//  TransactionListViewModel.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/26/25.
//

import Combine

final class TransactionListViewModel: MimoBaseViewModel, ObservableObject {
    private var cancellables = Set<AnyCancellable>()
//    private let coordinatoor: EVChargerCoordinator
    private let worker: TransactionWorkerProtocol
    
    @Published private(set) var transactions: [ItemSection<TransactionDTO>] = []

    init(
//        coordinatoor: EVChargerCoordinator,
        worker: TransactionWorkerProtocol
    ) {
//        self.coordinatoor = coordinatoor
        self.worker = worker
        super.init()
        
        getTransactionList()
    }
    
    func back() {
//        coordinatoor.dissmiss()
    }
    
    private func getTransactionList() {
        worker.getTransactionList()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] transactions in
                let grouped = Dictionary(grouping: transactions) { item in
                    let date = Date(timeIntervalSince1970: TimeInterval((item.date) / 1000))
                    return Calendar.current.startOfDay(for: date)
                }

                let sorted = grouped.sorted { $0.key > $1.key }
                var locale: Locale = Locale.current
                if let language = StorageManager().fetch(key: .language, type: String.self) {
                    locale = Locale(identifier: language)
                }

                self?.transactions = sorted.map { (date, items) in
                    ItemSection(
                        title: date.toString(dateStyle: .medium, timeStyle: .none, locale: locale),
                        items: items
                    )
                }
                
                print("transactions: \(transactions)")
            }
            .store(in: &cancellables)
    }
}

extension TransactionListViewModel {
    struct ItemSection<T>: Identifiable {
        let id = UUID()
        let title: String
        let items: [T]
    }
}
