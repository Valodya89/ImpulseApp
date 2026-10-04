//
//  ChargingStation.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 20.11.23.
//

import Foundation
import GoogleMaps

/// `StationDto` (powerbank docs/mobile-api.md "GET /api/station", shape under
/// "GET /public/station/nearby"). Every field is read leniently: one station with
/// an odd value must not empty the whole map.
struct ChargingStation: Decodable, MimoResult {
    let id: String?
    /// The code printed on the cabinet - what a rider matches the row against.
    let qr: String?
    let type: String?
    let slotsCount: Int?
    let powerBanksCount: Int?
    let powerBanks: [PowerBank]?
    let location: Located?
    let destinationName: String?
    let destinationAddress: String?
    let images: [ImageObj]?
    let logo: ImageObj?
    let workingHours: String?
    let instagramUrl: String?
    let facebookUrl: String?
    let websiteUrl: String?
    let linkedinUrl: String?
    /// Percent; `0` when the backend sends none.
    let discount: Int
    /// `ACTIVE`, `TECHNICAL_CHECKUP`, `BROKEN` or `LOST`; kept as the wire string.
    let status: String?

    private enum CodingKeys: String, CodingKey {
        case id, qr, type, slotsCount, powerBanksCount, powerBanks, location, destinationName, destinationAddress, images, logo, workingHours, instagramUrl, facebookUrl, websiteUrl, linkedinUrl, discount, status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? container.decodeIfPresent(String.self, forKey: .id)
        qr = try? container.decodeIfPresent(String.self, forKey: .qr)
        type = try? container.decodeIfPresent(String.self, forKey: .type)
        slotsCount = try? container.decodeIfPresent(Int.self, forKey: .slotsCount)
        powerBanksCount = try? container.decodeIfPresent(Int.self, forKey: .powerBanksCount)
        powerBanks = try? container.decodeIfPresent([PowerBank].self, forKey: .powerBanks)
        location = try? container.decodeIfPresent(Located.self, forKey: .location)
        destinationName = try? container.decodeIfPresent(String.self, forKey: .destinationName)
        destinationAddress = try? container.decodeIfPresent(String.self, forKey: .destinationAddress)
        images = try? container.decodeIfPresent([ImageObj].self, forKey: .images)
        logo = try? container.decodeIfPresent(ImageObj.self, forKey: .logo)
        workingHours = try? container.decodeIfPresent(String.self, forKey: .workingHours)
        instagramUrl = try? container.decodeIfPresent(String.self, forKey: .instagramUrl)
        facebookUrl = try? container.decodeIfPresent(String.self, forKey: .facebookUrl)
        websiteUrl = try? container.decodeIfPresent(String.self, forKey: .websiteUrl)
        linkedinUrl = try? container.decodeIfPresent(String.self, forKey: .linkedinUrl)
        discount = (try? container.decodeIfPresent(Int.self, forKey: .discount)) ?? 0
        status = try? container.decodeIfPresent(String.self, forKey: .status)
    }

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: location?.latitude ?? 0, longitude: location?.longitude ?? 0)
    }
}

/// The `PowerBank` document: a station's slot entry and `StateMessagedDto.powerBank`.
struct PowerBank: Decodable {
    let id: String?
    let slotNumber: Int?
    let electricQuantity: Double?
    let voltage: Int?
    let amperage: Int?
    /// `nil` when the backend sends none; `.unknown` for a value this build does not know.
    let status: PowerBankStatus?

    private enum CodingKeys: String, CodingKey {
        case id, slotNumber, electricQuantity, voltage, amperage, status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? container.decodeIfPresent(String.self, forKey: .id)
        slotNumber = try? container.decodeIfPresent(Int.self, forKey: .slotNumber)
        electricQuantity = try? container.decodeIfPresent(Double.self, forKey: .electricQuantity)
        voltage = try? container.decodeIfPresent(Int.self, forKey: .voltage)
        amperage = try? container.decodeIfPresent(Int.self, forKey: .amperage)
        status = try? container.decodeIfPresent(PowerBankStatus.self, forKey: .status)
    }
}

/// `PowerBankStatus` (powerbank docs/overview.md "Main domain objects",
/// docs/mobile-api.md "PATCH /api/admin/power-bank/{id}/{status}"): FREE,
/// BOOKED, RENT, BROKEN, LOST, TRANSFER, GARAGE. Anything newer lands in
/// `.unknown` with its wire value instead of failing the state list.
enum PowerBankStatus: Equatable, Decodable {
    case free
    case booked
    case rent
    case broken
    case lost
    case transfer
    case garage
    case unknown(String)

    init(rawValue: String) {
        switch rawValue {
        case "FREE": self = .free
        case "BOOKED": self = .booked
        case "RENT": self = .rent
        case "BROKEN": self = .broken
        case "LOST": self = .lost
        case "TRANSFER": self = .transfer
        case "GARAGE": self = .garage
        default: self = .unknown(rawValue)
        }
    }

    init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }

    var rawValue: String {
        switch self {
        case .free: return "FREE"
        case .booked: return "BOOKED"
        case .rent: return "RENT"
        case .broken: return "BROKEN"
        case .lost: return "LOST"
        case .transfer: return "TRANSFER"
        case .garage: return "GARAGE"
        case .unknown(let raw): return raw
        }
    }
}

extension ChargingStation {

    /// Power banks the backend reports as available in the cabinet.
    var availablePowerBanksCount: Int {
        max(0, powerBanksCount ?? 0)
    }

    func toGMSMarker() -> GMSMarker {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: location?.latitude ?? 0, longitude: location?.longitude ?? 0)
        marker.appearAnimation = .none
        let slotsCount = slotsCount ?? 0
        let availableSlotsCount = powerBanksCount ?? 0
        marker.iconView = ChargerMarkerView(
            slotsCount: slotsCount - availableSlotsCount,
            avaliablePBCount: availableSlotsCount,
            discount: discount
        )
        marker.groundAnchor = .init(x: 0.3, y: 0.5)
        return marker
    }
    
    func toSelectedGMSMarker() -> GMSMarker {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: location?.latitude ?? 0, longitude: location?.longitude ?? 0)
        marker.appearAnimation = .none
        let slotsCount = slotsCount ?? 0
        let availableSlotsCount = powerBanksCount ?? 0
        marker.iconView = ChargerSelectedMarkerView(
            slotsCount: slotsCount - availableSlotsCount,
            avaliablePBCount: availableSlotsCount,
            discount: discount
        )
        marker.groundAnchor = .init(x: 0.3, y: 1)
        
        return marker
    }
}
