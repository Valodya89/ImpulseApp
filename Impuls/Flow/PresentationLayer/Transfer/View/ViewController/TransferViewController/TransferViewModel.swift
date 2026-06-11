//
//  TransferViewModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/2/21.
//

import Foundation

struct TransferViewModel {
    
    private let sessionNetwork = SessionNetwork()
    
    func fetchContacts(completion: @escaping (Result<Array<ContactsListModel>, Error>) -> ()) {
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.getWihtdrawals)) { (result) in
            switch result {
            case .success(let data):
                do {
                    let responseModel = try JSONDecoder().decode(BaseResponseModel<[ContactsListModel]>.self, from: data)
                    let filterArray = Set(responseModel.content ?? [])
                    print("filterArray = \(filterArray)")
                    return completion(.success(Array(filterArray)))
                } catch {
                    print("Error happened isMimoUser(): \(error)")
                    
                    return completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func inviteUser(phoneNumber: String, completion: @escaping (Result<Void, NetworkError>) -> ()) {
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.inviteUser(phoneNumber: phoneNumber))) { (result) in
            switch result {
            case .success(let data):
                do {
                    let responseModel = try JSONDecoder().decode(BaseResponseModel<EmptyResponse>.self, from: data)
                    
                    if responseModel.statusCode == 200 {
                        completion(.success(()))
                        
                        return
                    }
                    
                    return completion(.failure(NetworkError.responseError("Can not invite user")))
                } catch {
                    print("Error happened inviteUser(): \(error)")
                    
                    return completion(.failure(.responseError(error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(.responseError(error.localizedDescription)))
            }
        }
    }
    
    func isMimoUser(phoneNumber: String, completed: @escaping (MimoUserCheckModel) -> ()) {
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.checkMimoContact(phoneNumber: phoneNumber))) { (result) in
            switch result {
            case .success(let data):
                do {
                    let responseModel = try JSONDecoder().decode(BaseResponseModel<UserResponse>.self, from: data)
                    let checkModel = MimoUserCheckModel(model: responseModel)
                    
                    return completed(checkModel)
                } catch {
                    print("Error happened isMimoUser(): \(error)")
                    
                    return completed(.error)
                }
            case .failure:
                completed(.error)
            }
        }
    }
}
