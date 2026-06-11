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

final class SessionNetwork: SessionProtocol {
    
    private var dispatchWorkItem: DispatchWorkItem? = nil
    private var needAccessTokenUpdate: Bool = true
    private var keychainManager = KeychainManager()
    
    lazy var noInternet: NoInternetViewController = {
        let homeVC = NoInternetViewController.initFromStoryboard(name: Constant.Storyboards.splash)
        return homeVC
    }()
    
    /// Set view controller as root
    func setRootViewController(_ vc: UIViewController) {
        UIApplication.shared.windows.first?.rootViewController = vc
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    func request(with builderProtocol: URLBuilderProtocol, _ completion: @escaping (Result<Data,NetworkSessionErrors>) -> (), _ queue: DispatchQueue = .global()) {
        
        if builderProtocol.getRequst()?.url?.absoluteString.contains("api/user") ?? false {
            print("")
        }
        
        if Reachability.isConnectedToNetwork(){
            print("Internet Connection Available!")
        } else {
//            let splashVC = NoInternetViewController.initFromStoryboard(name: Constant.Storyboards.splash)
//            setRootViewController(splashVC)
////            BaseRouter.shared.showSplashView()
            
            if !(UIApplication.shared.topMostViewController() is NoInternetConnectionViewController) {
                let noConnectionVC = NoInternetConnectionViewController()
                noConnectionVC.modalPresentationStyle = .fullScreen
                setRootViewController(noConnectionVC)
            }
            
            return
        }
        
        if keychainManager.isTokenExpired() && needAccessTokenUpdate && keychainManager.getRefreshToken() != nil {
            dispatchWorkItem?.cancel()
            needAccessTokenUpdate = false
            let refreshToken = keychainManager.getRefreshToken() ?? ""
            let deviceID = DeviceCheckManager.shared.deviceUnicToken
            request(with: URLBuilder(from: AuthAPI.refreshToken(refreshToken: refreshToken, deviceID: deviceID))) { result in
                switch result {
                case .success(let data):
                    guard let signInResponse = MimoConverter<BaseResponseModel<SignInReponse>>.parseJson(data: data as Any) else { return }
                    if let content = signInResponse.content, signInResponse.statusCode == 200 {
                        self.keychainManager.parse(from: content)
                    }
                case .failure(let error):
                    print(error)
                    completion(.failure(error))
                }
                builderProtocol.rebuild()
                queue.async(execute: self.dispatchWorkItem!)
                self.needAccessTokenUpdate = true
                return
            }
        }
        
        dispatchWorkItem = DispatchWorkItem {
            guard let request = builderProtocol.getRequst() else {
                completion(.failure(.resultsError(error: NetworkError.validatorError("Invalide request"))))
                return
            }
            
            #if DEBUG
            request.log()
            #endif
            
            let session = URLSession(configuration: .default)
            session.dataTask(with: request) { [weak self] data, response, error in
                
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
                    
                    guard (200 ..< 299) ~= response.statusCode else {
                        print("ERROR : \(response)")
                        if response.statusCode == 401 {
                            if let isDeviceEndpoint = request.url?.absoluteString.contains("user/device"), !isDeviceEndpoint {
                                self?.keychainManager.removeData()
                                BaseRouter.shared.showLoginView()
                                return
                            }
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
        queue.async(execute: self.dispatchWorkItem!)
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
