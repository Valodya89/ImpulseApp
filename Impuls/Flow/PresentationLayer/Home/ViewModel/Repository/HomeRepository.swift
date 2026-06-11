//
//  HomeRepository.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 5/9/21.
//

import CoreLocation

struct HomeRepository {
    
    private let network = SessionNetwork()
    
    func changeLockState(state: Bool, bikeId: String, completion: @escaping (Result<Void, MimoError>) -> ()) {
        network.request(with: URLBuilder(from: AuthAPI.updateBikeLock(state: state, bikeID: bikeId))) { (result) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(.init(error: .responseError(error.description))))
            }
        }
    }
    
    func scan(bikeID: String, location: CLLocationCoordinate2D, completion: @escaping (Result<TripActionModel, NetworkError>) -> ()) {
        
        network.request(with: URLBuilder(from: AuthAPI.trips(bookId: bikeID, latitude: CGFloat(location.latitude), longitude: CGFloat(location.longitude)))) { (result) in
            switch result {
            case .success(let data):
                
                guard let bikeResponse = MimoConverter<BaseResponseModel<TripActionModel>>.parseJson(data: data as Any) else {
                    completion(.failure(.invalidParse("Can not parse model")))
                    
                    return
                }
                
                    print("languageResponse === \(bikeResponse)")
                if bikeResponse.statusCode == 200, let content = bikeResponse.content {
                    completion(.success(content))
                    
                    return
                }
                //}
                
                completion(.failure(.responseError(bikeResponse.message)))
            case .failure(let error):
                print("scan qr error = \(error)")
                if error.description == "SHARING_no_minimal_requirements" || error.description == "MOBILE_map_minimum_requirments" {
                    completion(.failure(.tooFar(error.localizedDescription)))
                } else {
                    completion(.failure(.invalidParse(error.localizedDescription)))

                }
            }
        }
    }
    
    func bookNowRequest(bookId: String, location: CLLocationCoordinate2D, completion: @escaping (Result<Void, MimoError>) -> ()) {
        let api = AuthAPI.bookBike(bookId: bookId, latitude: CGFloat(location.latitude), longitude: CGFloat(location.longitude))
        network.request(with: URLBuilder(from: api)) { (result) in
            switch result {
            case .success(let data):
                
                guard let bikeResponse = MimoConverter<BaseResponseModel<EmptyModel>>.parseJson(data: data as Any) else {
                    completion(.failure(.init(error: .invalidParse("Can not parse model"))))
                    
                    return
                }
                
                    print("languageResponse === \(bikeResponse)")
                if bikeResponse.statusCode == 200 {
                    completion(.success(()))
                    
                    return
                }
                
                completion(.failure(.init(error: .responseError(bikeResponse.message))))
            case .failure(let error):
                completion(.failure(.init(error: .invalidParse(error.localizedDescription))))
            }
        }
    }
    
    func cancelBikeBooking(id: String, completion: @escaping (Result<Void, MimoError>) -> ()) {
        let api = AuthAPI.cancelBikeBook(bookID: id)
        network.request(with: URLBuilder(from: api)) { result in
            switch result {
            case .success(let data):
                guard let bikeResponse = MimoConverter<BaseResponseModel<EmptyModel>>.parseJson(data: data as Any) else {
                    completion(.failure(.init(error: .invalidParse("Can not parse model"))))
                    return
                }
                
                if bikeResponse.statusCode == 200 {
                    completion(.success(()))
                    return
                }
                
                completion(.failure(.init(error: .responseError(bikeResponse.message))))
            case .failure(let error):
                completion(.failure(.init(error: NetworkError.invalidParse(error.localizedDescription))))
            }
        }
    }
    
    func bookNowScooterRequest(bookId: String, location: CLLocationCoordinate2D, completion: @escaping (Result<BookedScooterResult, MimoError>) -> ()) {
        let api = AuthAPI.bookScooter(bookId: bookId, latitude: CGFloat(location.latitude), longitude: CGFloat(location.longitude))
        network.request(with: URLBuilder(from: api)) { (result) in
            switch result {
            case .success(let data):
                
                guard let bikeResponse = MimoConverter<BaseResponseModel<EmptyModel>>.parseJson(data: data as Any) else {
                    completion(.failure(.init(error: .invalidParse("Can not parse model"))))
                    
                    return
                }
                
                    print("languageResponse === \(bikeResponse)")
                if bikeResponse.statusCode == 200 {
                    guard let bookedScooterResult = MimoConverter<BaseResponseModel<BookedScooterResult>>.parseJson(data: data as Any) else {
                        completion(.failure(.init(error: .invalidParse("Can not parse model"))))
                        return
                    }
                    
                    completion(.success(bookedScooterResult.content!))
                    
                    return
                } else if bikeResponse.statusCode == 406 {
                    completion(.failure(.init(error: NetworkError.invalidParse(bikeResponse.message))))
                }
                
                completion(.failure(.init(error: .responseError(bikeResponse.message))))
            case .failure(let error):
                completion(.failure(.init(error: .invalidParse(error.localizedDescription))))
            }
        }
    }
    
    func cancelScooterBooking(id: String, completion: @escaping (Result<BookedScooterResult, MimoError>) -> ()) {
        network.request(with: URLBuilder(from: AuthAPI.cancelScooterBook(bookID: id))) { result in
            switch result {
            case .success(let data):
                guard let bikeResponse = MimoConverter<BaseResponseModel<EmptyModel>>.parseJson(data: data as Any) else {
                    completion(.failure(.init(error: .invalidParse("Can not parse model"))))
                    
                    return
                }
                
                if bikeResponse.statusCode == 200 {
                    guard let bookedScooterResult = MimoConverter<BaseResponseModel<BookedScooterResult>>.parseJson(data: data as Any) else {
                        completion(.failure(.init(error: .invalidParse("Can not parse model"))))
                        return
                    }
                    
                    completion(.success(bookedScooterResult.content!))
                    
                    return
                } else if bikeResponse.statusCode == 406 {
                    completion(.failure(.init(error: NetworkError.invalidParse(bikeResponse.message))))
                }
                
                completion(.failure(.init(error: .responseError(bikeResponse.message))))
            case .failure(let error):
                completion(.failure(.init(error: .invalidParse(error.localizedDescription))))
            }
        }
    }
    
    func getBikes(completion: @escaping (Result<[BikeResponse], Error>) -> Void) {
        network.request(with: URLBuilder(from: HomeAPI.getBikes)) { (result) in
            switch result {
            case .success(let data):
                
                guard let bikeResponse = MimoConverter<BaseResponseModel<[BikeResponse]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                
                //if bikeResponse.status == "OK" {
                    print("languageResponse === \(bikeResponse)")
                completion(.success(bikeResponse.content!))
                //}
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getAppVersion(completion: @escaping (Result<AppVersion, Error>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getVersion)) { (result) in
            switch result {
            case .success(let data):
                
                guard let appVersion = try? JSONDecoder().decode(AppVersion.self, from: data) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                
                //if bikeResponse.status == "OK" {
                    print("appVersion === \(appVersion)")
                completion(.success(appVersion))
                //}
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getZoneInfo( completion: @escaping (Result<[ZoneInfo], NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: HomeAPI.getZoneInfo)) { (result) in
            switch result {
            case .success(let data):
                
                guard let tripResponse = MimoConverter<BaseResponseModel<[ZoneInfo]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }

                print("tripResponse === \(tripResponse)")
                if  let data = tripResponse.content {
                    completion(.success(data))
                } else {
                    completion(.failure(NetworkError.serverError))
                }
            case .failure(let error):
                completion(.failure(NetworkError.validatorError(error.localizedDescription)))
            }
        }
    }
    
    func getTripBy(tripId id: String, completion: @escaping (Result<TripScooterDataModel, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: HomeAPI.getTripBy(id: id))) { (result) in
            switch result {
            case .success(let data):
                
                guard let tripResponse = MimoConverter<BaseResponseModel<TripScooterDataModel>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }

                print("tripResponse === \(tripResponse)")
                if  let data = tripResponse.content {
                    completion(.success(data))
                } else {
                    completion(.failure(NetworkError.responseError(tripResponse.message)))
                }
            case .failure(let error):
                completion(.failure(NetworkError.validatorError(error.localizedDescription)))
            }
        }
    }
    
    func pauseTrip(id: String, completion: @escaping (Result<ScooterStateModel, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: HomeAPI.pause(id: id))) { (result) in
            switch result {
            case .success(let data):
                guard let bikeResponse = MimoConverter<BaseResponseModel<ScooterStateModel>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Pause Data Decode Error")))
                    return
                }
                
                if let content = bikeResponse.content, bikeResponse.status == "OK" {
                    completion(.success(content))
                } else {
                    completion(.failure(NetworkError.responseError(bikeResponse.message)))
                }
                
            case .failure(let error):
                completion(.failure(NetworkError.validatorError(error.localizedDescription)))
            }
        }
    }
    
    func continueTrip(id: String, completion: @escaping (Result<ScooterStateModel, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: HomeAPI.continuePause(id: id))) { (result) in
            switch result {
            case .success(let data):
                guard let bikeResponse = MimoConverter<BaseResponseModel<ScooterStateModel>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Continue Data Decode Error")))
                    return
                }
                
                if let content = bikeResponse.content, bikeResponse.status == "OK" {
                    completion(.success(content))
                } else {
                    completion(.failure(NetworkError.responseError(bikeResponse.message)))
                }
            case .failure(let error):
                completion(.failure(NetworkError.validatorError(error.localizedDescription)))
            }
        }
    }
    
    func changeSpeedd(tarifId: String, speedId: String, completion: @escaping (Result<Bool, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: HomeAPI.changeSpedTariff(tripId: tarifId, speedId: speedId))) { (result) in
            switch result {
            case .success:
                
//                guard let bikeResponse = MimoConverter<BaseResponseModel<ContinueTrip>>.parseJson(data: data as Any) else {
//                    completion(.failure(NetworkError.serverError))
//                    return
//                }
                
                //if bikeResponse.status == "OK" {
//                    print("languageResponse === \(bikeResponse)")
                completion(.success(true))
                //}
            case .failure(let error):
                completion(.failure(NetworkError.validatorError(error.localizedDescription)))
            }
        }
    }
    
    func getMapZone(completion: @escaping (Result<[Zone], NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: HomeAPI.getZones)) { (result) in
            switch result {
            case .success(let data):
                
                guard let zoneResponse = MimoConverter<BaseResponseModel<[Zone]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                
                completion(.success(zoneResponse.content!))
            case .failure(let error):
                completion(.failure(NetworkError.validatorError(error.localizedDescription)))
            }
        }
    }
    
    func getBikeMapZone(completion: @escaping (Result<[Zone], NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: HomeAPI.getBikeZones)) { (result) in
            switch result {
            case .success(let data):
                guard let zoneResponse = MimoConverter<BaseResponseModel<[Zone]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                
                completion(.success(zoneResponse.content!))
            case .failure(let error):
                completion(.failure(NetworkError.validatorError(error.localizedDescription)))
            }
        }
    }
    
    func getNews(token: String, completion: @escaping (Result<[NewsObject], NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: HomeAPI.getNews(token: token))) { (result) in
            switch result {
            case .success(let data):
                
                guard let newsList = MimoConverter<BaseResponseModel<[NewsObject]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                
                //if bikeResponse.status == "OK" {
                    print("newsList === \(newsList)")
                completion(.success(newsList.content!))
                //}
            case .failure(let error):
                completion(.failure(NetworkError.invalidParse(error.description)))
            }
        }
    }
    
    func getScooters(completion: @escaping (Result<[ScooterResponse], Error>) -> Void) {
        network.request(with: URLBuilder(from: HomeAPI.getScooters)) { (result) in
            switch result {
            case .success(let data):
                
                guard let scooterResponse = MimoConverter<BaseResponseModel<[ScooterResponse]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                
                //if scooterResponse.status == "OK" {
                    print("languageResponse === \(scooterResponse)")
                completion(.success(scooterResponse.content!))
                //}
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getParkings(completion: @escaping (Result<[ParkingResponse], NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: HomeAPI.getParkings)) { (result) in
            switch result {
            case .success(let data):
                //MimoConverter<BaseResponseModel<[ParkingResponse]>>.parseJson(data: data as Any) else
                guard let parkingsResponse = MimoConverter<[ParkingResponse]>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                
                //if scooterResponse.status == "OK" {
//                    print("parkingsResponse === \(parkingsResponse)")
                completion(.success(parkingsResponse))
                //}
            case .failure(let error):
                completion(.failure(.responseError(error.description)))
            }
        }
    }
    
    func deactivateInsurance() {
        
        network.request(with: URLBuilder(from: AuthAPI.deactivateInsurance)) { result in
            switch result {
            case .success(let data):
                print(data)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func scanScoterscanScooter(id: String, insurance: Bool, speedModeTariff: String, billingModeTariff: String, longitude: Double, latitude: Double, deviceId: String, completion: @escaping (Result<ScooterStateModel, NetworkError>) -> Void) {
        
        network.request(with: URLBuilder(from: HomeAPI.scanScooter(id: id, insurance: insurance, speedModeTariff: speedModeTariff, billingModeTariff: billingModeTariff, longitude: longitude, latitude: latitude,  deviceId: deviceId))) { result in
            switch result {
            case .success(let data):
                
                guard let singleScooterResponse = MimoConverter<BaseResponseModel<ScooterStateModel>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                
                if singleScooterResponse.content !=  nil {
                    completion(.success(singleScooterResponse.content!))
                } else {
                    if singleScooterResponse.message == "SCOOTER_min_balance_error" || singleScooterResponse.message ==  "SCOOTER_no_minimal_requirements" {
                        completion(.failure(NetworkError.tooFar(singleScooterResponse.message.localized())))
                    } else {
                        completion(.failure(NetworkError.responseError(singleScooterResponse.message.localized())))
                    }
                }
                //}
            case .failure(let error):
                completion(.failure(NetworkError.invalidParse(error.localizedDescription)))
            }
        }
    }
    
    func getScooterById( scooterId: String, completion: @escaping (Result<SingleScooterResponse, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: HomeAPI.getScooterById(id: scooterId))) { (result) in
            switch result {
            case .success(let data):
                
                guard let singleScooterResponse = MimoConverter<BaseResponseModel<SingleScooterResponse>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.serverError))
                    return
                }
                
                //if scooterResponse.status == "OK" {
                    print("SingleScooterResponse === \(singleScooterResponse)")
                if singleScooterResponse.statusCode == 200 {
                    completion(.success(singleScooterResponse.content!))
                } else {
                    completion(.failure(.validatorError(singleScooterResponse.message)))
                }
                //}
            case .failure(let error):
                completion(.failure(NetworkError.invalidParse(error.localizedDescription)))
            }
        }
    }
    
    func beepBookedScooter(completion: @escaping (Result<Void, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.beepBookedScooter)) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(NetworkError.invalidParse(error.localizedDescription)))
            }
        }
    }
    
    func getUpdateOfBikes(completion: @escaping (Result<[BikeResult], Error>) -> Void) {
//        if let state = (UserDefaults.standard.value(forKey: "BikeState") as? String), state == "bike" {
//            socket.listenToBikeShare { (result) in
//                completion(.success(result))
//            }
//        }
    }
    
    func getUpdateOfScooters(completion: @escaping (Result<[ScooterResult], Error>) -> Void) {
//        socket.listenToBikeShare { (result) in
//            completion(.success(result))
//        }
    }
    
    //MARK: - Charger
    
    func getChargingStations(completion: @escaping (Result<BaseResponseModel<[ChargingStation]>, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: HomeAPI.getChargingStations)) { (result) in
            switch result {
            case .success(let data):
                
                guard let stationsResponse = MimoConverter<BaseResponseModel<[ChargingStation]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Parsing error")))
                    return
                }
                
                if stationsResponse.status == "OK" {
                    completion(.success(stationsResponse))
                } else {
                    completion(.failure(NetworkError.validatorError(stationsResponse.message)))
                }
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
    
    func scanCharger(stationId: String, location: CLLocationCoordinate2D, completion: @escaping (Result<RentedCharger, NetworkError>) -> ()) {
        network.request(with: URLBuilder(from: HomeAPI.scanCharger(id: stationId, latitude: location.latitude, longitude: location.longitude))) { (result) in
            switch result {
            case .success(let data):
                guard let chargerResponse = MimoConverter<BaseResponseModel<RentedCharger>>.parseJson(data: data as Any) else {
                    completion(.failure(.invalidParse("Can not parse model")))
                    
                    return
                }
                
                if chargerResponse.statusCode == 200, let content = chargerResponse.content {
                    completion(.success(content))
                    return
                }
                
                completion(.failure(.responseError(chargerResponse.message)))
            case .failure(let error):
                print("scan qr error = \(error)")
                
                if error.description == "SHARING_no_minimal_requirements" || error.description == "MOBILE_map_minimum_requirments" {
                    completion(.failure(.tooFar(error.localizedDescription)))
                } else {
                    completion(.failure(.invalidParse(error.localizedDescription)))
                }
            }
        }
    }
    
    func getChargerState(completion: @escaping (Result<[RentedCharger], NetworkError>) -> ()) {
        network.request(with: URLBuilder(from: HomeAPI.chargerState)) { result in
            switch result {
            case .success(let data):
                guard let chargerResponse = MimoConverter<BaseResponseModel<[RentedCharger]>>.parseJson(data: data as Any) else {
                    completion(.failure(.invalidParse("Can not parse model")))
                    
                    return
                }
                
                if chargerResponse.statusCode == 200, let content = chargerResponse.content {
                    completion(.success(content))
                    return
                }
                
                completion(.failure(.responseError(chargerResponse.message)))
            case .failure(let error):
                completion(.failure(.validatorError(error.localizedDescription)))
            }
        }
    }
    
    func getBikeTariffs(completion: @escaping (Result<[TariffModel], NetworkError>) -> ()) {
        let language = StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))
        
        network.request(with: URLBuilder(from: AuthAPI.getTarrifs(locale: language))) { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(.responseError(error.localizedDescription)))
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(BaseResponseModel<[TariffModel]>.self, from: data)
                    
                    if response.statusCode == 200, let content = response.content {
                        completion(.success(content))
                    } else {
                        completion(.failure(.responseError(response.message)))
                    }
                } catch {
                    completion(.failure(.responseError(error.localizedDescription)))
                }
            }
        }
    }
    
    func getBikePackages(completion: @escaping (Result<[PackageModel], NetworkError>) -> ()) {
        let language = StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))
        network.request(with: URLBuilder(from: AuthAPI.getPackages(locale: language))) { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(.responseError(error.localizedDescription)))
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(BaseResponseModel<[PackageModel]>.self, from: data)
                    
                    if response.statusCode == 200, let content = response.content {
                        completion(.success(content))
                    } else {
                        completion(.failure(.responseError(response.message)))
                    }
                } catch {
                    completion(.failure(.responseError(error.localizedDescription)))
                }
            }
        }
    }
    
    func unlockBikeTrip(id: String, completion: @escaping (Result<Void, NetworkError>) -> ()) {
        network.request(with: URLBuilder(from: AuthAPI.unlockBikeTrip(id: id))) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(BaseResponseModel<EmptyModel>.self, from: data)
                    
                    if response.statusCode == 200 {
                        completion(.success(()))
                    } else {
                        completion(.failure(.responseError(response.message)))
                    }
                } catch {
                    completion(.failure(.responseError(error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(.responseError(error.localizedDescription)))
            }
        }
    }
    
    func finishChcek(id: String, completion: @escaping (Result<Void, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: HomeAPI.finishCheck(id: id))) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(BaseResponseModel<EmptyModel>.self, from: data)
                    
                    if response.statusCode == 200 {
                        completion(.success(()))
                    } else {
                        completion(.failure(.responseError(response.message)))
                    }
                } catch {
                    completion(.failure(.responseError(error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(.responseError(error.localizedDescription)))
            }
        }
    }
    
    // MARK: - RATES
    
    func getChargerPackages(completion: @escaping (Result<[ChargerPackage], NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: HomeAPI.chargerPackages)) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(BaseResponseModel<[ChargerPackage]>.self, from: data)
                    
                    if let content = response.content, response.statusCode == 200 {
                        completion(.success(content))
                    } else {
                        completion(.failure(.responseError(response.message)))
                    }
                } catch {
                    completion(.failure(.responseError(error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(.responseError(error.localizedDescription)))
            }
        }
    }
    
    func activateChargerPackage(id: String, completion: @escaping (Result<ActivatedPackage, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: HomeAPI.chargerPackageActivate(id: id))) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(BaseResponseModel<ActivatedPackage>.self, from: data)
                    
                    if let content = response.content, response.statusCode == 200 {
                        completion(.success(content))
                    } else {
                        completion(.failure(.responseError(response.message)))
                    }
                } catch {
                    completion(.failure(.responseError(error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(.responseError(error.localizedDescription)))
            }
        }
    }
    
    func getChargerTariffs(completion: @escaping (Result<[ChargerTariff], NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: HomeAPI.chargerTariffs)) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode([ChargerTariff].self, from: data)
                    
                    completion(.success(response))
                } catch {
                    completion(.failure(.responseError(error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(.responseError(error.localizedDescription)))
            }
        }
    }
    
    func bikePackageActivate(id: String, completion: @escaping (Result<ActivatedPackage, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.activatePackage(packageID: id))) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(BaseResponseModel<ActivatedPackage>.self, from: data)
                    
                    if let content = response.content, response.statusCode == 200 {
                        completion(.success(content))
                    } else {
                        completion(.failure(.responseError(response.message)))
                    }
                } catch {
                    completion(.failure(.responseError(error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(.responseError(error.localizedDescription)))
            }
        }
    }
    
    func getChargerAccount(completion: @escaping (Result<ActivatedPackage?, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: HomeAPI.chargerAccount)) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(BaseResponseModel<ActivatedPackage?>.self, from: data)
                    
                    if response.statusCode == 200 {
                        completion(.success(response.content ?? nil))
                    } else {
                        completion(.failure(.responseError(response.message)))
                    }
                } catch {
                    completion(.failure(.responseError(error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(.responseError(error.localizedDescription)))
            }
        }
    }
    
    func finishScooterTrip(tripId: String, image: UIImage, completion: @escaping (Result<Void, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: ImageUploadAPI.finish(tripId: tripId, image: image))) { result in
            switch result {
            case .success(let data):
                guard let response = MimoConverter<BaseResponseModel<ScooterScanResponse>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Decode error")))
                    return
                }
                
                if response.statusCode != 200 {
                    completion(.failure(NetworkError.responseError(response.message)))
                } else {
                    completion(.success(()))
                }
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
    
    //MARK: - EV Charger
    
    func getChargingStations(completion: @escaping (Result<BaseResponseModel<[EVChargingStationDTO]>, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: EVChargerAPI.getChargingStations)) { (result) in
            switch result {
            case .success(let data):
                
                guard let stationsResponse = MimoConverter<BaseResponseModel<[EVChargingStationDTO]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Parsing error")))
                    return
                }
                
                if stationsResponse.status == "OK" {
                    completion(.success(stationsResponse))
                } else {
                    completion(.failure(NetworkError.validatorError(stationsResponse.message)))
                }
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
                }
        }
    }
        
    func getLeasedScooters(completion: @escaping (Result<ScooterAccountDto?, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: HomeAPI.scooterAccount)) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(BaseResponseModel<ScooterAccountDto?>.self, from: data)
                    
                    if response.statusCode == 200 {
                        completion(.success(response.content ?? nil))
                    } else {
                        completion(.failure(.responseError(response.message)))
                    }
                } catch {
                    completion(.failure(.responseError(error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(.responseError(error.localizedDescription)))
            }
        }
    }
        
    func getChargingState(completion: @escaping (Result<[EVStateMessagedDTO], NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: EVChargerAPI.getChargingState)) { (result) in
            switch result {
            case .success(let data):
                
                guard let stationResponse = MimoConverter<BaseResponseModel<[EVStateMessagedDTO]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Parsing error")))
                    return
                }
                
                if stationResponse.statusCode == 200, let content = stationResponse.content {
                    completion(.success(content))
                } else {
                    completion(.failure(NetworkError.validatorError(stationResponse.message)))
                }
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
                }
        }
    }

    func lockLeasedScooter(id: String, completion: @escaping (Result<Void, MimoError>) -> ()) {
        network.request(with: URLBuilder(from: HomeAPI.lockLeasedScooter(id: id))) { result in
            switch result {
            case .success(let data):
                guard let response = MimoConverter<BaseResponseModel<EmptyModel>>.parseJson(data: data as Any) else {
                    completion(.failure(.init(error: .invalidParse("Can not parse model"))))
                    return
                }
                
                if response.statusCode == 200 {
                    completion(.success(()))
                    return
                }
                
                completion(.failure(.init(error: .responseError(response.message))))
            case .failure(let error):
                completion(.failure(.init(error: NetworkError.invalidParse(error.localizedDescription))))
            }
        }
    }
    
    func unlockLeasedScooter(id: String, completion: @escaping (Result<Void, MimoError>) -> ()) {
        network.request(with: URLBuilder(from: HomeAPI.unlockLeasedScooter(id: id))) { result in
            switch result {
            case .success(let data):
                guard let response = MimoConverter<BaseResponseModel<EmptyModel>>.parseJson(data: data as Any) else {
                    completion(.failure(.init(error: .invalidParse("Can not parse model"))))
                    return
                }
                
                if response.statusCode == 200 {
                    completion(.success(()))
                    return
                }
                
                completion(.failure(.init(error: .responseError(response.message))))
            case .failure(let error):
                completion(.failure(.init(error: NetworkError.invalidParse(error.localizedDescription))))
            }
        }
    }
    
    func openBatteryCover(id: String, completion: @escaping (Result<Void, MimoError>) -> ()) {
        network.request(with: URLBuilder(from: HomeAPI.openBatteryCover(id: id))) { result in
            switch result {
            case .success(let data):
                guard let response = MimoConverter<BaseResponseModel<EmptyModel>>.parseJson(data: data as Any) else {
                    completion(.failure(.init(error: .invalidParse("Can not parse model"))))
                    return
                }
                
                if response.statusCode == 200 {
                    completion(.success(()))
                    return
                }
                
                completion(.failure(.init(error: .responseError(response.message))))
            case .failure(let error):
                completion(.failure(.init(error: NetworkError.invalidParse(error.localizedDescription))))
            }
        }
    }
    
    func getInsurancePrice(completion: @escaping (Result<InsurancePriceResponceModel, WalletRequestErrors>) -> Void) {
        
        network.request(with: URLBuilder(from: AuthAPI.getInsurancePrice)) { (result) in
            switch result {
            case .success(let data):
                guard let insurancePriceResponceModel = MimoConverter<BaseResponseModel<InsurancePriceResponceModel>>.parseJson(data: data as Any) else {
                    completion(.failure(WalletRequestErrors.parseError))
                    return
                }
                if let content = insurancePriceResponceModel.content, insurancePriceResponceModel.statusCode == 200 {
                    print("insurancePriceResponceModel === \(insurancePriceResponceModel)")
                    completion(.success(content))
                } else {
                    completion(.failure(.custom(message: insurancePriceResponceModel.message)))
                }
            case .failure(let error):
                completion(.failure(.internalError))
            }
        }
    }
}
