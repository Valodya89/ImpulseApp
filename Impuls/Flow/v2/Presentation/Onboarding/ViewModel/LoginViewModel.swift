//
//  LoginViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 17.09.23.
//

import Foundation
import Combine
import CoreLocation
import PhoneNumberKit

class LoginViewModel: MimoBaseViewModel, ObservableObject {
    
    private var cancellables = Set<AnyCancellable>()
    private let locationManager: MimoLocationManager
    private let geoCoder = CLGeocoder()
    
    private let worker: LoginWorkerProtocol = LoginWorker()
    
    private var steps: Set<LoginStep> = [.phoneNumber]
    
    @Published var loginStep: LoginStep = .phoneNumber
    @Published var isTermsAccepted: Bool = false
    @Published var isPrivacyPoliceAccepted: Bool = false
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
            getAvailableServices()
        }
    }
    @Published var exampleNumber: String?
    @Published var numberMask: String?
    @Published var isDeviceVerifid: Bool?
    @Published var isAccountCompleted: Bool?
    @Published var userData: UserResponse?
    @Published var name: String = ""
    @Published var surname: String = ""
    @Published var bithday: Date?
    @Published var gender: String = ""
    @Published var email: String = ""
    
    @Published var otpCode: String? {
        didSet {
            if otpCode == nil {
                isValidOTP = nil
            }
        }
    }
    @Published var otpMethod: OTPMethod = .CALL
    @Published var isValidOTP: Bool?
    @Published var emailVerificationCodeSent: Bool?
    @Published var isAccountFullCompleted: Bool = false
    
    @Published private(set) var availableProducts: [ProductCardViewModel] = []
    
    var activeTrips: [AnyObject]
    
    var formattedPhoneNumber: String {
        let dialCode = selectedCountry?.dial_code ?? ""
        let phoneNumber = phoneNumber.trimmingCharacters(in: .whitespaces)
        return "\(dialCode) \(phoneNumber)"
    }
    
    init(locationManager: MimoLocationManager, activeTrips: [AnyObject]) {
        self.locationManager = locationManager
        self.activeTrips = activeTrips
        
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
        
        locationManager.authorizationStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthorized in
                if !isAuthorized {
                    self?.selectedCountry = ApplicationSettings.shared.countryCodes.first(where: { $0.code == "AM" })
                }
            }
            .store(in: &cancellables)

        worker.userDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self else { return }

                self.name = data?.name ?? ""
                self.surname = data?.surname ?? ""
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd-MM-yyyy"
                if let birtday = data?.birthday {
                    let components = birtday.components(separatedBy: "-")
                    if components.count == 3 {
                        let day = components[0]
                        let month = components[1]
                        let year = components[2]
                        
                        if day.count == 2 && month.count == 2 && year.count == 4 {
                            self.bithday = dateFormatter.date(from: birtday)
                        } else {
                            isAccountCompleted = false
                        }
                    } else {
                        isAccountCompleted = false
                    }
                } else {
                    isAccountCompleted = false
                }
                self.gender = Gender(rawValue: data?.gender ?? "")?.title ?? ""
                self.email = data?.email ?? ""
            }
            .store(in: &cancellables)
    }
    
    deinit {
        print("LOGIN VIEW MODEL ---- deinit")
    }
    
    func invalidate() {
        cancellables.forEach({ $0.cancel() })
        cancellables.removeAll()
    }
    
    func signIn() {
        let phoneNumber = (self.selectedCountry?.dial_code ?? "") + self.phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        worker.signIn(phoneNumber: phoneNumber)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] failure in
                switch failure {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] isDeviceVerifid, isAccountCompleted, _, otpMethod in
                guard let self else { return }
                self.otpMethod = otpMethod ?? .CALL
                self.isDeviceVerifid = isDeviceVerifid
                if self.isAccountCompleted == nil {
                    self.isAccountCompleted = isAccountCompleted
                }
                
                if self.isDeviceVerifid ?? false {
                    if !(self.isAccountCompleted ?? false) {
                        self.set(step: .personalInfo)
                    }
                } else {
                    self.set(step: .otp)
                }
                
                self.isAccountFullCompleted = (self.isAccountCompleted ?? false) && (self.isDeviceVerifid ?? false)
            }
            .store(in: &cancellables)
    }
    
    func verifyDevice() {
        guard let otpCode else { return }
        let phoneNumber = (self.selectedCountry?.dial_code ?? "") + self.phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        worker.verifyDevice(phoneNumber: phoneNumber, code: otpCode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] failure in
                switch failure {
                case .failure(let error):
                    self?.errorMessage = error.message
                    self?.isValidOTP = false
                default: break
                }
            } receiveValue: { [weak self] data in
                guard let self else { return }
                
                self.isAccountCompleted = data.user?.isAccountComplated
                self.isDeviceVerifid = true

                if self.isDeviceVerifid ?? false {
                    if !(self.isAccountCompleted ?? false) {
                        self.set(step: .personalInfo)
                    }
                } else {
                    self.set(step: .otp)
                }
                
                self.isAccountFullCompleted = (self.isAccountCompleted ?? false) && (self.isDeviceVerifid ?? false)
            }
            .store(in: &cancellables)
    }
    
    func updatePersonalInfo() {
        guard let bithday else { return }
        let birtday = bithday.toString(format: .custom("dd-MM-yyyy"))
        guard let gender = Gender.allCases.first(where: { $0.title == gender })?.rawValue else { return }
        worker.updatePersonalInfo(name: name, surename: surname, birthday: birtday, gender: gender, email: email)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] failure in
                switch failure {
                case .failure(let error): self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] data in
                self?.userData = data
                self?.availableProducts.enumerated().forEach { index, value in
                    self?.availableProducts[index].isSelected = data.services?.contains(value.service) ?? false
                }
                StorageManager().store(data.isAccountComplated, key: .isAccountCompleted)
//                self?.set(step: .preferedServices)
                self?.openHomeView()
            }
            .store(in: &cancellables)
    }
    
    func skipEmailVerification() {
        guard let bithday else { return }
        let birtday = bithday.toString(format: .custom("dd-MM-yyyy"))
        guard let gender = Gender.allCases.first(where: { $0.title == gender })?.rawValue else { return }
        worker.updatePersonalInfo(name: name, surename: surname, birthday: birtday, gender: gender, email: email)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] failure in
                switch failure {
                case .failure(let error): self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] data in
                guard let self else { return }
                (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.set(rootView: HomeView(
                    homeViewModel: MimoHomeViewModel(
                        worker: Resolver.resolve(),
                        locationManager: Resolver.resolve(),
                        messageServicce: Resolver.resolve(),
                        activeTrips: activeTrips
                    )
                ).edgesIgnoringSafeArea(.all))
            }
            .store(in: &cancellables)
    }
    
    func sendEmailCode() {
        worker.sendEmailCode()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] failure in
                switch failure {
                case .failure(let error): self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] data in
                self?.emailVerificationCodeSent = data
            }
            .store(in: &cancellables)
    }
    
    func toggleSelection(for product: ProductCardViewModel) {
        if let index = availableProducts.firstIndex(where: { $0.service == product.service }) {
            availableProducts[index].isSelected.toggle()
        }
    }
    
    func getAvailableServices() {
        guard let alpha2code = selectedCountry?.code,
                  let isoCountryCode = CountryUtilities.getAlphaThreeCode(byAlpha2Code: alpha2code) else { return }
                
        worker.getAvailableServices(countryCode: isoCountryCode)
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] availableServices in
                let allowedServices = self?.userData?.services ?? []
                
                self?.availableProducts = availableServices.compactMap {
                    ProductCardViewModel(type: $0, isSelected: true)
                }
                
                ApplicationSettings.shared.availableServices = availableServices.compactMap { $0.mimoType }
            }
            .store(in: &cancellables)
    }
    
    func updatePreferedServices() {
        let selectedServices: [String] = availableProducts
            .filter({$0.isSelected})
            .compactMap { $0.service }
        
        guard !selectedServices.isEmpty else { return }
        
        worker.updateAllowedServices(selectedServices)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] in
                UserManager.share.userResponse?.services = selectedServices
                self?.openHomeView()
            }
            .store(in: &cancellables)
    }
    
    private func openHomeView() {
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.set(rootView: HomeView(
            homeViewModel: MimoHomeViewModel(
                worker: Resolver.resolve(),
                locationManager: Resolver.resolve(),
                messageServicce: Resolver.resolve(),
                activeTrips: activeTrips
            )
        ).edgesIgnoringSafeArea(.all))
    }
    
    func previousStep() -> Bool {
        guard steps.count > 1 else { return false }
        
        var stepsArray = Array(steps).sorted(by: { $0.rawValue < $1.rawValue })
        stepsArray = stepsArray.dropLast()
        self.steps = Set(stepsArray)
        self.loginStep = stepsArray.last ?? .phoneNumber
        
        return true
    }
    
    func set(step: LoginStep) {
        loginStep = step
        steps.insert(step)
    }
    
    func getLanguage() -> String {
        let language = StorageManager().fetch(key: .language, type: String.self)
        switch language {
        case "English": return "en"
        case "Русский": return "ru"
        case "Հայերեն": return "hy"
        case "ru": return "ru"
        case "hy": return "hy"
        case "en": return "en"
        default:
            return String(Locale.preferredLanguages[0].prefix(2))
        }
    }
    
    func isValid() -> Bool {
        switch loginStep {
        case .phoneNumber:
            let phoneNumber = (self.selectedCountry?.dial_code ?? "") + self.phoneNumber.trimmingCharacters(in: .whitespaces)
            return isTermsAccepted && isPrivacyPoliceAccepted && PhoneNumberKit().isValidPhoneNumber(phoneNumber)
        case .otp:
            guard let otpCode else { return false }
            return otpCode.count == 4
        case .personalInfo:
            return !name.isEmpty && !surname.isEmpty && bithday != nil && !gender.isEmpty
        case .preferedServices:
            return availableProducts.contains(where: { $0.isSelected })
        }
    }
    
    func formatPhoneNumber() {
        let countryCode = selectedCountry?.code ?? ""
        let dialCode = selectedCountry?.dial_code ?? ""
        let exampleNumber = PhoneNumberKit().getFormattedExampleNumber(forCountry: countryCode, ofType: .mobile, withFormat: .international)
        self.exampleNumber = exampleNumber?.replacingOccurrences(of: "\(dialCode)", with: "").trimmingCharacters(in: .whitespaces)
        self.numberMask = self.exampleNumber?.replacingOccurrences(of: "[0-9]", with: "#", options: .regularExpression)
    }
}

extension LoginViewModel {
    enum LoginStep: Int {
        case phoneNumber = 0
        case otp = 1
        case personalInfo = 2
        case preferedServices = 3
        
        var title: String {
            switch self {
            case .phoneNumber: return "MOBILE_sign_in_enter_phone_number".localized()
            case .otp: return "MOBILE_sign_in_verify_phone_number".localized()
            case .personalInfo: return "MOBILE_sign_in_about_yourself".localized()
            case .preferedServices: return "MOBILE_sign_in_onboard_service_title".localized()
            }
        }
        
        var buttonTitle: String {
            switch self {
            case .phoneNumber, .personalInfo, .preferedServices:  return "MOBILE_global_next".localized()
            case .otp: return "MOBILE_sign_in_code_verification".localized()
            }
        }
    }
    
    enum Gender: String, CaseIterable {
        case male = "MALE"
        case female = "FEMALE"
        
        var title: String {
            switch self {
            case .male: return "MOBILE_registartion_sex_bottom_sheet_male".localized()
            case .female: return "MOBILE_registartion_sex_bottom_sheet_female".localized()
            }
        }
    }
}
