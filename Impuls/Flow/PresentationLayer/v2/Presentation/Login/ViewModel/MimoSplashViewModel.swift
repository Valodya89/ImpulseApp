//
//  MimoSplashViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 03.09.23.
//

import Combine
import CoreLocation

class MimoSplashViewModel: MimoBaseViewModel, ObservableObject {
    
    private let worker: MimoSplashWorkerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    @Published var languages: [LanguageResult]?
    @Published var localizations: [String: String]?
    @Published var activeTrips: [AnyObject]?
    
    var currentLocation: CLLocationCoordinate2D?
    var isUserLoggedIn: Bool { worker.isUserLoggedIn }
    var isAccountComplated: Bool { worker.isAccountComplated }
    var locationManager: MimoLocationManagerProtocol = Resolver.resolve()
    
    @Published var translationsGot: Bool = false
    
    init(worker: MimoSplashWorkerProtocol) {
        self.worker = worker
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
                        }
                }
            }
            .store(in: &cancellables)
    }
    
    func loadData() {
        let locale = StorageManager().fetch(key: .language, type: String.self) ?? Locale.current.deviceLanguageCode // String(Locale.preferredLanguages[0].prefix(2))
        
        if !isUserLoggedIn {
            Publishers.Zip(worker.getTranslations(languageCode: locale), worker.getLanguages().replaceError(with: []))
                .receive(on: DispatchQueue.main)
                .sink { [weak self] localizations, languages in
                    guard let self else { return }
                    
                    Mimo.Localization.localizations = localizations
                    self.languages = languages
                    self.localizations = localizations
                    
                    self.translationsGot = true
                    StorageManager().store(languages.first(where: { $0.isSelected })?.id ?? locale, key: .language)
                }
                .store(in: &cancellables)
        } else {
            Publishers.Zip6(worker.getTranslations(languageCode: locale),
                            worker.getLanguages().replaceError(with: []),
                            worker.getActiveScooters().replaceError(with: []),
                            worker.getActiveBikes().replaceError(with: nil),
                            worker.getActiveChargers().replaceError(with: []),
                            worker.getActiveEvChargers().replaceError(with: []))
                .receive(on: DispatchQueue.main)
                .sink { [weak self] localizations, languages, scooterTrips, bikeTrips, chargers, evChargers in
                    guard let self else { return }
                    
                    Mimo.Localization.localizations = localizations
                    self.languages = languages
                    self.localizations = localizations
                    
                    var _activeTrips: [AnyObject] = scooterTrips.compactMap({ $0 as AnyObject })
                    if let bikeTrips {
                        _activeTrips.append(bikeTrips as AnyObject)
                    }
                    _activeTrips.append(contentsOf: chargers.compactMap({ $0 as AnyObject }))
                    _activeTrips.append(contentsOf: evChargers.compactMap({ $0 as AnyObject }))
                    
                    self.activeTrips = _activeTrips
                    self.translationsGot = true
                    StorageManager().store(languages.first(where: { $0.isSelected })?.id ?? locale, key: .language)
                }
                .store(in: &cancellables)
        }
    }
}
