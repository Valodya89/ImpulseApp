//
//  TripRepository.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/22/25.
//

import Foundation

struct TripRepository {
    private let network = SessionNetwork()
    
    func getScooterTripList(completion: @escaping (Result<BaseResponseModel<[TripScooterDataModel]>, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getScooterTripList)) { (result) in
            switch result {
            case .success(let data):
                
                guard let stationsResponse = MimoConverter<BaseResponseModel<[TripScooterDataModel]>>.parseJson(data: data as Any) else {
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
    
    func getBikeTripList(completion: @escaping (Result<BaseResponseModel<[TripBikeDataModel]>, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getBikeTripList)) { (result) in
            switch result {
            case .success(let data):
                
                guard let stationsResponse = MimoConverter<BaseResponseModel<[TripBikeDataModel]>>.parseJson(data: data as Any) else {
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
    
    func getChargerRentList(completion: @escaping (Result<BaseResponseModel<[ChargerRentModel]>, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getChargerRentList)) { (result) in
            switch result {
            case .success(let data):
                
                guard let stationResponse = MimoConverter<BaseResponseModel<[ChargerRentModel]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Parsing error")))
                    return
                }
                
                if stationResponse.statusCode == 200 {
                    completion(.success(stationResponse))
                } else {
                    completion(.failure(NetworkError.validatorError(stationResponse.message)))
                }
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
    
    func getEVChargerRentList(completion: @escaping (Result<BaseResponseModel<[EVChargerRentModel]>, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getEVChargerRentList)) { (result) in
            switch result {
            case .success(let data):
                
                guard let stationResponse = MimoConverter<BaseResponseModel<[EVChargerRentModel]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Parsing error")))
                    return
                }
                
                if stationResponse.statusCode == 200 {
                    completion(.success(stationResponse))
                } else {
                    completion(.failure(NetworkError.validatorError(stationResponse.message)))
                }
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
}
