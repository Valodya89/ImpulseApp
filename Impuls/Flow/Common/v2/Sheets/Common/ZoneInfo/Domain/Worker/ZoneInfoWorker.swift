//
//  ZoneInfoWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 19.07.23.
//

import Foundation
import Combine

class ZoneInfoWorker: ZoneInfoWorkerProtocol {
    
    private let useCase: ZoneInfoUseCaseProtocol
    
    var zoneInfoPublisher: AnyPublisher<Result<[ZoneInfo], MimoError>, Never> {
        zoneInfoSubject.eraseToAnyPublisher()
    }
    
    private let zoneInfoSubject = PassthroughSubject<Result<[ZoneInfo], MimoError>, Never>()
    
    init(useCase: ZoneInfoUseCaseProtocol) {
        self.useCase = useCase
    }
    
    func getZoneInfo() async {
        guard let result = try? await useCase.getZoneInfo() else { return }
        
        switch result {
        case .success(let data):
            zoneInfoSubject.send(.success(data))
        case .failure(let error):
            zoneInfoSubject.send(.failure(error))
        }
    }
}
