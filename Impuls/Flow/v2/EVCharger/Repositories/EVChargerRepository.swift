//
//  EVChargerRepository.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/25/25.
//

import Foundation

struct EVChargerRepository {
    private let network = SessionNetwork()
    
    func getChargingStations(completion: @escaping (Result<BaseResponseModel<[EVChargingStationDTO]>, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: EVChargerAPI.getChargingStations)) { (result) in
            switch result {
            case .success(let data):
                
                guard let stationsResponse = MimoConverter<BaseResponseModel<[EVChargingStationDTO]>>.parseJson(data: data as Any) else {
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
    
    func getLocationList(latitude: Double, longitude: Double, radius: Double, chargingTypes: [String], connectorTypes: [String], facilities: [String], minPowerKwts: Double, maxPowerKwts: Double, stations: [String], completion: @escaping (Result<BaseResponseModel<[EVLocationDTO]>, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: EVChargerAPI.getLocationList(latitude: latitude, longitude: longitude, radius: radius, chargingTypes: chargingTypes, connectorTypes: connectorTypes, facilities: facilities, minPowerKwts: minPowerKwts, maxPowerKwts: maxPowerKwts, stations: stations))) { (result) in
            switch result {
            case .success(let data):

                guard let stationsResponse = MimoConverter<BaseResponseModel<[EVLocationDTO]>>.parseJson(data: data as Any) else {
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

    func filterChargingStations(criterias: [[String: Any]], completion: @escaping (Result<BaseResponseModel<[EVChargingStationDTO]>, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: EVChargerAPI.filterChargingStations(criterias: criterias))) { (result) in
            switch result {
            case .success(let data):
                
                guard let stationsResponse = MimoConverter<BaseResponseModel<[EVChargingStationDTO]>>.parseJson(data: data as Any) else {
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
    
    func getChargingStation(id: String, completion: @escaping (Result<EVChargingStationDTO, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: EVChargerAPI.getChargingStation(id: id))) { (result) in
            switch result {
            case .success(let data):
                
                guard let stationResponse = MimoConverter<BaseResponseModel<EVChargingStationDTO>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Parsing error")))
                    return
                }
                
                if stationResponse.statusCode == 200, let content = stationResponse.content {
                    completion(.success(content))
                } else {
                    completion(.failure(NetworkError.validatorError(stationResponse.message)))
                }
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
    
    func getChargingStationDetailed(id: String, completion: @escaping (Result<EVLocationDTO, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: EVChargerAPI.getChargingStationDetailed(id: id))) { (result) in
            switch result {
            case .success(let data):

                guard let stationResponse = MimoConverter<BaseResponseModel<EVLocationDTO>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Parsing error")))
                    return
                }

                if stationResponse.statusCode == 200, let content = stationResponse.content {
                    completion(.success(content))
                } else {
                    completion(.failure(NetworkError.validatorError(stationResponse.message)))
                }
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }

    func getChargingStationDetailedByStationId(stationId: String, completion: @escaping (Result<EVLocationDTO, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: EVChargerAPI.getChargingStationDetailedByStationId(stationId: stationId))) { (result) in
            switch result {
            case .success(let data):

                guard let stationResponse = MimoConverter<BaseResponseModel<EVLocationDTO>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Parsing error")))
                    return
                }

                if stationResponse.statusCode == 200, let content = stationResponse.content {
                    completion(.success(content))
                } else {
                    completion(.failure(NetworkError.validatorError(stationResponse.message)))
                }
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
    
    func startCharging(id: String, connectorId: Int, kwts: Double, completion: @escaping (Result<EVStateMessagedDTO, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: EVChargerAPI.startCharging(stationId: id, connectorId: connectorId, kwts: kwts))) { (result) in
            switch result {
            case .success(let data):
                
                guard let stationResponse = MimoConverter<BaseResponseModel<EVStateMessagedDTO>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Parsing error")))
                    return
                }
                
                if stationResponse.statusCode == 200, let content = stationResponse.content {
                    completion(.success(content))
                } else {
                    completion(.failure(NetworkError.validatorError(stationResponse.message)))
                }
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
    
    func getChargingState(completion: @escaping (Result<[EVStateMessagedDTO], NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: EVChargerAPI.getChargingState)) { (result) in
            switch result {
            case .success(let data):
                
                guard let stationResponse = MimoConverter<BaseResponseModel<[EVStateMessagedDTO]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Parsing error")))
                    return
                }
                
                if stationResponse.statusCode == 200, let content = stationResponse.content {
                    completion(.success(content))
                } else {
                    completion(.failure(NetworkError.validatorError(stationResponse.message)))
                }
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
    
    func finishCharging(id: String, completion: @escaping (Result<Void, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: EVChargerAPI.finishCharging(stationId: id))) { (result) in
            switch result {
            case .success(let data):
                
                guard let stationResponse = MimoConverter<BaseResponseModel<EmptyResponse>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Parsing error")))
                    return
                }
                
                if stationResponse.statusCode == 200 {
                    completion(.success(()))
                } else {
                    completion(.failure(NetworkError.validatorError(stationResponse.message)))
                }
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
    
    func getCharging(id: String, completion: @escaping (Result<ChargingListDto, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: EVChargerAPI.getCharging(chargingId: id))) { (result) in
            switch result {
            case .success(let data):
                
                guard let stationResponse = MimoConverter<BaseResponseModel<ChargingListDto>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Parsing error")))
                    return
                }
                
                if stationResponse.statusCode == 200, let content = stationResponse.content {
                    completion(.success((content)))
                } else {
                    completion(.failure(NetworkError.validatorError(stationResponse.message)))
                }
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
    
    func getGuide(completion: @escaping (Result<GuideDTO, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: EVChargerAPI.getGuide)) { (result) in
            switch result {
            case .success(let data):
                
                guard let guideResponse = MimoConverter<BaseResponseModel<GuideDTO>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Parsing error")))
                    return
                }
                
                if guideResponse.statusCode == 200, let content = guideResponse.content {
                    completion(.success(content))
                } else {
                    completion(.failure(NetworkError.validatorError(guideResponse.message)))
                }
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
}
