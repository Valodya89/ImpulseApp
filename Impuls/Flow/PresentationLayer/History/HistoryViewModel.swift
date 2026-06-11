//
//  HistoryViewModel.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/20/25.
//

import Combine

final class HistoryViewModel: MimoBaseViewModel, ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let coordinatoor: EVChargerCoordinator
    private let worker: TripWorkerProtocol
    
    var selectionItems = PickerOption.allCases
    @Published var selectedItem: PickerOption = .scooter
    
    @Published private(set) var scooterTrips: [ItemSection<TripScooterDataModel>] = []
    @Published private(set) var bikeTrips: [ItemSection<TripBikeDataModel>] = []
    @Published private(set) var chargerRents: [ItemSection<ChargerRentModel>] = []
    @Published private(set) var evChargerRents: [ItemSection<EVChargerRentViewModel>] = []
//    @Published var selectedCellItem: String = ""
    
    init(
        coordinatoor: EVChargerCoordinator,
        worker: TripWorkerProtocol
    ) {
        self.coordinatoor = coordinatoor
        self.worker = worker
        super.init()
        
        getScooterTripList()
        observeSelectedItem()
    }
    
    func back() {
        coordinatoor.dissmiss()
    }
    
    private func observeSelectedItem() {
        $selectedItem
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                print("Selected item changed to: \(newValue)")
                self?.itemTapAction(item: newValue)
            }
            .store(in: &cancellables)
    }
    
    private func itemTapAction(item: PickerOption) {
        switch item {
        case .scooter:
            getScooterTripList()
        case .bike:
            getBikeTripList()
        case .charger:
            getChargerRentList()
        case .evup:
            getEvChargerRentList()
        }
    }
    
    private func getScooterTripList() {
        worker.getScooterTripList()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] scooterTrips in
                let grouped = Dictionary(grouping: scooterTrips) { item in
                    let date = Date(timeIntervalSince1970: TimeInterval((item.start ?? 0) / 1000))
                    return Calendar.current.startOfDay(for: date)
                }

                let sorted = grouped.sorted { $0.key > $1.key }
                var locale: Locale = Locale.current
                if let language = StorageManager().fetch(key: .language, type: String.self) {
                    locale = Locale(identifier: language)
                }

                self?.scooterTrips = sorted.map { (date, items) in
                    ItemSection(
                        title: date.toString(dateStyle: .medium, timeStyle: .none, locale: locale),
                        items: items
                    )
                }
                
                print("Scooter trips: \(scooterTrips)")
            }
            .store(in: &cancellables)
    }
    
    private func getBikeTripList() {
        worker.getBikeTripList()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] bikeTrips in
                let grouped = Dictionary(grouping: bikeTrips) { item in
                    let date = Date(timeIntervalSince1970: TimeInterval((item.start ?? 0) / 1000))
                    return Calendar.current.startOfDay(for: date)
                }

                let sorted = grouped.sorted { $0.key > $1.key }
                var locale: Locale = Locale.current
                if let language = StorageManager().fetch(key: .language, type: String.self) {
                    locale = Locale(identifier: language)
                }

                self?.bikeTrips = sorted.map { (date, items) in
                    ItemSection(
                        title: date.toString(dateStyle: .medium, timeStyle: .none, locale: locale),
                        items: items
                    )
                }
                print("Bike trips: \(bikeTrips)")
            }
            .store(in: &cancellables)
    }
    
    private func getChargerRentList() {
        worker.getChargerRentList()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] chargerRents in
                let grouped = Dictionary(grouping: chargerRents) { item in
                    let date = Date(timeIntervalSince1970: TimeInterval((item.start) / 1000))
                    return Calendar.current.startOfDay(for: date)
                }

                let sorted = grouped.sorted { $0.key > $1.key }
                var locale: Locale = Locale.current
                if let language = StorageManager().fetch(key: .language, type: String.self) {
                    locale = Locale(identifier: language)
                }

                self?.chargerRents = grouped.map { (date, items) in
                    ItemSection(
                        title: date.toString(dateStyle: .medium, timeStyle: .none, locale: locale),
                        items: items
                    )
                }
                print("Charger rents: \(chargerRents)")
            }
            .store(in: &cancellables)
    }
    
    private func getEvChargerRentList() {
        worker.getEVChargerRentList()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] evChargerRents in
                let evChargers = evChargerRents.map { $0.toViewMOdel() }
                let grouped = Dictionary(grouping: evChargers) { item in
                    let date = Date(timeIntervalSince1970: TimeInterval((item.start) / 1000))
                    return Calendar.current.startOfDay(for: date)
                }

                let sorted = grouped.sorted { $0.key > $1.key }
                var locale: Locale = Locale.current
                if let language = StorageManager().fetch(key: .language, type: String.self) {
                    locale = Locale(identifier: language)
                }

                self?.evChargerRents = sorted.map { (date, items) in
                    ItemSection(
                        title: date.toString(dateStyle: .medium, timeStyle: .none, locale: locale),
                        items: items
                    )
                }
                print("EvCharger rents: \(evChargerRents)")
            }
            .store(in: &cancellables)
    }
}

extension HistoryViewModel {
    enum PickerOption: String, SegmentedCapsuleOption {
        case scooter = "Scooter"
        case bike = "Bike"
        case charger = "Charger"
        case evup = "EvUp"
        
        var title: String { rawValue.capitalized }
    }
}

extension HistoryViewModel {
    struct ItemSection<T>: Identifiable {
        let id = UUID()
        let title: String
        let items: [T]
    }
}
