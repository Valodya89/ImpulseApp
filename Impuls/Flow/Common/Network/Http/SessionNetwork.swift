//
//  SessionNetwork.swift
//  MimoBike
//
//  Created by Albert on 15.05.21.
//

import UIKit
import KeychainAccess

struct PreactivateStatusModel: Decodable {
    let status: PreactivateStatus
    let message: String
}

enum PreactivateStatus: Int, Decodable {
    case messageBlocked = 3
    case success = 0
}

enum NetworkSessionErrors: Error {
    case invalidRequest(request: URLRequest?, error: Error?)
    case resultsError(error: Error)
    case sessionExpired
    case invalidStatusCode(code: Int)
    case unknown(message: String)
    
    var description: String {
        switch self {
        case .invalidRequest(let request, let error):
            if let error {
                return "Invalid request: \(error.localizedDescription)"
            }
            return "Invalid request: \(request?.url?.absoluteString ?? "unknown URL")"
        case .resultsError(let error):
            return "Results error :\(error.localizedDescription)"
        case .sessionExpired:
            return "Session expired".localized()
        case .invalidStatusCode(code: let code):
            return "Invalid status code: \(code)"
        case .unknown:
            return "Internal server error. Please, try again."
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .invalidRequest(let request, let error):
            if let error {
                return "Invalid request: \(error.localizedDescription)"
            }
            return "Invalid request: \(request?.url?.absoluteString ?? "unknown URL")"
        case .resultsError(let error):
            return "Results error :\(error.localizedDescription)"
        case .sessionExpired:
            return "Session expired".localized()
        case .invalidStatusCode(code: let code):
            return "Invalid status code: \(code)"
        case .unknown:
            return "Internal server error. Please, try again."
        }
    }
}

/// Renews the JWT pair after a bare HTTP 401 (missing/expired access token
/// on /api/**). Shared by every `SessionNetwork` instance so that parallel
/// requests failing on the same expired token wait for ONE renewal and reuse
/// the new token. Only the renewal decision is serialised: the original
/// requests and their retries run outside the lock.
///
/// Backend contract (accounts, commit eb41a3e9):
/// - docs/mobile-api.md "POST /account/refresh-token": public, JSON body
///   `RefreshTokenDto { refreshToken, deviceId }` (Content-Type
///   application/json is mandatory), always HTTP 200 with the envelope:
///   `statusCode` 200 with `{ user: UserDto, token: JwtToken }` renews,
///   `statusCode` 401 means the refresh token was refused (undecodable,
///   expired, wrong signature). The call rebinds `User.activeDevice` to the
///   `deviceId` sent, so an empty one must never go out.
/// - docs/mobile-api.md "POST /account/start": public, rate-limited 5/min per
///   IP (raw `429` text when exceeded), body `SignOnDto { userId, deviceId }`,
///   `412 DEVICE_NOT_VERIFIED` envelope when the device must be re-verified.
/// - docs/authentication.md "Token issuance and shape": `JwtToken`
///   `{ access_token, refresh_token, expires_in, token_type, scope }`; the
///   refresh token is an HS512 JWT whose payload carries `exp`.
///
/// Rules that keep a dead session from looping through 401 -> refresh -> 5xx:
/// - a refresh token already expired by its own `exp` claim is not sent; a
///   stored value that is not a JWT is dropped by
///   `KeychainManager.getRefreshToken` and counts as "nothing to refresh with";
///   both go to the /account/start fallback, whose refusal ends the session;
/// - a plain 5xx or 415 from the refresh cannot come from a bad token (every
///   token decision is a 200 envelope): the request itself was malformed, so
///   it is reported as a client bug; the first one is taken as transient, a
///   second for the same refresh token is a refusal;
/// - after any attempt that did not renew, every 401 of the following 15 s is
///   answered without a new call: the burst of 401s a dead session produces
///   must not become a burst of calls;
/// - nothing is sent while the phone is still locked after a reboot (the
///   keychain is closed) or without a device id: the session is kept.
final class TokenRenewer {

    static let shared = TokenRenewer()

    enum Outcome {
        /// A fresh pair is stored; retry with the stored access token.
        case renewed
        /// The server answered without a token (refresh refused AND
        /// /account/start refused, or nothing to renew with). The session is
        /// invalid: sign out when the user is signed in.
        case rejected
        /// Transport error, HTTP error or unparsable body (raw 429 text, 5xx),
        /// a closed keychain, no device id, or an attempt too soon after a
        /// failed one. Keep the session and fail the request with its
        /// original 401.
        case unavailable
    }

    private let lock = NSLock()
    private var waiters: [(Outcome) -> Void] = []
    private var isRenewing = false
    private let keychainManager = KeychainManager()

    /// Refresh tokens (hashed) the server answered a plain 5xx / 415 to, with
    /// the count of consecutive such answers.
    private var serverFailures: [Int: Int] = [:]
    /// When the last attempt ended without a renewal; attempts are spaced out.
    private var lastFailureAt: Date?
    private static let retryInterval: TimeInterval = 15
    private static let serverFailuresBeforeGivingUp = 2

    private init() {}

    /// - Parameter failedToken: the bearer the failed request carried.
    /// - Parameter completion: called on the main queue exactly once.
    func renew(failedWith failedToken: String, completion: @escaping (Outcome) -> Void) {
        // Read before taking the lock: off the main thread this hops to main.
        let isKeychainOpen = KeychainHelper.isProtectedDataAvailable

        lock.lock()
        let stored = keychainManager.getAccessToken()
        // Another request already renewed the token this one failed with.
        if let stored, stored != failedToken {
            lock.unlock()
            DispatchQueue.main.async { completion(.renewed) }
            return
        }
        // The session is already gone (signed out while this request was in
        // flight): nothing to renew, and /account/start must not sign the
        // rider back in with the phone number that outlives a logout.
        guard stored != nil else {
            lock.unlock()
            DispatchQueue.main.async { completion(.rejected) }
            return
        }
        // The phone has not been unlocked since it booted: the keychain is
        // closed, nothing can be read, renewed or stored. Keep the session.
        guard isKeychainOpen else {
            lock.unlock()
            DispatchQueue.main.async { completion(.unavailable) }
            return
        }
        waiters.append(completion)
        guard !isRenewing else {
            lock.unlock()
            return
        }
        isRenewing = true

        // A renewal just failed: every request of the burst that follows a
        // dead session gets the same answer without another call (and
        // without moving the 15 s window).
        if let last = lastFailureAt, Date().timeIntervalSince(last) < Self.retryInterval {
            lock.unlock()
            finish(.unavailable, attempted: false)
            return
        }
        lock.unlock()

        refreshToken { [weak self] outcome in
            guard let self else { return }
            switch outcome {
            case .renewed, .unavailable:
                self.finish(outcome, attempted: true)
            case .rejected:
                // Refresh refused or not possible: legacy sign-on fallback.
                self.signOn { self.finish($0, attempted: true) }
            }
        }
    }

    /// Signs the user out once (idempotent across waiters) and routes to the
    /// login / device re-verification screen.
    /// - Returns: whether there was a session to end.
    @discardableResult
    func signOutIfSignedIn() -> Bool {
        lock.lock()
        let isSignedIn = keychainManager.getAccessToken() != nil
        if isSignedIn {
            keychainManager.removeData()
        }
        serverFailures.removeAll()
        lock.unlock()
        guard isSignedIn else { return false }
        DispatchQueue.main.async {
            UserManager.share.userResponse = nil
            BaseRouter.shared.showLoginView()
        }
        return true
    }

    // MARK: - Private

    /// - Parameter attempted: whether a renewal was actually tried (as
    ///   opposed to answered from the 15 s back-off); only an attempt that
    ///   did not renew starts the back-off.
    private func finish(_ outcome: Outcome, attempted: Bool) {
        lock.lock()
        let pending = waiters
        waiters.removeAll()
        isRenewing = false
        if case .renewed = outcome {
            lastFailureAt = nil
            serverFailures.removeAll()
        } else if attempted {
            lastFailureAt = Date()
        }
        lock.unlock()
        DispatchQueue.main.async {
            pending.forEach { $0(outcome) }
        }
    }

    /// The stored device identifier; empty while the keychain cannot be read
    /// (`DeviceCheckManager` never generates a second id in that state).
    private var deviceID: String {
        let current = DeviceCheckManager.shared.deviceUnicToken
        return current.isEmpty ? DeviceCheckManager.shared.checkAndSaveValueInKeychain() : current
    }

    /// POST /account/refresh-token with the stored refresh token.
    private func refreshToken(_ completion: @escaping (Outcome) -> Void) {
        // Nothing to refresh with (never stored, or a non-JWT value that
        // `getRefreshToken` just discarded): let /account/start decide.
        guard let refreshToken = keychainManager.getRefreshToken() else {
            completion(.rejected)
            return
        }

        // Expired by its own clock: the server would only answer the 401
        // envelope. Treated as refused without a call.
        if let expiry = KeychainManager.expiry(ofJWT: refreshToken), expiry < Date() {
            completion(.rejected)
            return
        }

        // The backend rebinds the account's active device to the id sent
        // here: an empty one (keychain not readable yet) must never go out.
        let deviceID = self.deviceID
        guard !deviceID.isEmpty else {
            completion(.unavailable)
            return
        }

        send(AuthAPI.refreshToken(refreshToken: refreshToken, deviceID: deviceID)) { [weak self] outcome in
            guard let self else { return }
            switch outcome {
            case .renewed:
                completion(.renewed)
            case .rejected:
                // The 401 envelope: the server refused the refresh token.
                // Let /account/start decide.
                completion(.rejected)
            case .unavailable(let status):
                guard let status, Self.isMalformedRequestAnswer(status) else {
                    // Offline, or answered without a usable envelope (plain-text
                    // 429 of the rate limiter): keep the session.
                    completion(.unavailable)
                    return
                }
                // Not an outage and not a token the server refused (that is
                // the 401 envelope): the request itself was malformed. Keep
                // the rider signed in once, in case it was a hiccup; twice
                // for the same token cannot succeed.
                Self.reportMalformedRequest(status: status)
                self.lock.lock()
                let key = refreshToken.hashValue
                let failures = (self.serverFailures[key] ?? 0) + 1
                self.serverFailures[key] = failures
                let givenUp = failures >= Self.serverFailuresBeforeGivingUp
                if givenUp { self.serverFailures[key] = nil }
                self.lock.unlock()
                completion(givenUp ? .rejected : .unavailable)
            }
        }
    }

    /// POST /account/start with the stored phone number (legacy fallback).
    private func signOn(_ completion: @escaping (Outcome) -> Void) {
        guard let phone = StorageManager().fetch(key: .phoneNumber, type: String.self), !phone.isEmpty else {
            completion(.rejected)
            return
        }
        send(AuthAPI.auth(userId: phone, deviceID: deviceID)) { completion($0.flattened) }
    }

    /// Answers from the refresh endpoint that only a malformed request
    /// produces: the controller answers every token decision inside a 200
    /// envelope, so a plain 5xx (Spring's firewall rejecting a form-parsed
    /// JSON body) or 415 (a body without a JSON content type) means the app
    /// built the request wrongly, not that the token is bad or the service
    /// is down.
    private static func isMalformedRequestAnswer(_ status: Int) -> Bool {
        status >= 500 || status == 415
    }

    /// A client bug worth a report of its own: with `Content-Type:
    /// application/json` on the request this can no longer come from a bad
    /// token. The 5xx itself is already reported by `NetworkFailureReporter`
    /// as an unhandled error; the abnormal-behaviour report names the cause
    /// so the two are not confused. No body and no token is attached.
    private static func reportMalformedRequest(status: Int) {
        ErrorReporter.shared.reportAbnormalBehavior(
            "POST /account/refresh-token answered \(status): the refresh request was malformed (client bug)",
            action: "tokenRefresh",
            extra: ["status": "\(status)"]
        )
    }

    private enum RawOutcome {
        case renewed
        case rejected
        /// `status` is nil for a transport error or a non-HTTP answer.
        case unavailable(status: Int?)

        var flattened: Outcome {
            switch self {
            case .renewed: return .renewed
            case .rejected: return .rejected
            case .unavailable: return .unavailable
            }
        }
    }

    /// The envelope of both renewal endpoints, read leniently. The refusal of
    /// a refresh comes as `{"statusCode":401,"status":"UNAUTHORIZED",
    /// "message":null,"content":null}`: `BaseResponseModel` requires `message`
    /// to be a string, so decoding it there fails and the refusal would be
    /// taken as a transient failure instead of a refusal.
    private struct RenewalEnvelope: Decodable {
        let statusCode: Int
        let content: SignInReponse?
    }

    /// Runs a renewal call outside the 401 handling of `SessionNetwork` and
    /// without the (expired) bearer: both endpoints are public. Only that
    /// header goes: `Content-Type: application/json` from `AuthAPI.header`
    /// must stay, or Spring reads the JSON body as a form parameter and
    /// answers a plain 500 / 415 before the controller runs.
    private func send(_ api: AuthAPI, _ completion: @escaping (RawOutcome) -> Void) {
        guard var request = URLBuilder(from: api).getRequst() else {
            completion(.unavailable(status: nil))
            return
        }
        request.setValue(nil, forHTTPHeaderField: "Authorization")
        #if DEBUG
        request.log()
        #endif
        SessionNetwork.sharedSession.dataTask(with: request) { data, response, error in
            NetworkFailureReporter.report(request: request, response: response, data: data, error: error)
            #if DEBUG
            (response as? HTTPURLResponse)?.log(data: data, error: error)
            #endif
            guard error == nil, let data, let http = response as? HTTPURLResponse else {
                completion(.unavailable(status: nil))
                return
            }
            // A 5xx never carries a decision; its body is Spring's plain
            // error object, not an envelope.
            guard http.statusCode < 500 else {
                completion(.unavailable(status: http.statusCode))
                return
            }
            // Business answers (200, 401 refusal, 406, 412, 429
            // RESEND_CODE_INTERVAL) are JSON envelopes; a 415 or the IP rate
            // limiter's plain text 429 is not parsable and counts as transient.
            guard let envelope = try? JSONDecoder().decode(RenewalEnvelope.self, from: data) else {
                completion(.unavailable(status: http.statusCode))
                return
            }
            guard envelope.statusCode == 200,
                  let content = envelope.content,
                  let accessToken = content.token?.accessToken, !accessToken.isEmpty else {
                completion(.rejected)
                return
            }
            self.lock.lock()
            self.keychainManager.parse(from: content)
            self.lock.unlock()
            if let user = content.user {
                UserManager.share.userResponse = user
            }
            completion(.renewed)
        }.resume()
    }
}

final class SessionNetwork: SessionProtocol {

    /// One session for every request. A session made per request and never
    /// invalidated keeps its delegate queue and sockets alive, which after long
    /// use exhausts the process ("Cannot allocate memory", NSPOSIXErrorDomain 12).
    fileprivate static let sharedSession = URLSession(configuration: .default)

    private var keychainManager = KeychainManager()
    
    /// Set view controller as root
    func setRootViewController(_ vc: UIViewController) {
        UIApplication.shared.windows.first?.rootViewController = vc
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    func request(with builderProtocol: URLBuilderProtocol, _ completion: @escaping (Result<Data,NetworkSessionErrors>) -> (), _ queue: DispatchQueue = .global()) {
        perform(builderProtocol, completion, queue, allowRenewal: true)
    }

    /// Sends the request. On a bare 401 (expired/invalid JWT) the token pair
    /// is renewed once through `TokenRenewer` and the request is retried once
    /// with the new bearer (`allowRenewal: false`), never more.
    private func perform(_ builderProtocol: URLBuilderProtocol,
                         _ completion: @escaping (Result<Data,NetworkSessionErrors>) -> (),
                         _ queue: DispatchQueue,
                         allowRenewal: Bool) {
        queue.async {
            guard let request = builderProtocol.getRequst() else {
                completion(.failure(.resultsError(error: NetworkError.validatorError("Invalide request"))))
                return
            }
            
            #if DEBUG
            request.log()
            #endif
            
            SessionNetwork.sharedSession.dataTask(with: request) { [weak self] data, response, error in
                // Error reporting: 5xx and transport failures go to POST /mobile-errors.
                NetworkFailureReporter.report(request: request, response: response, data: data, error: error)

                if !(request.url?.absoluteString.contains("/api/notification") ?? false) { // TODO: Need to fix API response
                    #if DEBUG
                    (response as? HTTPURLResponse)?.log(data: data, error: error)
                    #endif
                }
                
                DispatchQueue.main.async {
                    guard error == nil else {
                        completion(.failure(.invalidRequest(request: request, error: error)))
                        return
                    }
                    guard let data = data else {
                        completion(.failure(.invalidRequest(request: request, error: nil)))
                        return
                    }
                    
                    guard let response = response as? HTTPURLResponse else {
                        completion(.failure(.invalidRequest(request: request, error: nil)))
                        return
                    }
                    if response.statusCode == 500 {
                        completion(.failure(.unknown(message: "Internal server error. Please, try again.")))
                        return
                    }
                    
                    // An action refused for unmet rules (402/412) lists them in
                    // `content.violations`. Keep them for the screen showing the
                    // error, and hand the body on so the caller reads the
                    // envelope's own status and message instead of being signed out.
                    let isRejectedAction = response.statusCode != 401
                        && ActionRejectionStore.shared.record(data: data, request: request) != nil

                    guard (200 ..< 299) ~= response.statusCode || isRejectedAction else {
                        print("ERROR : \(response)")
                        if response.statusCode == 401 {
                            self?.handleUnauthorized(request: request,
                                                     builderProtocol: builderProtocol,
                                                     completion,
                                                     queue,
                                                     allowRenewal: allowRenewal)
                            return
                        } else if response.statusCode > 401 {
                            AccountViewModel().logout(complation: {
                                
//                                let splashVC = SplashViewController.initFromStoryboard(name: Constant.Storyboards.splash)
//                                UIApplication.topController()?.setRootViewController(splashVC)
                                BaseRouter.shared.showSplashView()
                            })
                            completion(.failure(.invalidStatusCode(code: response.statusCode)))
                            return
                        }
                        completion(.failure(.invalidStatusCode(code: response.statusCode)))
                        return
                    }
                    
                    completion(.success(data))
                    return
                }
            }.resume()
        }
    }

    /// Bare 401: renew once and retry once; sign out only when the renewal is
    /// refused by the server for a signed-in user. `PUT api/user/device`
    /// keeps its legacy exemption from signing out. As before, a request that
    /// ends in a sign-out is not completed (the login screen replaces the
    /// caller's screen); every other 401 is returned to the caller.
    private func handleUnauthorized(request: URLRequest,
                                    builderProtocol: URLBuilderProtocol,
                                    _ completion: @escaping (Result<Data,NetworkSessionErrors>) -> (),
                                    _ queue: DispatchQueue,
                                    allowRenewal: Bool) {
        let isDeviceEndpoint = request.url?.absoluteString.contains("user/device") ?? false
        let failedToken = request.value(forHTTPHeaderField: "Authorization")?
            .replacingOccurrences(of: "Bearer ", with: "")

        // No bearer was sent: the user is not signed in, return the 401.
        guard let failedToken, !failedToken.isEmpty else {
            completion(.failure(.invalidStatusCode(code: 401)))
            return
        }

        // The retried request was refused with the renewed token as well.
        guard allowRenewal else {
            signOutOrReturn401(isDeviceEndpoint: isDeviceEndpoint, completion)
            return
        }

        TokenRenewer.shared.renew(failedWith: failedToken) { [weak self] outcome in
            switch outcome {
            case .renewed:
                // URLBuilder reads the bearer from the keychain on rebuild.
                builderProtocol.rebuild()
                self?.perform(builderProtocol, completion, queue, allowRenewal: false)
            case .rejected:
                self?.signOutOrReturn401(isDeviceEndpoint: isDeviceEndpoint, completion)
            case .unavailable:
                // Offline or the auth service is unavailable: keep the session.
                completion(.failure(.invalidStatusCode(code: 401)))
            }
        }
    }

    private func signOutOrReturn401(isDeviceEndpoint: Bool,
                                    _ completion: @escaping (Result<Data,NetworkSessionErrors>) -> ()) {
        guard !isDeviceEndpoint else {
            completion(.failure(.invalidStatusCode(code: 401)))
            return
        }
        // No session to end (already signed out): the caller gets its 401
        // instead of a completion that never comes.
        if !TokenRenewer.shared.signOutIfSignedIn() {
            completion(.failure(.invalidStatusCode(code: 401)))
        }
    }
}

public extension URLRequest {
    func log(){
        
        if CommandLine.arguments.contains("-disable-network-log") {
            return
        }
        
        let urlString = url?.absoluteString ?? ""
        let components = NSURLComponents(string: urlString)
        
        let method = httpMethod != nil ? "🟡 \(httpMethod ?? "")" : ""
        let path = "\(components?.path ?? "")"
        let query = "\(components?.query ?? "")"
        let host = "\(components?.host ?? "")"
        
        var requestLog = "\n>>================= REQUEST =================>>\n"
        requestLog += "\(urlString)"
        requestLog += "\n\n"
        requestLog += "\(method) \(path)?\(query) HTTP/1.1\n"
        requestLog += "Host: \(host)\n"
        for (key, value) in allHTTPHeaderFields ?? [:] {
            requestLog += "\(key): \(value)\n"
        }
        if let body = httpBody {
            requestLog += "\n\(String(data: body, encoding: .utf8) ?? "")\n"
        }
        
        requestLog += "\n>>===========================================>>\n";
        print(requestLog)
    }
}

public extension HTTPURLResponse {
    func log(data: Data?, error: Error?) {
        
        if CommandLine.arguments.contains("-disable-network-log") {
            return
        }
        
        let urlString = url?.absoluteString
        let components = NSURLComponents(string: urlString ?? "")
        
        let path = "\(components?.path ?? "")"
        let query = "\(components?.query ?? "")"
        
        var responseLog = "\n<<================= RESPONSE =================<<\n"
        if let urlString = urlString {
            responseLog += "\(urlString)"
            responseLog += "\n\n"
        }
        
        let statusColorSign = (statusCode >= 200 && statusCode < 300) ? "🟢" : "🔴"
        responseLog += "HTTP \(statusColorSign) \(statusCode) \(path)?\(query)\n"
        if let host = components?.host {
            responseLog += "Host: \(host)\n"
        }
        for (key, value) in allHeaderFields {
            responseLog += "\(key): \(value)\n"
        }
        if let body = data {
            responseLog += "\n\(body.prettyPrintedJSONString ?? "")\n"
        }
        if error != nil {
            responseLog += "\n 🔺 Error: \(error?.localizedDescription ?? "")\n"
        }
        
        responseLog += "<<===========================================<<\n";
        print(responseLog)
    }
}

public extension Data {
    /// Append string to Data
    ///
    /// Rather than littering my code with calls to `data(using: .utf8)` to convert `String` values to `Data`, this wraps it in a nice convenient little extension to Data. This defaults to converting using UTF-8.
    ///
    /// - parameter string:       The string to be added to the `Data`.
    mutating func append(_ string: String, using encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }
    
    var prettyPrintedJSONString: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = String(data: data, encoding: .utf8) else { return nil }
        
        return prettyPrintedString
    }
}
