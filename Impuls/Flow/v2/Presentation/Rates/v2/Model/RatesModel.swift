//
//  RatesModel.swift
//  MimoBike
//
//  Created by Yurka Babayan on 14.07.25.
//

import Foundation

struct RatesScooterModel: Identifiable, Equatable {
    var id = UUID().uuidString
    var name: String
    var speedChargeTarrif: [Int]
}
