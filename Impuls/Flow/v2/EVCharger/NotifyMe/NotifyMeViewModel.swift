//
//  NotifyMeViewModel.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/23/25.
//

import Foundation
import Combine

final class NotifyMeViewModel: MimoBaseViewModel, ObservableObject {
    private let worker: NotifyNewsWorkerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    @Published var email: String = ""
    @Published var isLoading: Bool = false
    @Published var isSubscribedNews: Bool = false
    
    init(worker: NotifyNewsWorkerProtocol) {
        self.worker = worker
        super.init()
        
        email = UserManager.share.userResponse?.email ?? ""
    }
    
    func submitEmail() {
        self.isLoading = true
        
        worker.subscribeEVChargerNews(email: email)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                case .finished:
                    self?.isLoading = false
                    break
                }
            } receiveValue: { [weak self] in
                self?.isSubscribedNews = true
            }
            .store(in: &cancellables)
    }
    
    func isValid() -> Bool {
        email.isEmail
    }
}
