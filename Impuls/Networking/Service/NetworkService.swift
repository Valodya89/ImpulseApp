//
//  NetworkService.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.06.24.
//

import Combine

class NetworkService {
    func request<T: Decodable>(_ endpoint: Endpointable, authorization: Bool = true) -> AnyPublisher<T, APIError> {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        if let parameters = endpoint.parameters {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                let jsonData = try JSONEncoder().encode(parameters)
                request.httpBody = jsonData
            } catch {
                return Fail(error: APIError.requestFailed("Encoding parameters failed.")).eraseToAnyPublisher()
            }
        }
        
        endpoint.headers?.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        request.addValue("IOS", forHTTPHeaderField: "os-type")
        request.addValue(appVersion, forHTTPHeaderField: "app-version")
        request.addValue(StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.current.deviceLanguageCode), forHTTPHeaderField: "locale")
        
        if let countryCode = ApplicationSettings.shared.isoCountryCode {
            request.addValue(countryCode, forHTTPHeaderField: "country")
        }
        
        if authorization {
            let keychainManager = KeychainManager()
            if let token = keychainManager.getAccessToken() {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                return Fail(error: APIError.authorizationError).eraseToAnyPublisher()
            }
        }
        
        #if DEBUG
        request.log()
        #endif
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .handleEvents(receiveOutput: { output in
                #if DEBUG
                (output.response as? HTTPURLResponse)?.log(data: output.data, error: nil)
                #endif
            })
            .tryMap { (data, response) -> Data in
                if let httpResponse = response as? HTTPURLResponse,
                   (200..<300).contains(httpResponse.statusCode) {
                    return data
                } else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    if statusCode == 401 {
                        KeychainManager().removeData()
                        throw APIError.authorizationError
                    }
                    throw APIError.requestFailed("Request failed with status code: \(statusCode)")
                }
            }
            .decode(type: ResponseWrapper<T>.self, decoder: JSONDecoder())
            .tryMap { (responseWrapper) -> T in
                let status = responseWrapper.statusCode
                switch status {
                case 200:
                    guard let data = responseWrapper.content else {
                        throw APIError.missingData(status)
                    }
                    return data
                case 401:
                    KeychainManager().removeData()
                    throw APIError.authorizationError
                default:
                    let message = responseWrapper.message
                    throw APIError.responseError(message)
                }
            }
            .mapError { error -> APIError in
                if error is DecodingError {
                    return APIError.decodingFailed(error.localizedDescription)
                } else if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.requestFailed("An unknown error occurred.")
                }
            }
            .eraseToAnyPublisher()
    }
}

private extension NetworkService {
    
    var appVersion: String {
        var version = ""
        
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            let components = appVersion.components(separatedBy: ".")
            if components.count > 2 {
                version = "\(components[0]).\(components[1])\(components[2])"
            } else {
                version = "\(components[0]).\(components[1])"
            }
        }
        
        return version
    }
}
