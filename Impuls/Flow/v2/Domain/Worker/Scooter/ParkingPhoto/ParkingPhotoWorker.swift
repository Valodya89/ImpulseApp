//
//  ParkingPhotoWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 24.05.24.
//

import Combine

protocol ParkingPhotoWorkerProtocol {
    func finishTrip(id: String, image: UIImage) -> AnyPublisher<Void, MimoError>
    func getTrip(id: String) -> AnyPublisher<TripScooterDataModel, MimoError>
}

final class ParkingPhotoWorker: ParkingPhotoWorkerProtocol {
    
    private let homeRepository = HomeRepository()
    
    func finishTrip(id: String, image: UIImage) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.homeRepository.finishScooterTrip(tripId: id, image: image) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(MimoError(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getTrip(id: String) -> AnyPublisher<TripScooterDataModel, MimoError> {
        Deferred {
            Future<TripScooterDataModel, MimoError> { promise in
                self.homeRepository.getTripBy(tripId: id) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(MimoError.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
