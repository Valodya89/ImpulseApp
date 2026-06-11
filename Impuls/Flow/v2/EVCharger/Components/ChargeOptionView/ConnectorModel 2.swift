//
//  ConnectorModel.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 02.03.25.
//

import Foundation
import SwiftUI

struct ConnectorModel {
    let id = UUID()
    let title: String
    let image: ImageResource
    var isSelected: Bool
}
