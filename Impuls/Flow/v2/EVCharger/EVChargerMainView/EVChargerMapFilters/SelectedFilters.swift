//
//  SelectedFilters.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 3/15/25.
//

import Foundation
import Combine

final class SelectedFilters: ObservableObject {
    private(set) var chargingTypes: Set<String> = []
    private(set) var connectorTypes: Set<String> = []
    private(set) var amenities: Set<String> = []
    private(set) var minChargingPower: Double = 0
    private(set) var maxChargingPower: Double = 350

    let objectWillChange = PassthroughSubject<Void, Never>()

    func updateFilters(
        chargingTypes: Set<String>,
        connectorTypes: Set<String>,
        amenities: Set<String>,
        minChargingPower: Double,
        maxChargingPower: Double
    ) {
        self.chargingTypes = chargingTypes
        self.connectorTypes = connectorTypes
        self.amenities = amenities
        self.minChargingPower = minChargingPower
        self.maxChargingPower = maxChargingPower

        objectWillChange.send()
    }
}
