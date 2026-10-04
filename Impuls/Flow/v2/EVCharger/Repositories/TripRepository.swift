//
//  TripRepository.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/22/25.
//

import Foundation

// MARK: - Paged envelope

/// `PageResponse<T>` (powerbank docs/mobile-api.md "Response envelope"): the
/// standard `Response<List<T>>` envelope plus `totalCount`, `totalPages`,
/// `pageNumber` and `pageSize`. The counters are optional so a plain envelope
/// still decodes; paging never depends on them alone.
final class PagedResponseModel<T: Decodable>: Decodable {
    var timestamp: String?
    var statusCode: UInt
    var status: String?
    var message: String?
    var content: T?
    var totalCount: Int?
    var totalPages: Int?
    var pageNumber: Int?
    var pageSize: Int?
}

/// One page of a history list, as the view model consumes it.
struct HistoryPage<Item> {
    let items: [Item]
    let page: Int
    let size: Int
    let totalPages: Int?

    /// Paging stops on a short page, or once the server says this was the last.
    var isLast: Bool {
        if items.count < size { return true }
        if let totalPages { return page + 1 >= totalPages }
        return false
    }
}

/// `AuthAPI.getChargerRentList` with the Spring `Pageable` `page`/`size`
/// (powerbank docs/mobile-api.md "GET /api/rent") set per request. Everything
/// else - base, path, headers, method - is the endpoint's own.
private struct PagedChargerRentAPI: APIProtocol {
    let page: Int
    let size: Int

    private var endpoint: AuthAPI { .getChargerRentList }

    var base: String { endpoint.base }
    var path: String { endpoint.path }
    var header: [String: String] { endpoint.header }
    var body: [String: Any]? { endpoint.body }
    var bodyString: String? { endpoint.bodyString }
    var formData: MultipartFormData? { endpoint.formData }
    var method: RequestMethod { endpoint.method }

    var query: [String: String] {
        var query = endpoint.query
        query["page"] = String(page)
        query["size"] = String(size)
        return query
    }
}

struct TripRepository {
    private let network = SessionNetwork()

    // MARK: - Paged history

    /// One page of the rider's power-bank rents, newest first (powerbank
    /// docs/mobile-api.md "GET /api/rent", `PageResponse<Rent>`).
    func getChargerRentPage(page: Int, size: Int, completion: @escaping (Result<HistoryPage<ChargerRentModel>, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: PagedChargerRentAPI(page: page, size: size))) { result in
            switch result {
            case .success(let data):
                guard let response = MimoConverter<PagedResponseModel<[ChargerRentModel]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Parsing error")))
                    return
                }

                // The envelope answers transport 200 even for errors, with the
                // real status in `statusCode` - a refusal must never be taken
                // for an empty page and end paging silently.
                guard response.statusCode == 200 else {
                    completion(.failure(NetworkError.validatorError(response.message ?? "")))
                    return
                }

                completion(.success(HistoryPage(
                    items: response.content ?? [],
                    page: response.pageNumber ?? page,
                    size: size,
                    totalPages: response.totalPages
                )))
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }

    // MARK: - Unpaged lists

    func getScooterTripList(completion: @escaping (Result<BaseResponseModel<[TripScooterDataModel]>, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getScooterTripList)) { (result) in
            switch result {
            case .success(let data):
                
                guard let stationsResponse = MimoConverter<BaseResponseModel<[TripScooterDataModel]>>.parseJson(data: data as Any) else {
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
    
    func getBikeTripList(completion: @escaping (Result<BaseResponseModel<[TripBikeDataModel]>, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getBikeTripList)) { (result) in
            switch result {
            case .success(let data):
                
                guard let stationsResponse = MimoConverter<BaseResponseModel<[TripBikeDataModel]>>.parseJson(data: data as Any) else {
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
    
    func getChargerRentList(completion: @escaping (Result<BaseResponseModel<[ChargerRentModel]>, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getChargerRentList)) { (result) in
            switch result {
            case .success(let data):
                
                guard let stationResponse = MimoConverter<BaseResponseModel<[ChargerRentModel]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Parsing error")))
                    return
                }
                
                if stationResponse.statusCode == 200 {
                    completion(.success(stationResponse))
                } else {
                    completion(.failure(NetworkError.validatorError(stationResponse.message)))
                }
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
    
    func getEVChargerRentList(completion: @escaping (Result<BaseResponseModel<[EVChargerRentModel]>, NetworkError>) -> Void) {
        network.request(with: URLBuilder(from: AuthAPI.getEVChargerRentList)) { (result) in
            switch result {
            case .success(let data):
                
                guard let stationResponse = MimoConverter<BaseResponseModel<[EVChargerRentModel]>>.parseJson(data: data as Any) else {
                    completion(.failure(NetworkError.invalidParse("Parsing error")))
                    return
                }
                
                if stationResponse.statusCode == 200 {
                    completion(.success(stationResponse))
                } else {
                    completion(.failure(NetworkError.validatorError(stationResponse.message)))
                }
            case .failure(let error):
                completion(.failure(NetworkError.responseError(error.localizedDescription)))
            }
        }
    }
}
