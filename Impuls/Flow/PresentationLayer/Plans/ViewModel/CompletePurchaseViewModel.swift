//
//  CompletePurchaseViewModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/8/21.
//

import Foundation

struct CompletePurchaseViewModel {
    
    let sessionNetwork = SessionNetwork()
    
    func getUser(completion: @escaping (Result<UserResponse, Error>) -> Void) {
                
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.getUser)) { (result) in
            switch result {
            case .success(let data):
                guard let userResponse = MimoConverter<BaseResponseModel<UserResponse>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                if let content = userResponse.content, userResponse.statusCode == 200 {
                    print("UserResponse === \(userResponse)")
                    completion(.success(content))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func activatePackage(packageID: String, completion: @escaping (Result<Void, Error>) -> ()) {
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.activatePackage(packageID: packageID))) { (result) in
            switch result {
            case .success(let data):
                do {
                    let content = try JSONDecoder().decode(BaseResponseModel<EmptyResponseModel>.self, from: data)
                    
                    if content.statusCode == 200 {
                        completion(.success(()))
                        return
                    }
                    completion(.success(()))
                    //completion(.failure(NetworkError.responseError("Failed to activate package")))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get all country codes
    func getWallet(completion: @escaping (Result<WalletModel, Error>) -> Void) {
        
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.getWallet)) { (result) in
            switch result {
            case .success(let data):
                guard let countryCodeResponce = MimoConverter<BaseResponseModel<WalletModel>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                if let content = countryCodeResponce.content, countryCodeResponce.statusCode == 200 {
                    print("countryCodeResponce === \(countryCodeResponce)")
                    completion(.success(content))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
