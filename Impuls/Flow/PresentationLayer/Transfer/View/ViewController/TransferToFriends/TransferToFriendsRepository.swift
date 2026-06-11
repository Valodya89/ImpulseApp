//
//  TransferToFriendsRepository.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/2/21.
//

import Foundation

struct TransferToFriendsRepository {
    
    let sessionNetwork = SessionNetwork()
    
    func transferMoney(amount: Double, phoneNumber: String, completion: @escaping (Result<Void, TransferMoneyErrors>) -> ()) {
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.tranfer(id: phoneNumber, amount: amount))) { (result) in
            switch result {
            case .success(let data):
                let checkModel = TransferMoneyCheckModel(data: data)
                
                switch checkModel {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error ?? .other))
                }
            case .failure:
                completion(.failure(.other))
            }
        }
    }
    
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
}
