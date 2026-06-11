//
//  VerifyEmailViewModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/4/21.
//

import Foundation

struct EmptyModel: Decodable {
    
}

class VerifyEmailViewModel {
    
    private var sessionNetwork = SessionNetwork()
    
    func sendEmailCode(completion: @escaping (Result<Void, Error>) -> ()) {
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.sendCodeToEmail)) { (result) in
            switch result {
            case .success(let data):
                do {
                    let baseResponseModel = try JSONDecoder().decode(BaseResponseModel<EmptyModel>.self, from: data)
                    
                    if baseResponseModel.statusCode == 200 {
                        return completion(.success(()))
                    }
                    
                    return completion(.failure(NetworkError.validatorError("Failed")))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    func verifyEmailCode(code: String, completion: @escaping (Result<Void, Error>) -> ()) {
        
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.emailVerification(code: code))) { (result) in
            switch result {
            case .success(let data):
                do {
                    let baseResponseModel = try JSONDecoder().decode(BaseResponseModel<EmptyModel>.self, from: data)
                    
                    if baseResponseModel.statusCode == 200 {
                        return completion(.success(()))
                    }
                    
                    return completion(.failure(NetworkError.validatorError("Failed")))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }

    }
    
}
