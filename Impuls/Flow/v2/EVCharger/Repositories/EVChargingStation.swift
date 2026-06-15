//
//  EVChargingStation.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/25/25.
//

import Foundation
import CoreLocation
import UIKit
struct EVChargingStationResponse: Decodable {
    let station: EVChargingStationDTO
    let feedbacks: [EVStationFeedbackDTO]
    let chargings: [EVChargingInfoDTO]?
}

struct EVChargingStationDTO: Decodable {
    let id: String
    
    let instagramUrl: String?
    let facebookUrl: String?
    let websiteUrl: String?
    let linkedinUrl: String?
    let destinationName: String?
    let destinationAddress: String?
    let workingHours: String?
    
    let images: [MediaDTO]?
    let logo: MediaDTO?
    let location: Located?
    let status: String?
    let state: String?
    let type: String?
    let amenities: [EVAmenity]?
    let connectors: [EVChargingConnectorDTO]?
    let rating: Decimal?
    let currency: String?
}

struct EVCoordinatesDTO: Decodable {
    let latitude: Double?
    let longitude: Double?
}

struct EVLocationDTO: Decodable {
    let id: String
    let city: String?
    let coordinates: EVCoordinatesDTO?
    let country: String?
    let countryCode: String?
    let destinationAddress: String?
    let destinationName: String?
    let direction: String?
    let facilities: [String]?
    let images: [EVImageDTO]?
    let logo: EVImageDTO?
    let logoThumbnailUrl: String?
    let `operator`: EVOperatorDTO?
    let parkingType: String?
    let partyId: String?
    let postalCode: String?
    let rating: Double?
    let roaming: Bool?
    let state: String?
    let stations: [EVLocationStationDTO]?
    let timezone: String?
    let workingHours: String?
    let socialMedia: EVSocialMediaDTO?
}

struct EVSocialMediaDTO: Decodable {
    let instagramUrl: String?
    let facebookUrl: String?
    let linkedinUrl: String?
    let websiteUrl: String?
}

struct EVImageDTO: Decodable {
    let id: String?
    let url: URL?
    let thumbnail: URL?
    let path: String?
    let thumbnailPath: String?
    let category: String?
    let type: String?
    let width: String?
    let height: String?
    let sortOrder: Int?
}

struct EVOperatorDTO: Decodable {
    let logo: EVImageDTO?
    let name: String?
    let website: String?
}

struct EVLocationStationDTO: Decodable {
    let id: String
    let chargingType: EVChargingType?
    let state: EVConnectorState?
    let connectors: [EVChargingConnectorDTO]?
    let chargings: [EVChargingInfoDTO]?
}

struct EVChargingConnectorDTO: Decodable {
    let connectorId: Int
    let errorCode: String?
    let info: String?
    let power: Double?
    let state: EVConnectorState
    let type: EVConnectorType?
    let adapters: [EVConnectorType]?
    let chargingType: EVChargingType?
    let pricePerKW: Double?
}

struct EVChargingStation: Identifiable, MimoResult, Equatable {
    let id: String
    
    var instagramUrl: String?
    var facebookUrl: String?
    var websiteUrl: String?
    var linkedinUrl: String?
    let destinationName: String
    let destinationAddress: String
    var workingHours: String
    
    var images: [URL]?
    var logo: URL?
    var location: Located?
    var status: String?
    var state: String?
    var type: String?
    let currency: String
    var amenities: [String]?
    var connectors: [EVChargingConnector] = []
    var uniqueConnectors: [EVChargingConnector] = []
    var chargingTypes: [EVChargingType] = []
    var partyId: String?
    var roaming: Bool?
    var rating: Double?
    var stationGroups: [EVStationGroup] = []

    init(station: EVChargingStationDTO, chargings: [EVChargingInfoDTO]? = nil) {
        self.id = station.id

        self.instagramUrl = station.instagramUrl
        self.facebookUrl = station.facebookUrl
        self.websiteUrl = station.websiteUrl
        self.linkedinUrl = station.linkedinUrl
        self.destinationName = station.destinationName ?? "-- --"
        self.destinationAddress = station.destinationAddress ?? "-- --"
        self.workingHours = station.workingHours ?? "-- --"

        self.images = station.images?.compactMap { $0.url }
        self.logo = station.logo?.url
        self.location = station.location

        self.currency = station.currency ?? "-- --"
        self.amenities = station.amenities?.compactMap { $0.title }

        self.connectors = station.connectors?.compactMap {
            var connector = EVChargingConnector(connector: $0)
            connector.percent = chargings?.first(where: { $0.connectorId == connector.id })?.percent
            return connector
        } ?? []

        for connector in connectors {
            if !uniqueConnectors.contains(where: { $0.type == connector.type }) {
                uniqueConnectors.append(connector)
            }
        }

        var collectedTypes: [EVChargingType] = []
        for connector in connectors where !collectedTypes.contains(connector.chargingType) {
            collectedTypes.append(connector.chargingType)
        }
        self.chargingTypes = collectedTypes
    }

    init(location: EVLocationDTO) {
        self.id = location.id

        self.instagramUrl = location.socialMedia?.instagramUrl
        self.facebookUrl = location.socialMedia?.facebookUrl
        self.websiteUrl = location.socialMedia?.websiteUrl ?? location.operator?.website
        self.linkedinUrl = location.socialMedia?.linkedinUrl
        self.destinationName = location.destinationName ?? "-- --"
        self.destinationAddress = location.destinationAddress ?? "-- --"
        self.workingHours = location.workingHours ?? "-- --"

        let parsedImages = location.images?.compactMap { $0.url } ?? []
        if !parsedImages.isEmpty {
            self.images = parsedImages
        } else {
            let fallback = [
                location.logo?.url,
                location.operator?.logo?.url,
                URL(string: location.logoThumbnailUrl ?? "")
            ].compactMap { $0 }
            self.images = fallback.isEmpty ? nil : fallback
        }
        self.logo = location.logo?.url
            ?? location.operator?.logo?.url
            ?? URL(string: location.logoThumbnailUrl ?? "")
        self.location = Located(
            longitude: location.coordinates?.longitude,
            latitude: location.coordinates?.latitude,
            timestamp: nil
        )

        self.currency = "-- --"
        self.amenities = location.facilities

        self.connectors = (location.stations ?? []).flatMap { stationDTO in
            (stationDTO.connectors ?? []).map { dto in
                var connector = EVChargingConnector(connector: dto)
                connector.stationId = stationDTO.id
                connector.percent = stationDTO.chargings?.first(where: { $0.connectorId == connector.id })?.percent
                return connector
            }
        }

        self.stationGroups = (location.stations ?? []).map { stationDTO in
            EVStationGroup(
                id: stationDTO.id,
                connectors: (stationDTO.connectors ?? []).map { dto in
                    var connector = EVChargingConnector(connector: dto)
                    connector.stationId = stationDTO.id
                    connector.percent = stationDTO.chargings?.first(where: { $0.connectorId == connector.id })?.percent
                    return connector
                }
            )
        }

        for connector in connectors {
            if !uniqueConnectors.contains(where: { $0.type == connector.type }) {
                uniqueConnectors.append(connector)
            }
        }

        var collectedTypes: [EVChargingType] = []
        for station in (location.stations ?? []) {
            if let type = station.chargingType, !collectedTypes.contains(type) {
                collectedTypes.append(type)
            }
        }
        for connector in connectors where !collectedTypes.contains(connector.chargingType) {
            collectedTypes.append(connector.chargingType)
        }
        self.chargingTypes = collectedTypes

        self.partyId = location.partyId
        self.roaming = location.roaming
        self.rating = location.rating
    }

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: location?.latitude ?? 0, longitude: location?.longitude ?? 0)
    }
    
    static func == (lhs: EVChargingStation, rhs: EVChargingStation) -> Bool {
        return lhs.id == rhs.id
    }
    
    var isFast: Bool {
        chargingTypes.contains(.faster)
    }
    
    func toGMSMarker(animate: Bool = true) -> MimoMarker {
        let marker = MimoMarker()
        marker.icon = isFast ? #imageLiteral(resourceName: "evcharger_fast_marker") : #imageLiteral(resourceName: "evcharger_marker")
        marker.position = coordinate
        marker.appearAnimation = animate ? .pop : .none
        
        return marker
    }
    
    func toSelectedGMSMarker(animate: Bool = true) -> MimoMarker {
        let marker = MimoMarker()
        marker.icon = isFast ? #imageLiteral(resourceName: "evcharger_fast_selected_marker") : #imageLiteral(resourceName: "evcharger_selected_marker")
        marker.position = coordinate
        marker.appearAnimation = animate ? .pop : .none
        
        return marker
    }
}

struct EVStationGroup: Identifiable {
    let id: String
    let connectors: [EVChargingConnector]
}

struct EVChargingConnector: Identifiable {
    let id: Int
    var stationId: String?
    let errorCode: String?
    let info: String?
    let power: Double
    let state: EVConnectorState
    let type: EVConnectorType
    let adapters: [EVConnectorType]
    let chargingType: EVChargingType
    let pricePerKW: Double
    var percent: Double?
    
    init(connector: EVChargingConnectorDTO) {
        self.id = connector.connectorId
        self.errorCode = connector.errorCode
        self.info = connector.info
        self.power = connector.power ?? 0
        self.state = connector.state
        self.type = connector.type ?? .type1
        self.adapters = connector.adapters ?? []
        self.chargingType = connector.chargingType ?? .standard
        self.pricePerKW = connector.pricePerKW ?? 0
    }
}

struct EVStationFeedbackDTO: Decodable {
    let id: String
    let author: String
    let type: EVConnectorType?
    let rating: Int
    let comment: String?
    let createdAt: Date
}

struct EVStationFeedback: Identifiable {
    let id: String
    let author: String
    let type: EVConnectorType
    let rating: Int
    let comment: String?
    let createdAt: Date
    
    init(feedback: EVStationFeedbackDTO) {
        self.id = feedback.id
        self.author = feedback.author
        self.type = feedback.type ?? .ccs1
        self.rating = feedback.rating
        self.comment = feedback.comment
        self.createdAt = feedback.createdAt
    }
}

struct EVChargingInfoDTO: Decodable {
    let connectorId: Int
    let percent: Double
}

extension EVChargingStation {
    func toGMSMarker() -> MimoMarker {
        let marker = MimoMarker()
        marker.position = CLLocationCoordinate2D(latitude: location?.latitude ?? 0, longitude: location?.longitude ?? 0)
        marker.appearAnimation = .none
        marker.iconView = ChargerMarkerView(
            slotsCount: 10,
            avaliablePBCount: 5,
            discount: 3
        )
        marker.groundAnchor = .init(x: 0.3, y: 0.5)
        return marker
    }
    
    func toSelectedGMSMarker() -> MimoMarker {
        let marker = MimoMarker()
        marker.position = CLLocationCoordinate2D(latitude: location?.latitude ?? 0, longitude: location?.longitude ?? 0)
        marker.appearAnimation = .none
        marker.iconView = ChargerSelectedMarkerView(
            slotsCount: 10,
            avaliablePBCount: 5,
            discount: 3
        )
        marker.groundAnchor = .init(x: 0.3, y: 1)
        
        return marker
    }
}

struct MockChargerStation {
    let destinationName = "Megamall Armenia"
    let destinationAdress = "16 Gai Ave, Yerevan"
    let instagramUrl: String? = "https://www.instagram.com/el_chillout_?igsh=OWEzbnFtbmR1c2d3"
    let facebookUrl: String? = "https://www.instagram.com/el_chillout_?igsh=OWEzbnFtbmR1c2d3"
    let linkedinUrl: String? = "https://www.instagram.com/el_chillout_?igsh=OWEzbnFtbmR1c2d3"
    let websiteUrl: String? = "https://www.instagram.com/el_chillout_?igsh=OWEzbnFtbmR1c2d3"
    let workingHours: String = "20:00-01:00"
    let images: [ImageObj] = [
        ImageObj(id: "7B407133B56702E180D31988E0F5861D06A7F7B36A65A2AE17259C3FCED63D52BB7C4AB054E4ADA85F3A891E11445996", node: "repository"),
        ImageObj(id: "7B407133B56702E180D31988E0F5861D06A7F7B36A65A2AE17259C3FCED63D526B93AAF85448CF1338CFEAB875932919", node: "repository"),
        ImageObj(id: "7B407133B56702E180D31988E0F5861DB5022DF6E0B0C750B62F54C02F0B77EFFE996F06C47E8669F197FF5C4B05BB39", node: "repository"),
        ImageObj(id: "7B407133B56702E180D31988E0F5861DB5022DF6E0B0C750B62F54C02F0B77EFEEB7B7EB0660E7FE19AD78E0D5DBDEB0", node: "repository"),
        ImageObj(id: "7B407133B56702E180D31988E0F5861DB5022DF6E0B0C750B62F54C02F0B77EFE96B09B40201BB7EEA608B158C4DF539", node: "repository")
    ]
    let logo: ImageObj = ImageObj(id: "7B407133B56702E180D31988E0F5861D89FC376B7446CB4AF5F8A3FD6AE096FE97E46CE3B5E957433E3CC043AF11DB71", node: "repository")
    
    let amenities: [String]? = ["Wi-Fi: Stay", "Restrooms", "Nearby Cafe", "Parking Space"]
    let connectors: [Connector]? = [Connector(), Connector(), Connector(), Connector(), Connector(), Connector()]
    let reviews: [Review]? = [Review(), Review(), Review(), Review(), Review(), Review()]
    
    
    struct Connector: Identifiable {
        let id: UUID = UUID()
        let name = "J-1772"
        let speed = "22 kW"
    }
    
    struct Review: Identifiable {
        let id: UUID = UUID()
        let name = "J-1772"
        let speed = "22 kW"
    }
}
