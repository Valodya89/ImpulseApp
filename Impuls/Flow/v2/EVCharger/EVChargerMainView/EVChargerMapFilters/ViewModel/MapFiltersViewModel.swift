//
//  MapFiltersViewModel.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 26.02.25.
//

import SwiftUI
import Combine

class MapFiltersViewModel: ObservableObject {
    @Published var chargerTypes: [EVStationFilterItem] = []
    @Published var connectors: [EVStationFilterItem] = []
    @Published var amenities: [EVStationFilterItem] = []
    
    @Published var lowerValue: CGFloat = 0
    @Published var upperValue: CGFloat = 350
    let minValue: CGFloat = 0
    let maxValue: CGFloat = 350
    
    var coordinator: EVChargerCoordinator
    let selectedFilters: SelectedFilters
        
    init(coordinator: EVChargerCoordinator, selectedFilters: SelectedFilters) {
        self.coordinator = coordinator
        self.selectedFilters = selectedFilters
        
        fetchFilterFields()
    }
    
    private func fetchFilterFields() {
        chargerTypes = EVChargingType.allCases.map {
            EVStationFilterItem(id: $0.rawValue, image: $0.iconName, title: $0.title, isSelected: selectedFilters.chargingTypes.contains($0.rawValue))
        }
        connectors = EVConnectorType.allCases.map {
            EVStationFilterItem(id: $0.rawValue, image: $0.iconName, title: $0.title, isSelected: selectedFilters.connectorTypes.contains($0.rawValue))
        }
        amenities = EVAmenity.allCases.map {
            EVStationFilterItem(id: $0.rawValue, image: $0.iconName, title: $0.title, isSelected: selectedFilters.amenities.contains($0.rawValue))
        }
        lowerValue = selectedFilters.minChargingPower
        upperValue = selectedFilters.maxChargingPower
    }
    
    func closeFiltersView() {
        coordinator.dissmiss()
    }
    
    func toggleSelection(for item: EVStationFilterItem) {
        item.isSelected.toggle()
    }
    
    func resetFilters() {
        chargerTypes.forEach { $0.isSelected = false }
        connectors.forEach { $0.isSelected = false }
        amenities.forEach { $0.isSelected = false }
        lowerValue = minValue
        upperValue = maxValue
    }
    
    func showFilteredStations() {
        selectedFilters.updateFilters(
            chargingTypes: Set(chargerTypes.filter(\.isSelected).map(\.id)),
            connectorTypes: Set(connectors.filter(\.isSelected).map(\.id)),
            amenities: Set(amenities.filter(\.isSelected).map(\.id)),
            minChargingPower: lowerValue,
            maxChargingPower: upperValue
        )
        
        coordinator.dissmiss()
    }
}

class EVStationFilterItem: Identifiable, ObservableObject {
    let id: String
    let image: String
    let title: String
    @Published var isSelected: Bool = false
    
    init(id: String, image: String, title: String, isSelected: Bool = false) {
        self.id = id
        self.image = image
        self.title = title
        self.isSelected = isSelected
    }
}
