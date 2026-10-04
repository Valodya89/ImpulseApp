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

    /// Location permission gate of the phone step: Next stays disabled until the
    /// rider has granted "when in use" (or "always") access. The status is replayed
    /// by the location manager, so it is right even when the system prompt was
    /// answered before this screen opened.
    @Published private(set) var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined

    /// Set once the first fix has been reverse-geocoded, so a late fix does not
    /// swap the dial code under a number the rider is already typing.
    private var hasResolvedCountryFromLocation = false

    var activeTrips: [AnyObject]

    var isLocationAuthorized: Bool {
        locationAuthorizationStatus == .authorizedWhenInUse || locationAuthorizationStatus == .authorizedAlways
    }

    /// The rider said no (or the device forbids it): the only way forward is Settings.
    var isLocationDenied: Bool {
        locationAuthorizationStatus == .denied || locationAuthorizationStatus == .restricted
    }

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
                guard let self, !self.hasResolvedCountryFromLocation else { return }
                self.hasResolvedCountryFromLocation = true
                self.geoCoder.reverseGeocodeLocation(location.clLocation, completionHandler: { [weak self] placemarks, _ in
                    guard let self else { return }
                    // A geocoder failure must never block sign-in: the dial code
                    // simply stays on the fallback and the country stays unknown.
                    guard let alpha2 = placemarks?.first?.isoCountryCode else {
                        self.hasResolvedCountryFromLocation = false
                        return
                    }
                    DispatchQueue.main.async {
                        self.applyLocatedCountry(alpha2: alpha2)
                    }
                })
            }
            .store(in: &cancellables)

        locationManager.authorizationStatusValuePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                self.locationAuthorizationStatus = status
                if self.selectedCountry == nil {
                    // Nothing to locate yet (or ever, when denied): start from the
                    // fallback so the phone field is usable straight away.
                    self.selectedCountry = self.fallbackCountry()
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

    // MARK: - Location permission gate

    /// "Allow" on the location card: shows the system prompt while the status is
    /// not determined. Asks for "when in use" only; "always" is never requested here.
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// "Open Settings" on the location card after a denial.
    func openLocationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    /// The rider's country from the first fix: pre-selects the dial code and is
    /// stored as ISO alpha-3 in the application settings. Impulse keeps its fixed
    /// `Constant.requestCountryCode` request header untouched; the stored value only
    /// feeds the places that already read `ApplicationSettings.isoCountryCode`.
    private func applyLocatedCountry(alpha2: String) {
        if let alpha3 = CountryUtilities.getAlphaThreeCode(byAlpha2Code: alpha2) {
            ApplicationSettings.shared.isoCountryCode = alpha3
        }

        guard let located = ApplicationSettings.shared.countryCodes.first(where: { $0.code == alpha2 }) else { return }

        // Only replace the pre-selected fallback, and only while the field is still
        // empty: a country the rider picked or typed against is theirs.
        let isStillOnFallback = selectedCountry == nil || selectedCountry?.code == fallbackCountry()?.code
        if isStillOnFallback && phoneNumber.isEmpty && selectedCountry?.code != located.code {
            selectedCountry = located
        }
    }

    /// Dial code to show before (or without) a fix: the country Impulse serves
    /// (`Constant.requestCountryCode`, alpha-3), then Armenia as in the sibling apps.
    private func fallbackCountry() -> CountryCodeResponse? {
        let codes = ApplicationSettings.shared.countryCodes
        if let fixed = Constant.requestCountryCode,
           let match = codes.first(where: { $0.code.flatMap { CountryUtilities.getAlphaThreeCode(byAlpha2Code: $0) } == fixed }) {
            return match
        }
        return codes.first(where: { $0.code == "AM" })
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
                
                // A verified device goes straight to Home, whatever the account
                // is still missing: profile details and documents are asked for
                // by `ActionEligibilityFlow` when an action actually needs them
                // (attaching a card, starting a ride, charging).
                if !(self.isDeviceVerifid ?? false) {
                    self.set(step: .otp)
                }

                self.isAccountFullCompleted = self.isDeviceVerifid ?? false
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

                // A verified device goes straight to Home, whatever the account
                // is still missing: profile details and documents are asked for
                // by `ActionEligibilityFlow` when an action actually needs them
                // (attaching a card, starting a ride, charging).
                if !(self.isDeviceVerifid ?? false) {
                    self.set(step: .otp)
                }

                self.isAccountFullCompleted = self.isDeviceVerifid ?? false
            }
            .store(in: &cancellables)
    }
    
    func updatePersonalInfo() {
        // Make birthday optional - only include if it has a value
        var birtday: String? = nil
        if let bithday {
            birtday = bithday.toString(format: .custom("dd-MM-yyyy"))
        }
        
        // Make gender optional - only include if it has a value
        let genderValue = Gender.allCases.first(where: { $0.title == gender })?.rawValue
        
        worker.updatePersonalInfo(name: name, surename: surname, birthday: birtday, gender: genderValue, email: email)
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
        // Make birthday optional - only include if it has a value
        var birtday: String? = nil
        if let bithday {
            birtday = bithday.toString(format: .custom("dd-MM-yyyy"))
        }
        
        // Make gender optional - only include if it has a value
        let genderValue = Gender.allCases.first(where: { $0.title == gender })?.rawValue
        
        worker.updatePersonalInfo(name: name, surename: surname, birthday: birtday, gender: genderValue, email: email)
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
            // Location permission is part of the gate: Next waits for it.
            guard isLocationAuthorized else { return false }
            let phoneNumber = (self.selectedCountry?.dial_code ?? "") + self.phoneNumber.trimmingCharacters(in: .whitespaces)
            return isTermsAccepted && isPrivacyPoliceAccepted && PhoneNumberKit().isValidPhoneNumber(phoneNumber)
        case .otp:
            guard let otpCode else { return false }
            return otpCode.count == 4
        case .personalInfo:
            // Gender and birthday are now optional, only name and surname are required
            return !name.isEmpty && !surname.isEmpty
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
