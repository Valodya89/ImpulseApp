//
//  TransactionRepository.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/29/25.
//

import Foundation

struct TransactionRepository {
    private let network = SessionNetwork()
    
    func getTransactionList(completion: @escaping (Result<BaseResponseModel<[TransactionDTO]>, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getTransactions)) { (result) in
            switch result {
            case .success(let data):
                
                guard let stationsResponse = MimoConverter<BaseResponseModel<[TransactionDTO]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Parsing error")))
                    return
                }
                
                if stationsResponse.status == "OK" {
                    completion(.success(stationsResponse))
                } else {
                    completion(.failure(NetworkError.validatorError(stationsResponse.message)))
                }
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
}
