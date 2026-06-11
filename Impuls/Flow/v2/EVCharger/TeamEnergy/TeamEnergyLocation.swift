import Foundation
import CoreLocation

struct TeamEnergyLocation: Decodable, Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let city: String
    let street: String
    let region: Region
    let days: Days?
    let hours: Hours?

    struct Region: Decodable {
        let id: String
        let label: String
    }

    struct Days: Decodable {
        let monFry: String?
        let satSun: String?
    }

    struct Hours: Decodable {
        let monFry: String?
        let satSun: String?
    }

    private enum CodingKeys: String, CodingKey {
        case id, cord, city, street, region, days, hours
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        let cord = try c.decode([Double].self, forKey: .cord)
        guard cord.count >= 2 else {
            throw DecodingError.dataCorruptedError(forKey: .cord, in: c,
                                                   debugDescription: "Expected [lat, lng] pair")
        }
        self.coordinate = CLLocationCoordinate2D(latitude: cord[0], longitude: cord[1])
        self.city = try c.decode(String.self, forKey: .city)
        self.street = try c.decode(String.self, forKey: .street)
        self.region = try c.decode(Region.self, forKey: .region)
        self.days = try c.decodeIfPresent(Days.self, forKey: .days)
        self.hours = try c.decodeIfPresent(Hours.self, forKey: .hours)
    }
}
