//
//  NotifyNewsWorkerProtocol.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/23/25.
//

import Foundation
import Combine

protocol NotifyNewsWorkerProtocol {
    func subscribeEVChargerNews(email: String) -> AnyPublisher<Void, MimoError>
}
