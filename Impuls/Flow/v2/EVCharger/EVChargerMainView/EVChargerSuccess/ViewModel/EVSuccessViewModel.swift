//
//  EVSuccessViewModel.swift
//  MimoBike
//
//  Created by Yurka Babayan on 02.08.25.
//

import Foundation
import SwiftUI
import Combine

class EVSuccessViewModel: MimoBaseViewModel, ObservableObject {
    
    private var cancellables = Set<AnyCancellable>()
    private let coordinatoor: EVChargerCoordinator
    
    var totalPrice: String
    var conectorNumber: String
    var chargerType: String
    var charged: String
    var chargeDuration: String
    
    @Published var selectedIndex: Int = -1
    @Published var comment: String = ""
    
//    var attributedText: AttributedString {
//        var str = AttributedString("Need Help? Contact us.")
//        
//        if let range1 = str.range(of: "Need Help?") {
//            str[range1].foregroundColor = Color(hex: "#666666")
//        }
//        
//        if let range2 = str.range(of: "Contact us.") {
//            str[range2].foregroundColor = Color.evbrandCyan80
//            str[range2].link = URL(string: "https://www.mimobike.com")
//        }
//        
//        return str
//    }
    
    init(coordinatoor: EVChargerCoordinator, chargingInfo: ChargingListDto) {
        self.coordinatoor = coordinatoor
        
        self.totalPrice = "\(chargingInfo.price?.amount ?? 0) \(chargingInfo.price?.currency ?? "")"
        self.conectorNumber = String(chargingInfo.connectorId)
        self.chargerType = chargingInfo.connectorType.title
        self.charged = "\(chargingInfo.kwtsCharged) " + "EV_CHARGER_kw".localized()
        self.chargeDuration = ""
        
        super.init()        
    }
    
    func routeToMap() {
        coordinatoor.navigationController?.popToRootViewController(animated: false)
        coordinatoor.navigationController?.isNavigationBarHidden = false
        coordinatoor.navigationController?.tabBarController?.tabBar.isHidden = false
    }
}


