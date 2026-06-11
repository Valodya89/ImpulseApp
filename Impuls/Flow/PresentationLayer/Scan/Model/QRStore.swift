//
//  QRStore.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/26/21.
//

import Foundation

final class QRStore {
    
    static let sharedInstance = QRStore()
    
    var qr: String?
    var currentBanalce: Double = 0.0
    var speedTariffs: [SpeedTariff] = []
}
