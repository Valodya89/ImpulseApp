//
//  DemoMessage.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 08.05.24.
//

import SwiftUI
import SwiftMessages

struct SuccessMessage: Identifiable {
    let title: String
    let body: String

    var id: String { title + body }
}

extension SuccessMessage: MessageViewConvertible {
    func asMessageView() -> SuccessMessageView {
        SuccessMessageView(message: self)
    }
}
