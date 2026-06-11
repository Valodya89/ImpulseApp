//
//  ZoneInfoViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 19.07.23.
//

import Foundation
import Combine

class ZoneInfoViewModel: MimoBaseViewModel {
    
    private var cancellables = Set<AnyCancellable>()
    private let worker: ZoneInfoWorkerProtocol
    
    let zoneType: ZoneType?
    
    @Published var zoneInfo: [ZoneInfo]?
    
    init(worker: ZoneInfoWorkerProtocol, zoneType: ZoneType?) {
        self.worker = worker
        self.zoneType = zoneType
        super.init()
        
        worker.zoneInfoPublisher
            .receive(on: DispatchQueue.main)
            .sink { result in
                switch result {
                case .success(let zoneInfo):
                    var _zoneInfo = zoneInfo
                    if let zoneType {
                        _zoneInfo = zoneInfo.filter({ $0.id == zoneType.rawValue })
                    } else {
                        _zoneInfo.insert(ZoneInfo(id: "Parking", title: "MOBILE_parking_zone".localized(), description: ""), at: 0)
                    }
                    self.zoneInfo = _zoneInfo
                case .failure:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    func getZoneInfo() {
        Task {
            await worker.getZoneInfo()
        }
    }
}
