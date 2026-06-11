//
//  StoryWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.12.23.
//

import Foundation
import Combine

class StoryWorker: StoryWorkerProtocol {
    
    private let storyRepository = StoryRepository()
    
    func getStories() -> AnyPublisher<[Story], MimoError> {
        Deferred {
            Future<[Story], MimoError> { promise in
                self.storyRepository.getStories { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data.sorted(by: { ($0.order ?? 0) < ($1.order ?? 0) })))
                    case .failure(let error):
                        promise(.failure(MimoError.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func like(id: String) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.storyRepository.likeStory(id: id) { result in
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
    
    func setOptions(id: String, pageNumber: Int, options: [String]) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.storyRepository.setOptions(id: id, pageNumber: pageNumber, options: options) { result in
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
