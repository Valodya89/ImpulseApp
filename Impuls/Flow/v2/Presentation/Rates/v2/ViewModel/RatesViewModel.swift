//
//  RatesViewModel.swift
//  MimoBike
//
//  Created by Yurka Babayan on 14.07.25.
//

import Combine
import SwiftUI

class RatesViewModel: MimoBaseViewModel, ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let coordinatoor: EVChargerCoordinator
    var selectionItems = PickerOption.allCases
    var pageSelectionItems = PageDetailItems.allCases
    var rateScooters: [RatesScooterModel] = [
        RatesScooterModel(name: "Max Pluse", speedChargeTarrif: [45, 60, 75]),
        RatesScooterModel(name: "Max Pluse", speedChargeTarrif: [50, 65, 85]),
        RatesScooterModel(name: "Max Pluse", speedChargeTarrif: [45, 60, 75]),
        RatesScooterModel(name: "Max Pluse", speedChargeTarrif: [45, 60, 75]),
        RatesScooterModel(name: "Max Pluse", speedChargeTarrif: [45, 60, 75]),
        RatesScooterModel(name: "Max Pluse", speedChargeTarrif: [45, 60, 75])
    ]
    var rateScootersSpeed: [Int] = [15, 20, 25]
    
    @Published var selectedItem: PickerOption = .scooter
    @Published var pageSelectedItem: PageDetailItems?
    @Published var selectedScooter: RatesScooterModel?
    
    init(coordinatoor: EVChargerCoordinator) {
        self.coordinatoor = coordinatoor
        self.selectedScooter = rateScooters.first
        super.init()
        
        self.itemTapAction(item: .scooter)
        self.pageItemTapAction(item: pageSelectionItems.first ?? .tariffs)
        observeSelectedItem()
    }
    
    private func observeSelectedItem() {
        $selectedItem
            .sink { [weak self] newValue in
                print("Selected item changed to: \(newValue)")
                self?.itemTapAction(item: newValue)
            }
            .store(in: &cancellables)
    }
    
    private func itemTapAction(item: PickerOption) {
        switch item {
        case .scooter:
            let items: [PageDetailItems] = [.tariffs]
            pageSelectionItems.removeAll()
            pageSelectionItems.append(contentsOf: items)
        case .bike:
            let items: [PageDetailItems] = [.tariffs]
            pageSelectionItems.removeAll()
            pageSelectionItems.append(contentsOf: items)
        case .charger:
            let items: [PageDetailItems] = [.tariffs]
            pageSelectionItems.removeAll()
            pageSelectionItems.append(contentsOf: items)
        case .evup:
            pageSelectionItems.removeAll()
            pageSelectionItems.append(.tariffs)
        }
    }
    
    func pageItemTapAction(item: PageDetailItems) {
        pageSelectedItem = item
    }
    
    func rateScooterItemTapction(scooter: RatesScooterModel) {
        selectedScooter = scooter
    }
    
    func chanlangeTapAction() {
        
    }
    
    func bikeStudentAction() {
        
    }
    
    func back() {
        coordinatoor.dissmiss()
    }
}

extension RatesViewModel {
    enum PickerOption: String, SegmentedCapsuleOption {
        case scooter = "Scooter"
        case bike = "Bike"
        case charger = "Charger"
        case evup = "EvUp"
        
        var title: String { rawValue.capitalized }
    }
    
    enum PageDetailItems: String, CaseIterable {
        case tariffs = "Tariffs"
    }
}
