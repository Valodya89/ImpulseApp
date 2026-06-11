//
//  ErrorMessage.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 09.05.24.
//

import SwiftUI
import SwiftMessages

struct ErrorMessage: Identifiable {
    let title: String
    let body: String

    var id: String { title + body }
}

extension ErrorMessage: MessageViewConvertible {
    func asMessageView() -> ErrorMessageView {
        ErrorMessageView(message: self)
    }
}

