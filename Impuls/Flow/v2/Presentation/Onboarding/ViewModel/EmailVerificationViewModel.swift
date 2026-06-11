//
//  EmailVerificationViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 03.10.23.
//

import Foundation
import Combine

class EmailVerificationViewModel: MimoBaseViewModel, ObservableObject {
    
    private var cancellables = Set<AnyCancellable>()
    
    private let worker: EmailVerificationWorkerProtocol
    
    @Published var emailVerified: Bool = false
    var activeTrips: [AnyObject]
    
    init(worker: EmailVerificationWorkerProtocol, activeTrips: [AnyObject]) {
        self.worker = worker
        self.activeTrips = activeTrips
        super.init()
        
        worker.verifyEmailPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                switch result {
                case .success:
                    self?.emailVerified = true
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
            .store(in: &cancellables)
    }
    
    func resendCode() {
        worker.resendVerificationEmail()
    }
    
    func verifyEmail(code: String) {
        worker.verifyEmail(code: code)
    }
}
