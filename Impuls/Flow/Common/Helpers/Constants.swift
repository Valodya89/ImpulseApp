//
//  Constants.swift
//  MimoBike
//
//  Created by Vardan on 15.04.21.
//

import Foundation
import UIKit

struct Constant {
    
    static let screenSize = UIScreen.main.bounds

    /// Upper-case ISO alpha-3 country sent as the `country` header on every API
    /// request and used in the legal page URLs. Impulse operates in Russia only.
    static let requestCountryCode: String? = "RUS"
    
    struct APIKeys {
        static let GOOGLE_MAPS_API_KEY = "AIzaSyBBnsPKB01veDAEZd0MYs13FFuwJJi7KKo"
    }

    struct Storyboards {
        static let splash = "Splash"
        static let signIn = "SignIn"
        static let map = "Map"
        static let home = "Home"
        static let completeAccount = "CompleteAccount"
        static let account = "Account"
        static let accountCover = "AccountCover"
        static let scan = "Scan"
        static let wallet = "Wallet"
        static let transfer = "Transfer"
        static let plan = "MIPlan"
        static let orderCard = "OrderCard"
        static let scooterPlan = "ScooterPlan"
        static let parkingPhotoCamera = "ParkingPhotoCamera"
    }
   
    struct CellIdentifiers {
        
    }
    
    struct Segues {

    }
    
    struct NotificationNames {
    }
    
    /// calculations based on iPhone 11 pro screen size  (375 x 812)
    struct CornerRadius {
        
        /// proportions from height
        static let cornerRadius8 = screenSize.height * 0.009852216749
        static let cornerRadius12 = screenSize.height * 0.01477832512
        static let cornerRadius19 = screenSize.height * 0.023399015
        static let cornerRadius21 = screenSize.height * 0.02586206897
        static let cornerRadius23 = screenSize.height * 0.02832512315
        static let cornerRadius24 = screenSize.height * 0.02955665025
        static let cornerRadius32 = screenSize.height * 0.039408867
        static let cornerRadius53 = screenSize.height * 0.06527093596

        /// proportions from width
        static let cornerRadiusFromScreenWidth8 = screenSize.width * 0.02133333333
        static let cornerRadiusFromScreenWidth17half = screenSize.width * 0.04666666667
        static let cornerRadiusFromScreenWidth19 = screenSize.width * 0.05066666667
        static let cornerRadiusFromScreenWidth20 = screenSize.width * 0.05333333333
        static let cornerRadiusFromScreenWidth24 = screenSize.width * 0.064
    }
    
    struct Height {
        
        static let height15 = screenSize.height * 0.0184729064
        static let height37 = screenSize.height * 0.04556650246
        static let height54 = screenSize.height * 0.06650246305
        static let height70 = screenSize.height * 0.08620689655
        static let height106 = screenSize.height * 0.1305418719
        static let height184 = screenSize.height * 0.226601
    }
    
    struct Width {
        
        static let width15 = screenSize.width *  0.04
        static let width68 = screenSize.width *  0.1813333333
        static let width79 = screenSize.width * 0.2106666667
        static let width200 = screenSize.width * 0.5333333333
        static let width250 = screenSize.width * 0.6666666667
        static let width288 = screenSize.width * 0.768
        static let width335 = screenSize.width * 0.8933
        
        static let width075 = screenSize.width * 0.75
        static let width085 = screenSize.width * 0.85
    }
    
    struct Constraint {
        static let constant15 = screenSize.height * 0.0184729064
        static let constant37 = screenSize.height * 0.04556650246
        static let constant72 = screenSize.height * 0.08866995074
        static let constant184 = screenSize.height * 0.166601
        static let constant224 = screenSize.height * 0.275862069
    }
    
    struct URLString {
        /// Legal pages: https://privacy.impulsepower.ru/<COUNTRY>/<language>/<slug>.
        /// The country segment is the same upper-case ISO alpha-3 value the app
        /// sends in the `country` request header and is omitted when unknown;
        /// the site serves the default document for a country without its own
        /// page, so it is always appended when known (never a country list).
        private static let legalHost = "https://privacy.impulsepower.ru"

        enum LegalDocument: String {
            case agreement = "agreement"
            case privacyPolicy = "privacy-policy"
        }

        static func legalURL(_ document: LegalDocument, language: String? = nil) -> URL {
            let language = (language ?? StorageManager().fetch(key: .language, type: String.self)
                            ?? String(Locale.preferredLanguages[0].prefix(2)))
            var segments = [legalHost]
            if let country = Constant.requestCountryCode, !country.isEmpty {
                segments.append(country.uppercased())
            }
            segments.append(language)
            segments.append(document.rawValue)
            return URL(string: segments.joined(separator: "/"))!
        }
    }
    
    struct Lottie {
        static let logo = "logo"
        static let bike = "bike"
        static let plus = "plus"
    }
    
    struct MeasureName {
        static let distance = "km"
        static let calories = "kcal"
        static let carbon = "car"
    }
    
    struct Font {
        static let robotoBold = "Roboto-Bold"
    }
    
    struct Notifications {
        static let LanguageUpdate = NSNotification.Name(rawValue: "Mimo.Notification.Language")
        static let updateUserUI = NSNotification.Name(rawValue: "Mimo.Notification.UpdateUser")
        static let updateUserPicture = NSNotification.Name(rawValue: "Mimo.Notification.UpdatePicture")
        static let updateFinansialState = NSNotification.Name(rawValue: "Mimo.Notification.UpdatePicture")
        static let accountVerified = NSNotification.Name(rawValue: "Mimo.Notification.AccountVerified")
        static let updateBlureState = NSNotification.Name(rawValue: "Mimo.Notification.updateBlureState")
        static let emailVerificationCode = NSNotification.Name(rawValue: "Mimo.Notification.emailVerificationCode")
        static let paymentCallback = NSNotification.Name(rawValue: "Mimo.Notification.paymentCallback")
        static let ThemeUpdate = NSNotification.Name(rawValue: "Mimo.Notification.Theme")
        /// Fresh backend translations were merged into the in-memory dictionary.
        static let TranslationsUpdate = NSNotification.Name(rawValue: "Mimo.Notification.Translations")
        /// A station App Link (https://accounts.impulsepower.ru/scan/{code}) was opened
        /// while the app is running; the code is held in `HomeRouter` until Home takes it.
        static let stationScanLink = NSNotification.Name(rawValue: "Mimo.Notification.stationScanLink")
    }
}

/// Bundled support contacts: the transitional fallback shown until the
/// accounts service has answered GET /contact-info (see `SupportContactsStore`)
/// and kept when it cannot be reached. Delete once every Impulse environment
/// serves the endpoint with an Impulse row.
enum SupportContact {
    /// Impulse support hotline, E.164 (the same number Impulse Android dials).
    static let hotline = "+79165132326"
    /// Telegram channel id of the Impulse support chat (the same id Impulse
    /// Android opens). An `https://t.me` link is handed to the Telegram app
    /// when it is installed and opens in the browser otherwise, so no `tg://`
    /// scheme (or `canOpenURL` check) is needed.
    static let telegramChannelId = "impulse_power_help"
    static let telegramChatURLString = "https://t.me/\(telegramChannelId)"
    static var telegramChatURL: URL? { URL(string: telegramChatURLString) }
}

// MARK: - Support contacts from the server (GET /contact-info)

/// `ContactInfo` as the accounts service returns it inside the standard
/// envelope (accounts docs/mobile-api.md "GET /contact-info
/// (`ContactInfoController`)", commit 499a79b8). Every field is optional:
/// `null` means "this contact does not exist for the app and country".
struct ContactInfoDto: Decodable {
    let id: String?
    let application: String?
    /// `"*"` when the app's default row was returned, else ISO alpha-3.
    let country: String?
    /// E.164 hotline, dialled as returned.
    let phone: String?
    /// What follows `t.me/`; informational, the link is `telegramUrl`.
    let telegram: String?
    /// `https://t.me/<telegram>`, opened as returned (public chat or invite).
    let telegramUrl: String?
    /// WhatsApp support number in E.164; informational, the link is `whatsappUrl`.
    let whatsapp: String?
    /// `https://wa.me/<digits>`, opened as returned (app or WhatsApp Web).
    let whatsappUrl: String?
}

/// The support contacts every entry point shows: Profile > Support, the map
/// support banner and the live-session row. One value for the whole app,
/// held by `SupportContactsStore`.
struct SupportContacts: Equatable {

    enum Messenger: Equatable {
        case telegram
        case whatsapp
    }

    /// E.164 hotline; nil = no hotline, "Call now" is hidden.
    let phone: String?
    /// nil = no Telegram chat, its entry point is hidden.
    let telegramURL: URL?
    /// nil = no WhatsApp chat, its entry point is hidden.
    let whatsappURL: URL?

    init(phone: String?, telegramURL: URL?, whatsappURL: URL?) {
        self.phone = phone
        self.telegramURL = telegramURL
        self.whatsappURL = whatsappURL
    }

    /// nil when the row carries no contact at all (the server promises at
    /// least one, so such an answer is treated as unusable, not as "hidden").
    init?(dto: ContactInfoDto) {
        let phone = dto.phone?.trimmingCharacters(in: .whitespacesAndNewlines)
        let telegramURL = dto.telegramUrl.flatMap(Self.httpURL)
        let whatsappURL = dto.whatsappUrl.flatMap(Self.httpURL)
        let hotline = (phone?.isEmpty == false) ? phone : nil
        guard hotline != nil || telegramURL != nil || whatsappURL != nil else { return nil }
        self.init(phone: hotline, telegramURL: telegramURL, whatsappURL: whatsappURL)
    }

    /// The bundled defaults (`SupportContact`): what is shown before the first
    /// server answer and when the server cannot be reached.
    static let bundled = SupportContacts(phone: SupportContact.hotline,
                                         telegramURL: SupportContact.telegramChatURL,
                                         whatsappURL: nil)

    /// Only `https://t.me` / `https://wa.me` style links are opened; anything
    /// else (an empty string, a custom scheme) is ignored.
    private static func httpURL(_ string: String) -> URL? {
        guard let url = URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http" else {
            return nil
        }
        return url
    }

    /// The chat entry points to show, Telegram first.
    var messengers: [Messenger] {
        var result: [Messenger] = []
        if telegramURL != nil { result.append(.telegram) }
        if whatsappURL != nil { result.append(.whatsapp) }
        return result
    }

    func url(for messenger: Messenger) -> URL? {
        switch messenger {
        case .telegram: return telegramURL
        case .whatsapp: return whatsappURL
        }
    }

    /// `tel://+E.164`, the number exactly as the server returned it.
    var dialURL: URL? {
        guard let phone, !phone.isEmpty else { return nil }
        return URL(string: "tel://\(phone)")
    }

    var hasAnyContact: Bool {
        phone != nil || telegramURL != nil || whatsappURL != nil
    }

    /// The hotline for display: an 11-digit Russian number as
    /// "+7 (916) 513 23 26", anything else as returned.
    var displayPhone: String? {
        guard let phone else { return nil }
        let digits = phone.filter(\.isNumber)
        guard digits.count == 11, phone.hasPrefix("+") else { return phone }
        let d = Array(digits)
        return "+\(d[0]) (\(String(d[1...3]))) \(String(d[4...6])) \(String(d[7...8])) \(String(d[9...10]))"
    }
}

/// What one GET /contact-info call ended in.
enum ContactInfoOutcome {
    /// Envelope `statusCode` 200: use these contacts.
    case contacts(SupportContacts)
    /// Envelope `statusCode` 404 `ACCOUNTS_contact_info_not_found`: the app
    /// has no row for the country and no default row, hide every entry point.
    case notFound
    /// Transport error, HTTP error (a deployment without the endpoint answers
    /// a plain 404; 5xx) or a body that is not the envelope: keep what is shown.
    case unavailable
}

/// Loads the support contacts from GET /contact-info once per app start (on
/// the first entry point that needs them), retries a failed load, and reloads
/// after sign-in when the user's country differs from the one requested.
/// Observers listen to `SupportContactsStore.didChange` (main queue).
///
/// `contacts` is nil only after the server said the app has no contacts at
/// all (hide everything); before the first answer and after a failed load it
/// is the bundled fallback or the last successful answer.
final class SupportContactsStore: SubscriberProtocol {

    static let shared = SupportContactsStore()
    static let didChange = Notification.Name(rawValue: "Mimo.Notification.SupportContactsChanged")

    var id: String = UUID().uuidString

    private(set) var contacts: SupportContacts? = .bundled
    /// true once the server has answered (200 or 404) for `requestedCountry`.
    private var lastLoadSucceeded = false
    private var isLoading = false
    private var requestedCountry: String?
    private var failedAttempts = 0
    private let repository = AuthRepository()

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(userChanged),
                                               name: Constant.Notifications.updateUserUI, object: nil)
        Resolver.optional(MessageServiceProtocol.self)?.subscribe(self, for: .refreshUser)
    }

    /// The country the contacts are asked for: the country the user signed up
    /// from (`User.country`, GET /api/user) when signed in, else the country
    /// the app operates in. Upper-case ISO alpha-3, nil when unknown (the
    /// `country` header then decides on the server).
    var currentCountry: String? {
        let isSignedIn = KeychainManager().getAccessToken() != nil
        let raw = (isSignedIn ? UserManager.share.userResponse?.country : nil) ?? Constant.requestCountryCode
        let code = raw?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
        return code.isEmpty ? nil : code
    }

    /// Loads once; later calls only reload after a failed load or when the
    /// country changed (sign-in). Cheap to call from every entry point.
    func loadIfNeeded() {
        guard !isLoading else { return }
        if lastLoadSucceeded && requestedCountry == currentCountry { return }
        load()
    }

    private func load() {
        let country = currentCountry
        isLoading = true
        requestedCountry = country
        repository.getContactInfo(country: country) { [weak self] outcome in
            guard let self else { return }
            self.isLoading = false
            switch outcome {
            case .contacts(let contacts):
                self.lastLoadSucceeded = true
                self.failedAttempts = 0
                self.apply(contacts)
            case .notFound:
                // Transitional, as Impulse Android: the live Impulse deployment
                // has no contact row yet (envelope 404). Keep the bundled hotline
                // and chat until an admin adds one, instead of hiding support.
                self.lastLoadSucceeded = true
                self.failedAttempts = 0
                self.apply(.bundled)
            case .unavailable:
                self.lastLoadSucceeded = false
                self.failedAttempts += 1
                self.scheduleRetry()
            }
            // The user signed in while the request was in flight.
            if self.lastLoadSucceeded && self.requestedCountry != self.currentCountry {
                self.load()
            }
        }
    }

    private func apply(_ new: SupportContacts?) {
        guard new != contacts else { return }
        contacts = new
        NotificationCenter.default.post(name: Self.didChange, object: self)
    }

    /// A failed load is retried a few times with a growing delay; after that
    /// the next entry point or sign-in event retries.
    private func scheduleRetry() {
        guard failedAttempts <= 3 else { return }
        let delay = TimeInterval(failedAttempts) * 20
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.loadIfNeeded()
        }
    }

    @objc private func userChanged() {
        loadIfNeeded()
    }

    // MARK: SubscriberProtocol

    func receive(message: MessageKey) {
        if message == .refreshUser {
            loadIfNeeded()
        }
    }

    func unsubscribe() {
        Resolver.optional(MessageServiceProtocol.self)?.unsubscribe(self, from: .refreshUser)
    }
}
