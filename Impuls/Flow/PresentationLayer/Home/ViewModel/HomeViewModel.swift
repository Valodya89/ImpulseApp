//
//  HomeViewModel.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 5/9/21.
//

import CoreLocation

final class HomeViewModel {
    
    private let homeRepository = HomeRepository()
    private let keychainManager = KeychainManager()
    private let storageManager = StorageManager()
    private let socketManager: SocketService = SocketService.shared
    
    deinit {
        print("deinit - \(String(describing: self))")
    }
    
    func getInsurancePrice() {
        homeRepository.getInsurancePrice { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let data):
                print(data.price)
                self.storageManager.store(data.price, key: .insurancePrice)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func getTripBy(tripId id: String, completion: @escaping (Result<TripScooterDataModel, NetworkError>) -> Void)  {
        homeRepository.getTripBy(tripId: id) { result in
            switch result {
            case .success(let data):
                print(data)
                completion(.success(data))
            case .failure(let error):
                print(error)
                completion(.failure(error))
            }
        }
    }
    
    func pauseTrip(id: String, completion: @escaping (Result<Bool, NetworkError>) -> Void) {
        homeRepository.pauseTrip(id: id) { result in
            switch result {
            case .success(let data):
                break
//                print(data)
//                completion(.success(data))
            case .failure(let error):
                print(error)
                completion(.failure(error))
            }
        }
    }
    
    func continueTrip(id: String, completion: @escaping (Result<Bool, NetworkError>) -> Void) {
        homeRepository.continueTrip(id: id) { result in
            switch result {
            case .success(let data):
                print(data)
//                completion(.success(data))
            case .failure(let error):
                print(error)
                completion(.failure(error))
            }
        }
    }
    
    func changeSpeed(tarifId: String, speedId: String, completion: @escaping (Result<Bool, NetworkError>) -> Void) {
        homeRepository.changeSpeedd(tarifId: tarifId, speedId: speedId) { result in
            switch result {
            case .success(let data):
                print(data)
                completion(.success(data))
            case .failure(let error):
                print(error)
                completion(.failure(error))
            }
        }  
    }
    
    func getAppVersion(completion: @escaping (Result<AppVersion, NetworkError>) -> Void) {
        homeRepository.getAppVersion { result in
            switch result {
            case .success(let data):
                print(data)
                completion(.success(data))
            case .failure(let error):
                print(error)
                completion(.failure(error as! NetworkError))
            }
        }
    }
    
    func changeBlockState(state: Bool, bikeId: String, completion: @escaping (Result<Void, MimoError>) -> ()) {
        homeRepository.changeLockState(state: state, bikeId: bikeId, completion: completion)
    }
    
    func listenToScanBike(completion: @escaping (Result<TripActionModel, MimoError>) -> ()) {
        guard let phoneNumber = self.storageManager.fetch(key: .phoneNumber, type: String.self) else {
            return completion(.failure(.init(error: .invalidParse("can not identify user"))))
        }
        
        socketManager.listenToScanSuccess(phoneNumber: phoneNumber) { result in
            switch result {
            case .success(let model):
                if model.action == .TripStarted {
                    return completion(.success(model))
                } else if model.action == .TripScanned {
                    return completion(.success(model))
                }
                completion(.failure(.init(error: .responseError(model.action.rawValue))))
            case .failure(let error):
                completion(.failure(.init(error: .responseError(error.localizedDescription))))
            }
        }
    }
    
    func listenScanBikeChange(completion: @escaping (Result<TripActionModel, MimoError>) -> ()) {
        guard let phoneNumber = self.storageManager.fetch(key: .phoneNumber, type: String.self) else {
            return completion(.failure(.init(error: .invalidParse("can not identify user"))))
        }
        
        socketManager.listenToScanSuccess(phoneNumber: phoneNumber) { result in
            switch result {
            case .success(let model):
                completion(.success(model))
            case .failure(let error):
                completion(.failure(.init(error: .responseError(error.localizedDescription))))
            }
        }
    }
    
    func scanBike(bookId: String, location: CLLocationCoordinate2D, completion: @escaping (Result<TripActionModel, NetworkError>) -> ()) {
//        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
//            let positionModel = TripDataModel.TripPositionModel(longitude: location.longitude, latitude: location.latitude, timestamp: 2234123425233)
//
//            let tripDtoModel = TripDataModel(id: "sdf", scan: nil, start: nil, end: nil, user: nil, bike: nil, startPosition: positionModel, endPosition: nil)
//
//            completion(.success(.init(action: .TripStarted, bikeDto: BikeResponse(id: "355951092927933", qr: bookId, mac: "nil", voltage: nil, longitude: location.longitude, latitude: location.latitude, updated: false), data: tripDtoModel)))
//        }
//
//        return
        
        self.homeRepository.scan(bikeID: bookId, location: location) { (result) in
            
            switch result {
            case .success(let model):
                completion(.success(model))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func bookBike(bookId: String, location: CLLocationCoordinate2D, completion: @escaping (Result<Void, MimoError>) -> ()) {
        self.homeRepository.bookNowRequest(bookId: bookId, location: location) { [weak self] (result) in
            
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getMapZones(completion: @escaping (Result<[Zone], Error>) -> Void) {
        self.homeRepository.getMapZone { result in
            switch result {
            case .success(let zones):
                completion(.success(zones))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    func getNews(complation: @escaping ((Result<[NewsObject], NetworkError>) -> Void)) {
        self.homeRepository.getNews(token: keychainManager.getAccessToken() ?? "", completion: { result in
            switch result {
            case .success(let newsList):
                
                    print("==== newsList = \(newsList)")
                complation(.success(newsList))
            case .failure(let error):
                complation(.failure(error))
            }
        })
        
    }
    
    func bookScooter(bookId: String, location: CLLocationCoordinate2D, completion: @escaping (Result<BookedScooterResult, MimoError>) -> ()) {
        self.homeRepository.bookNowScooterRequest(bookId: bookId, location: location) { [weak self] (result) in
            
            switch result {
            case .success(let bookedScooter):
                completion(.success(bookedScooter))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func scan(bikeID: String, location: CLLocationCoordinate2D, completion: @escaping (Result<TripActionModel, NetworkError>) -> ()) {
        
   
        homeRepository.scan(bikeID: bikeID, location: location) { (result) in

            switch result {
            case .success(let model):
                completion(.success(model))
                break
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getBikes(completion: @escaping (Result<([BikeResult], MarkerAction), Error>) -> Void) {
        
        homeRepository.getBikes { (result) in
            switch result {
            case .success(let bikeResponses):
                self.homeRepository.getUpdateOfBikes { (result) in
                    switch result {
                    case .success(let elements):
                        completion(.success((elements, .update)))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                
                print(bikeResponses)
                let bikeResults = HomeMapper.toBikeResults(from: bikeResponses)
                completion(.success((bikeResults, .add)))
                break
            case .failure(let error):
                completion(.failure(error))
                break
            }
        }
    }
    
    func getScooters(completion: @escaping (Result<([ScooterResult], MarkerAction), Error>) -> Void) {
        
        homeRepository.getScooters { (result) in
            switch result {
            case .success(let scooterResponses):
                self.homeRepository.getUpdateOfScooters { (result) in
                    switch result {
                    case .success(let elements):
                        completion(.success((elements, .update)))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                
                print(scooterResponses)
                let scooterResults = HomeMapper.toScooterResults(from: scooterResponses)
                print("scooterResults = \(scooterResults)")
                completion(.success((scooterResults, .add)))
                break
            case .failure(let error):
                completion(.failure(error))
                break
            }
        }
    }
    
    func getParkings(completion: @escaping (Result<[ParkingResponse], NetworkError>) -> Void) {
        
        homeRepository.getParkings { (result) in
            switch result {
            case .success(let parkingResponses):
                
//                print(parkingResponses)
                
//                print("parkingResponses = \(parkingResponses)")
                completion(.success((parkingResponses)))
                break
            case .failure(let error):
                completion(.failure(error))
                break
            }
        }
    }
    
    func getScooterDetails(id: String, completion: @escaping (Result<(SingleScooterResponse), NetworkError>) -> Void) {
        homeRepository.getScooterById(scooterId: id) { result in
            switch result {
            case .success(let singleScooterResponses):
//                self.homeRepository.getUpdateOfScooters { (result) in
//                    switch result {
//                    case .success(let elements):
//                        completion(.success((elements, .update)))
//                    case .failure(let error):
//                        completion(.failure(error))
//                    }
//                }
                
//                print(singleScooterResponses)
//                let scooterResults = HomeMapper.toScooterResults(from: singleScooterResponses)
                print("scooterResults = \(singleScooterResponses)")
                completion(.success((singleScooterResponses)))
                break
            case .failure(let error):
                completion(.failure(error))
                break
            }
        }
    }
    
    func deactivateInsurance() {
        homeRepository.deactivateInsurance()
    }
    
    func scanScooter(id: String, insurance: Bool, speedModeTariff: String, billingModeTariff: String, longitude: Double, latitude: Double,  completion: @escaping (Result<ScooterStateModel, NetworkError>) -> Void) {
        //40.220420, 44.486523
        var token = DeviceCheckManager.shared.deviceUnicToken
        homeRepository.scanScoterscanScooter(id: id, insurance: insurance, speedModeTariff: speedModeTariff, billingModeTariff: billingModeTariff, longitude: longitude, latitude: latitude ,  deviceId: token) { resuult in
            switch resuult {
            case .success(let data):
                completion(.success(data))
            case .failure(let er):
                completion(.failure(er))
            }
        }
    }
    
    func getAvatar(completion: @escaping (String) -> Void) {
        if let token = keychainManager.getAccessToken(),
           let avatarUrlString = storageManager.fetch(key: .avatar, type: String.self) {
            completion(avatarUrlString + token)
        }
    }
    
    func cancelBikeBook(bikeID: String, completion: @escaping (Result<(),Error>)->Void) {
        SessionNetwork().request(with: URLBuilder(from: AuthAPI.cancelBikeBook(bookID: bikeID))) { result in
            switch result {
            case .success(let data):
                
                guard let bikeResponse = MimoConverter<BaseResponseModel<EmptyModel>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                if bikeResponse.statusCode == 200 {
                    completion(.success(()))
                } else {
                    completion(.failure(NetworkError.invalidParse(bikeResponse.message)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func cancelScooterBook(bikeID: String, completion: @escaping (Result<(),Error>)->Void) {
        SessionNetwork().request(with: URLBuilder(from: AuthAPI.cancelScooterBook(bookID: bikeID))) { result in
            switch result {
            case .success(let data):
                
                guard let bikeResponse = MimoConverter<BaseResponseModel<EmptyModel>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                if bikeResponse.statusCode == 200 {
                    completion(.success(()))
                } else {
                    completion(.failure(NetworkError.invalidParse(bikeResponse.message)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func beepBookedBike() {
        SessionNetwork().request(with: URLBuilder(from: AuthAPI.beepBookedBike)) { response in
            
        }
    }
    
    func beepBookedScooter() {
        SessionNetwork().request(with: URLBuilder(from: AuthAPI.beepBookedScooter)) { _ in }
    }
}
