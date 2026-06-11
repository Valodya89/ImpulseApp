//
//  LoginWorkerProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 17.09.23.
//

import Foundation
import Combine

protocol LoginWorkerProtocol {
    
    var userDataPublisher: AnyPublisher<UserResponse?, Never> { get }
    
    func signIn(phoneNumber: String) -> AnyPublisher<(Bool, Bool, Bool, OTPMethod?), MimoError>
    func verifyDevice(phoneNumber: String, code: String) -> AnyPublisher<SignInReponse, MimoError>
    func updatePersonalInfo(name: String, surename: String, birthday: String, gender: String, email: String) -> AnyPublisher<UserResponse, MimoError>
    func sendEmailCode() -> AnyPublisher<Bool, MimoError>
    func getAvailableServices(countryCode: String) -> AnyPublisher<[MimoProductType], MimoError>
    func updateAllowedServices(_ services: [String]) -> AnyPublisher<Void, MimoError>
}
