//
//  ChargingStationDetailsViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 22.11.23.
//

import Foundation

class ChargingStationDetailsViewModel: MimoBaseViewModel {
    
    private(set) var chargingStation: ChargingStation?
    private(set) var walletInfo: WalletModel?
    private(set) var financialState: FinancialStateModel?
    private(set) var user: UserResponse?
    
    init(chargingStation: ChargingStation?, walletInfo: WalletModel?, financialState: FinancialStateModel?, user: UserResponse?) {
        self.chargingStation = chargingStation
        self.walletInfo = walletInfo
        self.financialState = financialState
        self.user = user
        
        super.init()
    }
}
