//
//  AppConfig.swift
//  MimoBike
//
//  Created by Andrey Lupin on 01.02.26.
//

import Foundation

/// The Firebase Remote Config flags the app reads. Decoding is tolerant: a key
/// that is missing from the remote payload (or carries an unexpected value)
/// keeps its default, and keys the app does not know are ignored, so a config
/// change on the console can never make the whole config fail to load.
public struct AppConfig: Decodable, Equatable {
    /// Scooter insurance offer on the scooter plan screen.
    var isInsuranceAvailable: Bool = false
    /// Impulse wallet: when false only the Carta MIR (card) top-up is offered;
    /// when true the other provider rails (Idram, Telcell, Fastshift, MyAmeria,
    /// crypto, ...) returned by the backend are shown as well. Defaults to the
    /// safe, hidden value.
    var showExtraPaymentRails: Bool = false

    enum CodingKeys: String, CodingKey, CaseIterable {
        case isInsuranceAvailable
        case showExtraPaymentRails
    }

    init() { }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.isInsuranceAvailable = (try? container.decodeIfPresent(Bool.self, forKey: .isInsuranceAvailable)) ?? false
        self.showExtraPaymentRails = (try? container.decodeIfPresent(Bool.self, forKey: .showExtraPaymentRails)) ?? false
    }
}
