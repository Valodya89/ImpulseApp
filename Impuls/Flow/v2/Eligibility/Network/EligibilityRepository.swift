//
//  EligibilityRepository.swift
//  Impuls
//

import Foundation

enum EligibilityError: Error {
    /// The pre-check itself could not be read (offline, not deployed, bad body).
    case unavailable
}

final class EligibilityRepository {

    private struct Envelope: Decodable {
        let statusCode: Int?
        let content: EligibilityResult?
    }

    /// Runs the pre-check. A violated rule is a success with `satisfied == false`;
    /// a failure only means the check could not be read.
    ///
    /// Sent outside `SessionNetwork` on purpose: that session signs the rider
    /// out on any status above 401, which a pre-check must never cause.
    func check(_ check: EligibilityCheck, completion: @escaping (Result<EligibilityResult, EligibilityError>) -> Void) {
        guard let request = URLBuilder(from: check).getRequst() else {
            completion(.failure(.unavailable))
            return
        }

        #if DEBUG
        request.log()
        #endif

        URLSession.shared.dataTask(with: request) { data, response, error in
            #if DEBUG
            (response as? HTTPURLResponse)?.log(data: data, error: error)
            #endif

            var result: Result<EligibilityResult, EligibilityError> = .failure(.unavailable)

            if let data,
               let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
               let content = envelope.content,
               (200..<300).contains(envelope.statusCode ?? 200) {
                result = .success(content)
            }

            DispatchQueue.main.async { completion(result) }
        }.resume()
    }
}

/// Remembers the last action the backend refused for unmet rules.
///
/// The legacy error chain carries a message string only (`NetworkError`,
/// `WalletRequestErrors`, `MimoError`), so the violations cannot travel with
/// the error. `SessionNetwork` records them here as the response arrives, and
/// the screen that receives the message picks them up by that same message.
final class ActionRejectionStore {

    static let shared = ActionRejectionStore()

    private var rejection: ActionRejection?
    private var recordedAt = Date.distantPast

    /// A rejection is only meaningful for the error being shown right now.
    private let lifetime: TimeInterval = 15

    private init() {}

    @discardableResult
    func record(data: Data, request: URLRequest?) -> ActionRejection? {
        guard let rejection = ActionRejection.parse(data: data, request: request) else { return nil }

        self.rejection = rejection
        recordedAt = Date()

        return rejection
    }

    /// The rejection behind `message`, if that is the error it produced.
    func take(matching message: String?) -> ActionRejection? {
        guard let rejection, let message,
              Date().timeIntervalSince(recordedAt) < lifetime,
              message == rejection.message || rejection.violations.contains(where: { $0.code == message }) else {
            return nil
        }

        self.rejection = nil

        return rejection
    }
}
