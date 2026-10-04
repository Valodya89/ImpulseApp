//
//  UserResponse.swift
//  MimoBike
//
//  Created by Albert on 19.05.21.
//

import Foundation

enum AppThemeMode: String, Codable {
    case dark = "DARK"
    case light = "LIGHT"
}

/// The accounts `UserDto` - the body of `GET /api/user`, `PUT /api/user`,
/// `PUT /api/user/settings`, `PUT /api/user/avatar` and the `user` of a sign-in
/// (accounts docs/mobile-api.md, headings "GET /api/user", "PUT /api/user",
/// commit eb41a3e925cf7da27bc5c6e59b4cf47a9eb6e2f4).
///
/// Decoding is lenient on purpose: the backend may omit any of these fields or
/// send `null`, and a nested document in a shape this build does not know
/// (settings, avatar, package, tariff, activePlan, address) becomes nil and is
/// reported once instead of failing the whole profile and with it the screen.
struct UserResponse: Decodable {
    let name: String?
    let surname: String?
    let gender: String?
    let email: String?
    let birthday: String?
    let status: String?
    let distance: Double?
    let minutes: Double?
    let bio: String?
    let avatar: AvatarResponse?
    var emailVerified: Bool?
    let package: ActivePackage?
    let tariff: ActiveTarrif?
    let lastActionDate: Double?
    var settings: SettingsModel?
    let activePlan: ActiveSubscriptionPlan?
    var services: [String]?
    /// ISO alpha-3, stored at sign-up (docs/mobile-api.md "PUT /api/user").
    let country: String?
    let address: AddressResponse?

    /// `AccountSettings`: locale, push toggle, UI mode `DARK` / `LIGHT`
    /// (accounts docs/mobile-api.md "PUT /api/user/settings").
    struct SettingsModel: Codable {
        var locale: String?
        var sendPush: Bool?
        var mode: AppThemeMode?
        
        func toDictionary() -> [String: Any] {
            return ["locale": locale ?? "en", "sendPush": sendPush ?? true, "mode": mode?.rawValue ?? AppThemeMode.light.rawValue]
        }
    }
    
    var isAccountComplated: Bool {
        return name != nil && surname != nil && gender != nil && birthday != nil
    }
}

extension UserResponse {

    private enum CodingKeys: String, CodingKey {
        case name, surname, gender, email, birthday, status, distance, minutes, bio, avatar
        case emailVerified, package, tariff, lastActionDate, settings, activePlan, services
        case country, address
    }

    private static let document = "UserDto"

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let document = Self.document

        name = container.decodeLenient(String.self, forKey: .name, in: document)
        surname = container.decodeLenient(String.self, forKey: .surname, in: document)
        gender = container.decodeLenient(String.self, forKey: .gender, in: document)
        email = container.decodeLenient(String.self, forKey: .email, in: document)
        birthday = container.decodeLenient(String.self, forKey: .birthday, in: document)
        status = container.decodeLenient(String.self, forKey: .status, in: document)
        distance = container.decodeLenientDouble(forKey: .distance, in: document)
        minutes = container.decodeLenientDouble(forKey: .minutes, in: document)
        bio = container.decodeLenient(String.self, forKey: .bio, in: document)
        avatar = container.decodeLenient(AvatarResponse.self, forKey: .avatar, in: document)
        emailVerified = container.decodeLenient(Bool.self, forKey: .emailVerified, in: document)
        package = container.decodeLenient(ActivePackage.self, forKey: .package, in: document)
        tariff = container.decodeLenient(ActiveTarrif.self, forKey: .tariff, in: document)
        lastActionDate = container.decodeLenientDouble(forKey: .lastActionDate, in: document)
        settings = container.decodeLenient(SettingsModel.self, forKey: .settings, in: document)
        activePlan = container.decodeLenient(ActiveSubscriptionPlan.self, forKey: .activePlan, in: document)
        services = container.decodeLenient([String].self, forKey: .services, in: document)
        country = container.decodeLenient(String.self, forKey: .country, in: document)
        address = container.decodeLenient(AddressResponse.self, forKey: .address, in: document)
    }
}

extension UserResponse.SettingsModel {

    private enum CodingKeys: String, CodingKey {
        case locale, sendPush, mode
    }

    /// A `mode` this build does not know (anything but `DARK` / `LIGHT`) is nil
    /// - the theme falls back to the system one - instead of dropping the whole
    /// settings object or the whole user.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let document = "AccountSettings"

        locale = container.decodeLenient(String.self, forKey: .locale, in: document)
        sendPush = container.decodeLenient(Bool.self, forKey: .sendPush, in: document)

        let rawMode = container.decodeLenient(String.self, forKey: .mode, in: document)
        mode = rawMode.flatMap { AppThemeMode(rawValue: $0.uppercased()) }
        if let rawMode, mode == nil {
            LenientDecoding.report(document: document, field: "mode", detail: "unknown value \(rawMode)")
        }
    }
}

/// `Address` of the accounts `User`: `{ country, city, street, postalCode }`
/// (accounts docs/mobile-api.md "PUT /api/user", docs/overview.md "Main domain objects").
struct AddressResponse: Decodable {
    let country: String?
    let city: String?
    let street: String?
    let postalCode: String?

    private enum CodingKeys: String, CodingKey {
        case country, city, street, postalCode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let document = "Address"

        country = container.decodeLenient(String.self, forKey: .country, in: document)
        city = container.decodeLenient(String.self, forKey: .city, in: document)
        street = container.decodeLenient(String.self, forKey: .street, in: document)
        postalCode = container.decodeLenient(String.self, forKey: .postalCode, in: document)
    }
}

/// `FileData` of the avatar: `node` comes from `file.repository.active.node`
/// (accounts docs/mobile-api.md "PUT /api/user/avatar").
struct AvatarResponse: Decodable {
    let id: String?
    let node: String?
    
    func getURL() -> URL? {
        guard let token = KeychainManager().getAccessToken(), let node = node, let id = id else { return nil }
        var avatar = "https://\(node).impulsepower.ru/files?id=\(id)&token=\(token)"
        print("avatar url = \(avatar)")
        return URL(string: avatar)
    }
}

extension AvatarResponse {

    private enum CodingKeys: String, CodingKey {
        case id, node
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let document = "FileData"

        id = container.decodeLenient(String.self, forKey: .id, in: document)
        node = container.decodeLenient(String.self, forKey: .node, in: document)
    }
}

// MARK: - Lenient decoding

/// Decoding helpers for backend DTOs. A field the backend omits or sends as
/// `null` is nil; a field in a shape this build does not know is nil as well,
/// reported once per document and field as abnormal behaviour
/// (`POST /mobile-errors`) instead of failing the whole document - and with it
/// the screen that asked for it.
enum LenientDecoding {

    private static var reported = Set<String>()
    private static let lock = NSLock()

    /// Reports the first drop of `document.field` in this process; later ones
    /// are the same backend contract drift and would only flood the queue.
    static func report(document: String, field: String, detail: String) {
        let key = "\(document).\(field)"

        lock.lock()
        let isFirst = reported.insert(key).inserted
        lock.unlock()

        guard isFirst else { return }

        print("LenientDecoding: dropped \(key): \(detail)")
        ErrorReporter.shared.reportAbnormalBehavior(
            "Lenient decode dropped \(key)",
            action: "decode",
            extra: ["document": document, "field": field, "detail": detail]
        )
    }

    static func report(document: String, field: String, error: Error) {
        report(document: document, field: field, detail: String(describing: error))
    }
}

extension KeyedDecodingContainer {

    /// Absent or `null` -> nil. Wrong shape -> nil, reported once.
    func decodeLenient<T: Decodable>(_ type: T.Type, forKey key: Key, in document: String) -> T? {
        do {
            return try decodeIfPresent(T.self, forKey: key)
        } catch {
            LenientDecoding.report(document: document, field: key.stringValue, error: error)
            return nil
        }
    }

    /// `decodeLenient` with a default for the fields the screens read as
    /// non-optionals.
    func decodeLenient<T: Decodable>(_ type: T.Type, forKey key: Key, in document: String, default value: T) -> T {
        decodeLenient(type, forKey: key, in: document) ?? value
    }

    /// A number the backend may send as a JSON number or as a numeric string
    /// (ipay types `additional` as `Object`, `amount` as `BigDecimal`).
    func decodeLenientDouble(forKey key: Key, in document: String) -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return value
        }
        if let text = try? decodeIfPresent(String.self, forKey: key) {
            if let value = Double(text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")) {
                return value
            }
            LenientDecoding.report(document: document, field: key.stringValue, detail: "not a number: \(text)")
            return nil
        }
        if contains(key), (try? decodeNil(forKey: key)) == false {
            LenientDecoding.report(document: document, field: key.stringValue, detail: "not a number")
        }
        return nil
    }

    /// An epoch-millis or other integer the backend may send as `long`, as a
    /// floating-point number or as a numeric string.
    func decodeLenientInt(forKey key: Key, in document: String) -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        guard let value = decodeLenientDouble(forKey: key, in: document), value.isFinite,
              value >= Double(Int.min), value < Double(Int.max) else {
            return nil
        }
        return Int(value)
    }
}
