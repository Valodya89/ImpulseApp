//
//  Startup.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 12.05.23.
//

extension Resolver: ResolverRegistering {
    
    public static func registerAllServices() {
        
        //MARK: - User
        register { UserService() }.implements(UserServicable.self)
        
        //MARK: - Managers
        register { MimoLocationManager() }.implements(MimoLocationManagerProtocol.self)
        
        //MARK: - Services
        register { MessageService() }.implements(MessageServiceProtocol.self).scope(.application)
        register { MimoScooterSocketService() }.implements(MimoScooterSocketServiceProtocol.self)
        register { MimoBikeSocketService() }.implements(MimoBikeSocketServiceProtocol.self)
        register { MimoChargerSocketService() }.implements(MimoChargerSocketServiceProtocol.self)
        register { EVChargerSocketService() }.implements(EVChargerSocketServiceProtocol.self).scope(.application)
        
        //MARK: - Helpers
        register { AddressHelper() }.implements(AddressHelperProtocol.self)
        
        //MARK: - Login
        register { MimoSplashWorker() }.implements(MimoSplashWorkerProtocol.self)
        register { MimoSplashViewModel(worker: resolve()) }
        register { EmailVerificationWorker() }.implements(EmailVerificationWorkerProtocol.self)
        
        //MARK: - Home
        register { MimoHomeWorker() }.implements(MimoHomeWorkerProtocol.self)
        
        //MARK: - Scooter
        register { ScooterUseCase() }.implements(ScooterUseCaseProtocol.self)
        register { ScooterWorker(useCase: resolve(), scooterSocketService: resolve()) }.implements(ScooterWorkerProtocol.self)
        
        register { ScooterDetailsUseCase(addressHelper: resolve()) }.implements(ScooterDetailsUseCaseProtocol.self)
        register { ScooterDetailsWorker(useCase: resolve()) }.implements(ScooterDetailsWorkerProtocol.self)
        register { (_, args) in MimoScooterViewModel(preScannedQR: args("preScannedQR"), 
                                                     preSelectedQR: args("preSelectedQR"),
                                                     leasedScooters: args("leasedScooters"),
                                                     worker: resolve(),
                                                     locationManager: resolve(),
                                                     messagingService: resolve()) }
        register { (_, args) in EVChargerMapViewModel(preSelectedId: args.optional("preSelectedId"),
                                                      worker: resolve(),
                                                      locationManager: resolve(),
                                                      messagingService: resolve() ) }
        
        register { ScooterTripWorker() }.implements(ScooterTripWorkerProtocol.self)
        register { (_, args) in ScooterTripViewModel(worker: resolve(), messageService: resolve(), trips: args()) }
        
        register {  (_, args) in ScooterDetailsViewModel(worker: resolve(),
                                                         scooterData: args.optional("scooterData"),
                                                         scooterState: args.optional("scooterState"),
                                                         hasLeasedScooters: args.optional("hasLeasedScooters"),
                                                         walletInfo: args.optional("walletInfo"),
                                                         financialState: args.optional("financialState"), 
                                                         user: args.optional("user")) }
        
        register { ParkingPhotoWorker() }.implements(ParkingPhotoWorkerProtocol.self)
        
        //MARK: - ZoneInfo
        register { ZoneInfoUseCase() }.implements(ZoneInfoUseCaseProtocol.self)
        register { ZoneInfoWorker(useCase: resolve()) }.implements(ZoneInfoWorkerProtocol.self)
        register { (_, args) in ZoneInfoViewModel(worker: resolve(), zoneType: args()) }
        
        //MARK: - Bike
        register { BikeUseCase() }.implements(BikeUseCaseProtocol.self)
        register { BikeWorker(useCase: resolve(), bikeSocketService: resolve()) }.implements(BikeWorkerProtocol.self)
        register { (_, args) in BikeViewModel(preScannedQR: args("preScannedQR"), 
                                              preSelectedQR: args("preSelectedQR"),
                                              worker: resolve(),
                                              locationManager: resolve(),
                                              messageService: resolve()) }
        
        register { BikeDetailsUseCase(addressHelper: resolve()) }.implements(BikeDetailsUseCaseProtocol.self)
        register { BikeDetailsWorker(useCase: resolve()) }.implements(BikeDetailsWorkerProtocol.self)
        register { (_, args) in BikeDetailsViewModel(worker: resolve(), locationManager: resolve(), data: args()) }
        
        register { BikeTripUseCase(addressHelper: resolve()) }.implements(BikeTripUseCaseProtocol.self)
        register { BikeTripWorker(useCase: resolve()) }.implements(BikeTripWorkerProtocol.self)
        register { (_, args) in BikeTripViewModel(worker: resolve(), data: args()) }
        
        //MARK: - Charger
        register { ChargerWorker(chargerSocketService: resolve()) }.implements(ChargerWorkerProtocol.self)
        register { (_, args) in  ChargerViewModel(preScannedQR: args("preScannedQR"), 
                                                  preSelectedQR: args("preSelectedQR"),
                                                  worker: resolve(),
                                                  locationManager: resolve(),
                                                  messagingService: resolve()) }
        
        //MARK: - EVCharger
        register { EVChargerUseCase() }.implements(EVChargerUseCaseProtocol.self)
        register { EVChargerWorker(useCase: resolve(), evChargerSocketService: resolve()) }.implements(EVChargerWorkerProtocol.self).scope(.application)
        
        //MARK: - Partnership
        register { PartnershipWorker() }.implements(PartnershipWorkerProtocol.self)
        
        //MARK: - Notify
        register { NotifyNewsWorker() }.implements(NotifyNewsWorkerProtocol.self)
        
        //MARK: - Rates
        register { RatesWorker() }.implements(RatesWorkerProtocol.self)
        
        //MARK: - Stories
        register { StoryWorker() }.implements(StoryWorkerProtocol.self)
        
        //MARK: - Profile
        register { ProfileWorker() }.implements(ProfileWorkerProtocol.self)
        
        //MARK: - Wallet
        register { WalletWorker() }.implements(WalletWorkerProtocol.self)
        
        //MARK: - Subscriptions
        register { SubscriptionService() }.implements(SubscriptionServicable.self)
        register { SubscriptionWorker(subscriptionService: resolve(), userService: resolve()) }.implements(SubscriptionWorkerProtocol.self)
    }
}
