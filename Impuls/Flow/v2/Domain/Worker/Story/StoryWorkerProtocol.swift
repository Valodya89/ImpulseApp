//
//  StoryWorkerProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.12.23.
//

import Foundation
import Combine

protocol StoryWorkerProtocol {
    
    func getStories() -> AnyPublisher<[Story], MimoError>
    func like(id: String) -> AnyPublisher<Void, MimoError>
    func setOptions(id: String, pageNumber: Int, options: [String]) -> AnyPublisher<Void, MimoError>
}
