//
//  ProductSelectionViewModel.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/25/25.
//

import Foundation
import Combine
import CoreLocation

final class ProductSelectionViewModel: MimoBaseViewModel, ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    private let worker: MimoHomeWorkerProtocol
    private let locationManager: MimoLocationManagerProtocol
    private let messagingService: MessageServiceProtocol

    @Published private(set) var currentLocation: CLLocationCoordinate2D?
    @Published private(set) var isLocationAuthorized: Bool = false
    @Published private(set) var countryCode: String?
    @Published private(set) var availableProducts: [ProductCardViewModel] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var shouldDismiss: Bool = false
    
    init(
        worker: MimoHomeWorkerProtocol,
        locationManager: MimoLocationManagerProtocol,
        messagingService: MessageServiceProtocol
    ) {
        self.worker = worker
        self.locationManager = locationManager
        self.messagingService = messagingService
        
        super.init()
        
        locationManager.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                if self?.currentLocation == nil {
                    self?.currentLocation = location
                    
                    CLGeocoder().reverseGeocodeLocation(
                        CLLocation(
                            latitude: location.latitude,
                            longitude: location.longitude
                        )) { [weak self] placemarks, error in
                            guard error == nil else { return }
                            
                            guard let isoCountryCode = placemarks?.first?.isoCountryCode else { return }
                            ApplicationSettings.shared.isoCountryCode = CountryUtilities.getAlphaThreeCode(byAlpha2Code: isoCountryCode)
                            self?.countryCode = isoCountryCode
                            self?.getAvailableServices()
                        }
                }
            }
            .store(in: &cancellables)
        
        locationManager.authorizationStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthorized in
                self?.isLocationAuthorized = isAuthorized
            }
            .store(in: &cancellables)
    }
    
    func getAvailableServices() {
        guard let isoCountryCode = ApplicationSettings.shared.isoCountryCode else { return }
        
        self.isLoading = true
        
        worker.getAvailableServices(countryCode: isoCountryCode)
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] availableServices in
                let allowedServices = UserManager.share.userResponse?.services ?? []
                
                self?.availableProducts = availableServices.compactMap {
                    ProductCardViewModel(type: $0, isSelected: allowedServices.contains($0.service))
                }
                
                ApplicationSettings.shared.availableServices = availableServices.compactMap { $0.mimoType }
                
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }
    
    
    func toggleSelection(for product: ProductCardViewModel) {
        if let index = availableProducts.firstIndex(where: { $0.service == product.service }) {
            availableProducts[index].isSelected.toggle()
        }
    }
    
    func isValid() -> Bool {
        return availableProducts.contains(where: { $0.isSelected })
    }
    
    func save() {
        let selectedServices: [String] = availableProducts
            .filter({$0.isSelected})
            .compactMap { $0.service }
        
        guard !selectedServices.isEmpty else { return }
        
        self.isLoading = true
        
        worker.updateAllowedServices(selectedServices)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                case .finished:
                    UserManager.share.userResponse?.services = selectedServices
                    self?.isLoading = false
                    break
                }
            } receiveValue: { [weak self] in
                self?.messagingService.publish(.allowedServicesUpdated)
                self?.shouldDismiss = true
            }
            .store(in: &cancellables)
    }
}
