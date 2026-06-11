//
//  BikeDetailsData.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 22.07.23.
//

import Foundation

struct BikeDetailsData {
    
    var bikeData: BikeResult?
    var walletInfo: WalletModel?
    var financialState: FinancialStateModel?
    var bikeState: TripActionModel?
    var user: UserResponse?
    
    init(bikeData: BikeResult?, walletInfo: WalletModel?, financialState: FinancialStateModel?, bikeState: TripActionModel?, user: UserResponse?) {
        self.bikeData = bikeData
        self.walletInfo = walletInfo
        self.financialState = financialState
        self.bikeState = bikeState
        self.user = user
    }
}
