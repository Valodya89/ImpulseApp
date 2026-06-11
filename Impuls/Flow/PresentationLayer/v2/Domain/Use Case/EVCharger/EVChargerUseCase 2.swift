//
//  EVChargerUseCase.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/19/25.
//

import Foundation
import CoreLocation

class EVChargerUseCase: EVChargerUseCaseProtocol {
    
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
