//
//  ActivatedPackage.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 12.03.24.
//

import Foundation

/// `ChargerAccount` (powerbank docs/mobile-api.md "GET /api/account",
/// "PATCH /api/package/{id}/activate"). `package` is null for an account that
/// never activated one, and a package that does not parse reads as none rather
/// than failing the account.
struct ActivatedPackage: Decodable {
    let id: String
    let package: ServicePackage?

    private enum CodingKeys: String, CodingKey {
        case id, package
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decodeIfPresent(String.self, forKey: .id)) ?? ""
        package = try? container.decodeIfPresent(ServicePackage.self, forKey: .package)
    }
}

/// `ChargerAccount.package` and `ActiveRent.activePackage`: the package name
/// (e.g. `MONTHLY`) with its validity window in epoch milliseconds.
struct ServicePackage: Decodable {
    let id: String
    let name: String
    let start: Int64
    let end: Int64

    private enum CodingKeys: String, CodingKey {
        case id, name, start, end
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decodeIfPresent(String.self, forKey: .id)) ?? ""
        name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        start = (try? container.decodeIfPresent(Int64.self, forKey: .start)) ?? 0
        end = (try? container.decodeIfPresent(Int64.self, forKey: .end)) ?? 0
    }
}
