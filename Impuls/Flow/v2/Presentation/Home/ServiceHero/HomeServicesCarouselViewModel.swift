//
//  HomeServicesCarouselViewModel.swift
//  Impuls
//
//  Turns the home view model's available services and nearest-vehicles list
//  into the row of hero cards on the home screen: one card per product the
//  rider has chosen, an "add product" card while there is more to choose, a
//  skeleton until the services are known.
//

import Foundation
import Combine
import CoreLocation

final class HomeServicesCarouselViewModel {

    enum Item: Equatable {
        case loading
        case service(MimoProductType)
        case addProduct
    }

    let items = CurrentValueSubject<[Item], Never>([.loading])

    private var cards: [MimoProductType: HomeServiceHeroCardViewModel] = [:]
    private var cancellables = Set<AnyCancellable>()

    private var services: [MimoProductType]?
    private var results: [MimoResult]?
    private var location: CLLocationCoordinate2D?
    private var isLocationAuthorized = false

    init(homeViewModel: MimoHomeViewModel) {
        homeViewModel.$availableServices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] services in
                self?.services = services
                self?.rebuildItems()
            }
            .store(in: &cancellables)

        homeViewModel.$currentLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.location = location
                self?.pushLocation()
            }
            .store(in: &cancellables)

        homeViewModel.$isLocationAuthorized
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthorized in
                self?.isLocationAuthorized = isAuthorized
                self?.pushLocation()
            }
            .store(in: &cancellables)

        // The nearest-vehicles sheet triggers the load; the cards only read the
        // result. The subject's initial empty value is not a result yet.
        homeViewModel.fastDecisions
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                self?.results = results
                self?.pushSites()
            }
            .store(in: &cancellables)
    }

    /// A product can be taken off the home screen only while another one stays.
    var canRemoveProducts: Bool {
        (services?.count ?? 0) > 1
    }

    func card(for product: MimoProductType) -> HomeServiceHeroCardViewModel {
        if let card = cards[product] { return card }

        let card = HomeServiceHeroCardViewModel(style: .style(for: product))
        cards[product] = card
        card.update(location: location, isLocationAuthorized: isLocationAuthorized)
        if let results {
            card.update(sites: sites(for: product, in: results))
        }
        return card
    }

    // MARK: - Private

    private func rebuildItems() {
        guard let services else {
            if items.value != [.loading] { items.send([.loading]) }
            return
        }

        cards = cards.filter { services.contains($0.key) }

        var newItems = services.map(Item.service)
        // A power-bank-only market never offered "add product" on the tile row;
        // the card row keeps that rule.
        let hidesAddProduct = services == [.charger]
        if services.count < MimoProductType.allCases.count, !hidesAddProduct {
            newItems.append(.addProduct)
        }
        if newItems != items.value {
            items.send(newItems)
        }
    }

    private func pushLocation() {
        cards.values.forEach { $0.update(location: location, isLocationAuthorized: isLocationAuthorized) }
    }

    private func pushSites() {
        guard let results else { return }
        for (product, card) in cards {
            card.update(sites: sites(for: product, in: results))
        }
    }

    private func sites(for product: MimoProductType, in results: [MimoResult]) -> [HomeServiceHeroCardViewModel.Site] {
        switch product {
        case .scooter:
            return results.compactMap { $0 as? ScooterResult }
                .map { HomeServiceHeroCardViewModel.Site(coordinate: $0.coordinate, available: 1) }
        case .bike:
            return results.compactMap { $0 as? BikeResult }
                .map { HomeServiceHeroCardViewModel.Site(coordinate: $0.coordinate, available: 1) }
        case .charger:
            return results.compactMap { $0 as? ChargingStation }
                .map { HomeServiceHeroCardViewModel.Site(coordinate: $0.coordinate, available: $0.availablePowerBanksCount) }
        case .evCharger:
            // The home view model publishes one row per connector so the sheet
            // can list plugs; the card wants sites, so it folds them back by id.
            var order: [String] = []
            var folded: [String: HomeServiceHeroCardViewModel.Site] = [:]
            for case let station as EVChargingStation in results {
                let freePlugs = station.connectors.filter { $0.state == .available }.count
                if let existing = folded[station.id] {
                    folded[station.id] = HomeServiceHeroCardViewModel.Site(coordinate: existing.coordinate,
                                                                            available: existing.available + freePlugs)
                } else {
                    order.append(station.id)
                    folded[station.id] = HomeServiceHeroCardViewModel.Site(coordinate: station.coordinate,
                                                                            available: freePlugs)
                }
            }
            return order.compactMap { folded[$0] }
        }
    }
}
