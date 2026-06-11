//
//  EVStateMessagedDTO.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 3/6/25.
//

import Foundation

class EVStateMessagedDTO: Decodable {
    let state: String
    let station: EVChargingStationDTO
    let data: EVChargingDTO
}
