//
//  ZoneInfoUseCase.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 19.07.23.
//

import Foundation

class ZoneInfoUseCase: ZoneInfoUseCaseProtocol {
    
    private let homeRepository = HomeRepository()
    
    func getZoneInfo() async throws -> Result<[ZoneInfo], MimoError> {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Result<[ZoneInfo], MimoError>, Error>) in
            
            homeRepository.getZoneInfo { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: .success(data))
                case .failure(let error):
                    continuation.resume(returning: .failure(MimoError(error: error)))
                }
            }
        })
    }
}
