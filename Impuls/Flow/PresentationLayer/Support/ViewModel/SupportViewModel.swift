//
//  SupportViewModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/4/21.
//

import Foundation

struct SupportViewModel {
    
    func call(phoneNumber: String) {
        if let url = URL(string: "tel://\(phoneNumber)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}
