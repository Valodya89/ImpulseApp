//
//  InfoMessage.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 20.05.24.
//

import SwiftUI
import SwiftMessages

struct InfoMessage: Identifiable {
    let title: String
    let body: String

    var id: String { title + body }
}
