//
//  PartnershipViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.10.23.
//

import Foundation
import Combine
import PhoneNumberKit
import CoreLocation

class PartnershipViewModel: MimoBaseViewModel, ObservableObject {
    
    private let worker: PartnershipWorkerProtocol
    private let locationManager: MimoLocationManager
    private let geoCoder = CLGeocoder()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var exampleNumber: String?
    @Published var numberMask: String?
    @Published var phoneNumber: String = "" {
        didSet {
            let formatedNumber = phoneNumber.format(with: numberMask ?? "")
            if phoneNumber != formatedNumber {
                phoneNumber = formatedNumber
            }
            
            if phoneNumber.count > numberMask?.count ?? 0 {
                phoneNumber = String(phoneNumber.prefix(numberMask?.trimmingCharacters(in: .whitespaces).count ?? 0))
            }
        }
    }
    
    @Published var selectedCountry: CountryCodeResponse? {
        didSet {
            formatPhoneNumber()
            phoneNumber = ""
        }
    }
    
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var location: String = ""
    
    @Published var applicationSubmited: Bool = false
    
    init(worker: PartnershipWorkerProtocol, locationManager: MimoLocationManager) {
        self.worker = worker
        self.locationManager = locationManager
        super.init()
        
        locationManager.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.geoCoder.reverseGeocodeLocation(location.clLocation, completionHandler: { placemarks, error in
                    guard let currentLocPlacemark = placemarks?.first else { return }
                    if self?.selectedCountry == nil {
                        self?.selectedCountry = ApplicationSettings.shared.countryCodes.first(where: { $0.code == currentLocPlacemark.isoCountryCode ?? "AM" })
                    }
                })
            }
            .store(in: &cancellables)
    }
    
    func submit() {
        var _phoneNumber: String?
        if !(phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty) {
            _phoneNumber = (self.selectedCountry?.dial_code ?? "") + self.phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        }
        
        worker.submitApplication(fullName: fullName, email: email, phoneNumber: _phoneNumber, location: location)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                case .finished: break
                }
            } receiveValue: { [weak self] _ in
                self?.applicationSubmited = true
            }
            .store(in: &cancellables)
    }
    
    func isValid() -> Bool {
        return !fullName.isEmpty && email.isEmail && !location.isEmpty
    }
    
    func formatPhoneNumber() {
        let countryCode = selectedCountry?.code ?? ""
        let dialCode = selectedCountry?.dial_code ?? ""
        let exampleNumber = PhoneNumberKit().getFormattedExampleNumber(forCountry: countryCode, ofType: .mobile, withFormat: .international)
        self.exampleNumber = exampleNumber?.replacingOccurrences(of: "\(dialCode)", with: "").trimmingCharacters(in: .whitespaces)
        self.numberMask = self.exampleNumber?.replacingOccurrences(of: "[0-9]", with: "#", options: .regularExpression)
    }
}
