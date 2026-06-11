//
//  ScooterTripWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 04.06.23.
//

import Foundation
import Combine

class ScooterTripWorker: ScooterTripWorkerProtocol {
    
    private let homeRepository = HomeRepository()
    
    func getScooterDetails(by id: String) -> AnyPublisher<SingleScooterResponse, MimoError> {
        Deferred {
            Future<SingleScooterResponse, MimoError> { [weak self] promise in
                self?.homeRepository.getScooterById(scooterId: id) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func pauseScooter(with id: String) -> AnyPublisher<ScooterStateModel, MimoError> {
        Deferred {
            Future<ScooterStateModel, MimoError> { [weak self] promise in
                self?.homeRepository.pauseTrip(id: id, completion: { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                })
            }
        }
        .eraseToAnyPublisher()
    }
    
    func continueScooter(with id: String) -> AnyPublisher<ScooterStateModel, MimoError> {
        Deferred {
            Future<ScooterStateModel, MimoError> { [weak self] promise in
                self?.homeRepository.continueTrip(id: id, completion: { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                })
            }
        }
        .eraseToAnyPublisher()
    }
    
    func changeSpeedTarif(tripId: String, speedId: String) -> AnyPublisher<Bool, MimoError> {
        Deferred {
            Future<Bool, MimoError> { [weak self] promise in
                self?.homeRepository.changeSpeedd(tarifId: tripId, speedId: speedId) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func checkFinish(id: String) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { [weak self] promise in
                self?.homeRepository.finishChcek(id: id) { result in
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
}
