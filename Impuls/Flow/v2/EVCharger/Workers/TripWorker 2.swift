//
//  TripWorker.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/22/25.
//

import Combine

protocol TripWorkerProtocol {
    func getScooterTripList() -> AnyPublisher<[TripScooterDataModel], MimoError>
    func getBikeTripList() -> AnyPublisher<[TripBikeDataModel], MimoError>
    func getChargerRentList() -> AnyPublisher<[ChargerRentModel], MimoError>
    func getEVChargerRentList() -> AnyPublisher<[EVChargerRentModel], MimoError>
}

final class TripWorker: TripWorkerProtocol {
    private let tripRepository: TripRepository
    
    init(tripRepository: TripRepository = TripRepository()) {
        self.tripRepository = tripRepository
    }
    
    func getScooterTripList() -> AnyPublisher<[TripScooterDataModel], MimoError> {
        Deferred {
            Future<[TripScooterDataModel], MimoError> { promise in
                self.tripRepository.getScooterTripList { result in
                    switch result {
                    case .success(let data):
                        let scooterTrips = data.content ?? []
                        promise(.success(scooterTrips))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getBikeTripList() -> AnyPublisher<[TripBikeDataModel], MimoError> {
        Deferred {
            Future<[TripBikeDataModel], MimoError> { promise in
                self.tripRepository.getBikeTripList { result in
                    switch result {
                    case .success(let data):
                        let bikeTrips = data.content ?? []
                        promise(.success(bikeTrips))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getChargerRentList() -> AnyPublisher<[ChargerRentModel], MimoError> {
        Deferred {
            Future<[ChargerRentModel], MimoError> { promise in
                self.tripRepository.getChargerRentList { result in
                    switch result {
                    case .success(let data):
                        let chargerRents = data.content ?? []
                        promise(.success(chargerRents))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getEVChargerRentList() -> AnyPublisher<[EVChargerRentModel], MimoError> {
        Deferred {
            Future<[EVChargerRentModel], MimoError> { promise in
                self.tripRepository.getEVChargerRentList { result in
                    switch result {
                    case .success(let data):
                        let chargerRents = data.content ?? []
                        promise(.success(chargerRents))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
