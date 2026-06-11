//
//  BikeUseCase.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 19.07.23.
//

import Foundation
import CoreLocation

class BikeUseCase: BikeUseCaseProtocol {
    
    private let authRepository: AuthRepository = AuthRepository()
    
    func isMimoUser(phoneNumber: String) async -> Result<MimoUserCheckModel, MimoError> {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<Result<MimoUserCheckModel, MimoError>, Never>) in
            authRepository.isMimoUser(phoneNumber: phoneNumber) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: .success(data))
                case .failure(let error):
                    continuation.resume(returning: .failure(error))
                }
            }
        })
    }
}
