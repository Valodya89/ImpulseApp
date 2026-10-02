//
//  RequirementsProfileService.swift
//  Impuls
//
//  The profile data the rules ask for:
//    PUT  api/user            name, surname, gender, birthday, email, country,
//                             address { country, city, street, postalCode }
//    POST api/user/documents  multipart: type, frontSide, backSide, documentNumber
//

import UIKit

enum IdentityDocumentType: String, CaseIterable {
    case idCard = "ID_CARD"
    case passport = "PASSPORT"

    var title: String {
        switch self {
        case .idCard:
            return "MOBILE_document_type_id_card".localized(fallback: "ID card")
        case .passport:
            return "MOBILE_document_type_passport".localized(fallback: "Passport")
        }
    }
}

struct RequirementsServiceError: Error {
    /// Backend message key, or nil when the request did not reach the backend.
    let code: String?

    var message: String {
        guard let code, !code.isEmpty else {
            return "MOBILE_requirements_save_failed".localized(fallback: "Your details could not be saved. Please try again.")
        }

        return UIViewController.userFacingErrorMessage(from: code)
    }
}

final class RequirementsProfileService {

    private let network = SessionNetwork()

    /// The rider's profile as raw JSON: the address and country are not part of
    /// `UserResponse`, and only prefill the form. Nil when it could not be read.
    func loadProfile(completion: @escaping ([String: Any]?) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getUser)) { result in
            guard case .success(let data) = result,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [String: Any] else {
                completion(nil)
                return
            }

            completion(content)
        }
    }

    func updateProfile(_ body: [String: Any], completion: @escaping (Result<Void, RequirementsServiceError>) -> Void) {
        network.request(with: URLBuilder(from: RequirementsProfileAPI.updateUser(body: body))) { result in
            switch result {
            case .success(let data):
                completion(Self.result(from: data))
            case .failure:
                completion(.failure(RequirementsServiceError(code: nil)))
            }
        }
    }

    /// Sent outside `SessionNetwork`, which has no multipart body with named
    /// file parts.
    func uploadDocument(type: IdentityDocumentType,
                        front: UIImage?,
                        back: UIImage?,
                        documentNumber: String?,
                        completion: @escaping (Result<Void, RequirementsServiceError>) -> Void) {
        guard let url = URL(string: MimoBaseURLs.accounts.rawValue + "api/user/documents"),
              let token = KeychainManager().getAccessToken() else {
            completion(.failure(RequirementsServiceError(code: nil)))
            return
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = RequestMethod.post.rawValue
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("IOS", forHTTPHeaderField: "os-type")

        var body = Data()
        body.appendFormField(name: "type", value: type.rawValue, boundary: boundary)

        if let documentNumber, !documentNumber.isEmpty {
            body.appendFormField(name: "documentNumber", value: documentNumber, boundary: boundary)
        }

        if let data = front.flatMap(Self.jpegData) {
            body.appendFileField(name: "frontSide", fileName: "document-front.jpg", data: data, boundary: boundary)
        }

        if let data = back.flatMap(Self.jpegData) {
            body.appendFileField(name: "backSide", fileName: "document-back.jpg", data: data, boundary: boundary)
        }

        body.append("--\(boundary)--\r\n")

        // Uploaded from memory, so no copy of the document is left on disk.
        URLSession(configuration: .ephemeral).uploadTask(with: request, from: body) { data, _, error in
            var result: Result<Void, RequirementsServiceError> = .failure(RequirementsServiceError(code: nil))

            if error == nil, let data {
                result = Self.result(from: data)
            }

            DispatchQueue.main.async { completion(result) }
        }.resume()
    }

    /// The accounts service answers 200 with the real status in the envelope.
    private static func result(from data: Data) -> Result<Void, RequirementsServiceError> {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let statusCode = json["statusCode"] as? Int else {
            return .failure(RequirementsServiceError(code: nil))
        }

        guard (200..<300).contains(statusCode) else {
            return .failure(RequirementsServiceError(code: json["message"] as? String))
        }

        return .success(())
    }

    /// The service caps a part at 5 MB; the long edge is limited first so the
    /// text on the document stays legible after compression.
    private static func jpegData(from image: UIImage) -> Data? {
        let maxBytes = 5 * 1024 * 1024
        let resized = image.resizedForUpload(maxDimension: 2000)

        for quality in [CGFloat(0.8), 0.6, 0.4] {
            if let data = resized.jpegData(compressionQuality: quality), data.count <= maxBytes {
                return data
            }
        }

        return resized.jpegData(compressionQuality: 0.3)
    }
}

private enum RequirementsProfileAPI: APIProtocol {
    case updateUser(body: [String: Any])

    var base: String { MimoBaseURLs.accounts.rawValue }
    var path: String { "api/user" }
    var header: [String: String] { ["Content-Type": "application/json"] }
    var query: [String: String] { [:] }

    var body: [String: Any]? {
        switch self {
        case .updateUser(let body):
            return body
        }
    }

    var bodyString: String? { nil }
    var formData: MultipartFormData? { nil }
    var method: RequestMethod { .put }
}

private extension Data {

    mutating func appendFormField(name: String, value: String, boundary: String) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        append("\(value)\r\n")
    }

    mutating func appendFileField(name: String, fileName: String, data: Data, boundary: String) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
        append("Content-Type: image/jpeg\r\n\r\n")
        append(data)
        append("\r\n")
    }
}

private extension UIImage {

    func resizedForUpload(maxDimension: CGFloat) -> UIImage {
        let longEdge = max(size.width, size.height)
        guard longEdge > maxDimension else { return self }

        let scale = maxDimension / longEdge
        let target = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
