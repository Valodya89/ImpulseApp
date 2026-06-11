//
//  UserService.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.06.24.
//

import Combine

protocol UserServicable {
    func getUser(_ endpoint: UserEndpoint) -> AnyPublisher<UserDto, APIError>
}

final class UserService: NetworkService, UserServicable {
    
    func getUser(_ endpoint: UserEndpoint) -> AnyPublisher<UserDto, APIError> {
        request(endpoint).eraseToAnyPublisher()
    }
}
