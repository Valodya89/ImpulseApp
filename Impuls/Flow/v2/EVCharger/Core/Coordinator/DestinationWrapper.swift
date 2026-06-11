//
//  DestinationWraper.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 07.03.25.
//

import SwiftUI

public struct DestinationWrapper: Identifiable, Hashable {
    public var id: String { routable.id }
    let routable: any Routable
    
    init(routable: any Routable) {
        self.routable = routable
    }
    
    @ViewBuilder
    var contentView: some View {
        AnyView(routable.contentView)
    }
    
    public static func == (lhs: DestinationWrapper, rhs: DestinationWrapper) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
