//
//  AccountRepository.swift
//  MimoBike
//
//  Created by Albert on 20.05.21.
//

import Foundation

final class AccountRepository {
    
    private let network = SessionNetwork()
    
    func getUser(completion: @escaping (Result<UserResponse, Error>) -> Void) {
        
        let builder = URLBuilder(from: AuthAPI.getUser)
        network.request(with: builder) { (result) in
            switch result {
            case .success(let data):
                guard let userResponse = try? JSONDecoder().decode(BaseResponseModel<UserResponse>.self, from: data) else {
                    completion(.failure(NetworkError.invalidParse("Culdn not parse json model from data \(data)")))
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
    
    func getUserAccount(completion: @escaping (Result<UserResponse, NetworkError>) -> Void) {
        
        let builder = URLBuilder(from: AuthAPI.getAccount)
        network.request(with: builder) { (result) in
            switch result {
            case .success(let data):
                guard let userResponse = try? JSONDecoder().decode(BaseResponseModel<UserResponse>.self, from: data) else {
                    completion(.failure(NetworkError.invalidParse("Culdn not parse json model from data \(data)")))
                    return
                }
                if let content = userResponse.content, userResponse.statusCode == 200 {
                    print("UserResponse === \(userResponse)")
                    completion(.success(content))
                } else {
                    completion(.failure(NetworkError.responseError(userResponse.message)))
                }
            case .failure(let error):
                completion(.failure(.serverError))
            }
        }
    }
    
    func updateUser(name: String, surname: String, gender: String, email: String, birthday: String,
                    bio: String, settings: UserResponse.SettingsModel, completion: @escaping (Result<UserResponse, Error>) -> Void) {
        UserManager.share.updateUser(name: name, surname: surname, gender: gender, email: email, birthday: birthday, bio: bio, settings: settings) { response in
            switch response {
            case .success(let user):
                completion(.success(user))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func updatePersonalInfo(name: String, surname: String, gender: String, birthday: String, completion: @escaping (Result<UserResponse, Error>) -> Void) {
        let builder = URLBuilder(from: AuthAPI.updatePersonalInfo(name: name, surname: surname, birthday: birthday, gender: gender))
        network.request(with: builder) { result in
            switch result {
            case .success(let data):
                guard let userResponse = try? JSONDecoder().decode(BaseResponseModel<UserResponse>.self, from: data) else {
                    completion(.failure(NetworkError.invalidParse("Culdn not parse json model from data \(data)")))
                    return
                }
                if let content = userResponse.content, userResponse.statusCode == 200 {
                    completion(.success(content))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func submitPartnershipApplication(fullName: String, email: String, phoneNumber: String?, location: String, completion: @escaping (Result<Void, MimoError>) -> Void) {
        let builder = URLBuilder(from: AuthAPI.partnershipApplication(fullName: fullName, email: email, phoneNumber: phoneNumber, location: location))
        network.request(with: builder) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(MimoError(error: NetworkError.responseError(error.localizedDescription))))
            }
        }
    }
    
    func subscribeEVChargerNews(email: String, completion: @escaping (Result<Void, MimoError>) -> Void) {
        let builder = URLBuilder(from: AuthAPI.subscribeEVChargerNews(email: email))
        network.request(with: builder) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(MimoError(error: NetworkError.responseError(error.localizedDescription))))
            }
        }
    }
    
    func updateDeviceInfo(token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let builder = URLBuilder(from: AuthAPI.uploadFCM(token: token))
        network.request(with: builder) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getAvailableServices(countryCode: String, completion: @escaping (Result<[String], NetworkError>) -> Void) {
        network.request(with: URLBuilder.init(from: HomeAPI.availableServices(code: countryCode))) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(BaseResponseModel<[AvailableService]>.self, from: data)
                    
                    if let content = response.content, response.statusCode == 200 {
                        completion(.success(content.compactMap({ $0.service })))
                    } else {
                        completion(.failure(.responseError(response.message)))
                    }
                } catch {
                    completion(.failure(.responseError(error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(.responseError(error.localizedDescription)))
            }
        }
    }
    
    func updateAllowedServices(services: [String], completion: @escaping (Result<Void, NetworkError>) -> Void) {
        let builder = URLBuilder(from: AuthAPI.updateServices(services: services))
        network.request(with: builder) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(.responseError(error.localizedDescription)))
            }
        }
    }
}
