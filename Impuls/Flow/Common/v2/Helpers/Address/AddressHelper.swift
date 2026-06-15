//
//  AddressHelper.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.05.23.
//

import Foundation
import CoreLocation
class AddressCaching {
    private(set) static var cache: NSCache<AnyObject, AnyObject> = .init()
    
    static func key(for coordinate: CLLocationCoordinate2D) -> String {
        return coordinate.latitude.description + coordinate.longitude.description
    }
}

class AddressHelper: AddressHelperProtocol {
    
    private let geocoder = MimoGeocoder()
    
    func getAddress(for coordinate: CLLocationCoordinate2D, fullAddress: Bool) async throws -> String {
        return try await withCheckedThrowingContinuation({ continuation in
            let cachingKey = AddressCaching.key(for: coordinate) as AnyObject
            if let address = AddressCaching.cache.object(forKey: cachingKey) as? String {
                continuation.resume(returning: address)
            } else {
                geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
                    guard let result = response?.firstResult() else { return }
                    
                    let thoroughfare = result.thoroughfare
                    let subLocality = result.subLocality
                    let locality = result.locality
                    
                    var address = ""
                    if let thoroughfare {
                        address.append(thoroughfare)
                    }
                    
                    if fullAddress {
                        if let subLocality {
                            if !address.isEmpty {
                                address.append(", ")
                            }
                            address.append(subLocality)
                        }
                        
                        if let locality, fullAddress {
                            if !address.isEmpty {
                                address.append(", ")
                            }
                            address.append(locality)
                        }
                    }
                    
                    if address.isEmpty {
                        address = "-"
                    }
                    
                    continuation.resume(returning: address)
                    AddressCaching.cache.setObject(address as AnyObject, forKey: cachingKey)
                }
            }
        })
    }
}
