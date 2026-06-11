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
    
    init(rentedChargers: [RentedCharger]?) {
        self.rentedChargers.send(rentedChargers)
    }
}
