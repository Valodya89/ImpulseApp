//
//  RentedChargerViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.11.23.
//

import Foundation
import Combine

class RentedChargerViewModel: MimoBaseViewModel {
    
    var rentedChargers: CurrentValueSubject<[RentedCharger]?, Never> = .init(nil)
    
    let currency: String
    
    init(rentedChargers: [RentedCharger]?, currency: String) {
        self.rentedChargers.send(rentedChargers)
        self.currency = currency
    }
}
