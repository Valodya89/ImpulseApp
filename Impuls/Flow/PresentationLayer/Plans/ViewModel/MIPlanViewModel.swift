//
//  MIPlanViewModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/7/21.
//

import Foundation

struct MIPlanViewModel {
    
    let sessionNetwork = SessionNetwork()
    let storageManager = StorageManager()
    
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
    
    func fetchTariff(completion: @escaping (Result<[TariffModel], Error>) -> ()) {
        let language = storageManager.fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))
        
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.getTarrifs(locale: language))) { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                do {
                    let content = try JSONDecoder().decode(BaseResponseModel<[TariffModel]>.self, from: data)
                    
                    completion(.success(content.content ?? []))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func fetchPackage(completion: @escaping (Result<[PackageModel], Error>) -> ()) {
        let language = storageManager.fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.getPackages(locale: language))) { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                do {
                    let content = try JSONDecoder().decode(BaseResponseModel<[PackageModel]>.self, from: data)
                    
                    completion(.success(content.content
                     ?? []))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func activateTarrif(_ id: String, phone: String, email: String, unversityName: String, addmissionDate: String, graduationDate: String, studentCardPhoto: UIImage, selfiePhoto: UIImage , completion: @escaping (Result<EmptyModel, NetworkSessionErrors>) -> ()) {
        
        sessionNetwork.request(with: URLBuilder(from: TarrifAPI.activateTarrif(id: id, studentCard: studentCardPhoto, selfie: selfiePhoto, phone: phone, email: email, university: unversityName, addmisionDate: addmissionDate, graduationDate: graduationDate))) { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                do {
                    let content = try JSONDecoder().decode(BaseResponseModel<EmptyModel>.self, from: data)
                    
                    if content.statusCode == 200 {
                        completion(.success(.init()))
                    }
                } catch let error {
                    completion(.failure(.unknown(message: error.localizedDescription)))
                }
            }
        }
    }
    
}
