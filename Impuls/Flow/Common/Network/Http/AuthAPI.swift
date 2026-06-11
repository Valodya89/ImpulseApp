//
//  AuthAPI.swift
//  MimoBike
//
//  Created by Albert on 15.05.21.
//

import Foundation

public extension UIDevice {

    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
            #if os(iOS)
            switch identifier {
            case "iPod5,1":                                       return "iPod touch (5th generation)"
            case "iPod7,1":                                       return "iPod touch (6th generation)"
            case "iPod9,1":                                       return "iPod touch (7th generation)"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":           return "iPhone 4"
            case "iPhone4,1":                                     return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                        return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                        return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                        return "iPhone 5s"
            case "iPhone7,2":                                     return "iPhone 6"
            case "iPhone7,1":                                     return "iPhone 6 Plus"
            case "iPhone8,1":                                     return "iPhone 6s"
            case "iPhone8,2":                                     return "iPhone 6s Plus"
            case "iPhone9,1", "iPhone9,3":                        return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                        return "iPhone 7 Plus"
            case "iPhone10,1", "iPhone10,4":                      return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                      return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                      return "iPhone X"
            case "iPhone11,2":                                    return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                      return "iPhone XS Max"
            case "iPhone11,8":                                    return "iPhone XR"
            case "iPhone12,1":                                    return "iPhone 11"
            case "iPhone12,3":                                    return "iPhone 11 Pro"
            case "iPhone12,5":                                    return "iPhone 11 Pro Max"
            case "iPhone13,1":                                    return "iPhone 12 mini"
            case "iPhone13,2":                                    return "iPhone 12"
            case "iPhone13,3":                                    return "iPhone 12 Pro"
            case "iPhone13,4":                                    return "iPhone 12 Pro Max"
            case "iPhone14,4":                                    return "iPhone 13 mini"
            case "iPhone14,5":                                    return "iPhone 13"
            case "iPhone14,2":                                    return "iPhone 13 Pro"
            case "iPhone14,3":                                    return "iPhone 13 Pro Max"
            case "iPhone14,7":                                    return "iPhone 14"
            case "iPhone14,8":                                    return "iPhone 14 Plus"
            case "iPhone15,2":                                    return "iPhone 14 Pro"
            case "iPhone15,3":                                    return "iPhone 14 Pro Max"
            case "iPhone15,4":                                    return "iPhone 15"
            case "iPhone15,5":                                    return "iPhone 15 Plus"
            case "iPhone16,1":                                    return "iPhone 15 Pro"
            case "iPhone16,2":                                    return "iPhone 15 Pro Max"
            case "iPhone8,4":                                     return "iPhone SE"
            case "iPhone12,8":                                    return "iPhone SE (2nd generation)"
            case "iPhone14,6":                                    return "iPhone SE (3rd generation)"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":      return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":                 return "iPad (3rd generation)"
            case "iPad3,4", "iPad3,5", "iPad3,6":                 return "iPad (4th generation)"
            case "iPad6,11", "iPad6,12":                          return "iPad (5th generation)"
            case "iPad7,5", "iPad7,6":                            return "iPad (6th generation)"
            case "iPad7,11", "iPad7,12":                          return "iPad (7th generation)"
            case "iPad11,6", "iPad11,7":                          return "iPad (8th generation)"
            case "iPad12,1", "iPad12,2":                          return "iPad (9th generation)"
            case "iPad13,18", "iPad13,19":                        return "iPad (10th generation)"
            case "iPad4,1", "iPad4,2", "iPad4,3":                 return "iPad Air"
            case "iPad5,3", "iPad5,4":                            return "iPad Air 2"
            case "iPad11,3", "iPad11,4":                          return "iPad Air (3rd generation)"
            case "iPad13,1", "iPad13,2":                          return "iPad Air (4th generation)"
            case "iPad13,16", "iPad13,17":                        return "iPad Air (5th generation)"
            case "iPad2,5", "iPad2,6", "iPad2,7":                 return "iPad mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":                 return "iPad mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":                 return "iPad mini 3"
            case "iPad5,1", "iPad5,2":                            return "iPad mini 4"
            case "iPad11,1", "iPad11,2":                          return "iPad mini (5th generation)"
            case "iPad14,1", "iPad14,2":                          return "iPad mini (6th generation)"
            case "iPad6,3", "iPad6,4":                            return "iPad Pro (9.7-inch)"
            case "iPad7,3", "iPad7,4":                            return "iPad Pro (10.5-inch)"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":      return "iPad Pro (11-inch) (1st generation)"
            case "iPad8,9", "iPad8,10":                           return "iPad Pro (11-inch) (2nd generation)"
            case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7":  return "iPad Pro (11-inch) (3rd generation)"
            case "iPad14,3", "iPad14,4":                          return "iPad Pro (11-inch) (4th generation)"
            case "iPad6,7", "iPad6,8":                            return "iPad Pro (12.9-inch) (1st generation)"
            case "iPad7,1", "iPad7,2":                            return "iPad Pro (12.9-inch) (2nd generation)"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":      return "iPad Pro (12.9-inch) (3rd generation)"
            case "iPad8,11", "iPad8,12":                          return "iPad Pro (12.9-inch) (4th generation)"
            case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11":return "iPad Pro (12.9-inch) (5th generation)"
            case "iPad14,5", "iPad14,6":                          return "iPad Pro (12.9-inch) (6th generation)"
            case "AppleTV5,3":                                    return "Apple TV"
            case "AppleTV6,2":                                    return "Apple TV 4K"
            case "AudioAccessory1,1":                             return "HomePod"
            case "AudioAccessory5,1":                             return "HomePod mini"
            case "i386", "x86_64", "arm64":                       return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                              return identifier
            }
            #elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3": return "Apple TV 4"
            case "AppleTV6,2", "AppleTV11,1", "AppleTV14,1": return "Apple TV 4K"
            case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default: return identifier
            }
            #elseif os(visionOS)
            switch identifier {
            case "RealityDevice14,1": return "Apple Vision Pro"
            default: return identifier
            }
            #endif
        }

        return mapToDevice(identifier: identifier)
    }()
}

enum AuthAPI: APIProtocol {
    case getVersion
    case getLanguage
    case getState
    case getScooterState
    case updateBikeLock(state: Bool, bikeID: String)
    case trips(bookId: String, latitude: CGFloat, longitude: CGFloat)
    case getBikeTripList
    case getScooterTripList
    case getChargerRentList
    case getEVChargerRentList
    case bookBike(bookId: String, latitude: CGFloat, longitude: CGFloat)
    case bookScooter(bookId: String, latitude: CGFloat, longitude: CGFloat)
    case checkLock(bikeId: String, command: String)
    case getFinancialState(deviceID: String)
    case getTranslations
    case getMobileTranslations(languageCode: String)
    case getAccountsTranslations(languageCode: String)
    case getSharingTranslations(languageCode: String)
    case getScoterTranslations(languageCode: String)
    case getChargerTranslations(languageCode: String)
    case getEVChargerTranslations(languageCode: String)
    case getiPayTranslations(languageCode: String)
    case getGlobalSettings
    case preactivate(deviceId: String)
    case getModules
    case inviteUser(phoneNumber: String)
    case updateModule(id: String, version: Int, token: String)
    case getCountryCode(_ language: String)
    case auth(userId: String, deviceID: String)
    case deviceVerification(userId: String, deviceID: String, code: String)
    case sendCodeToEmail
    case emailVerification(code: String)
    case getToken(username: String, password: String)
    case getAuthRefreshToken(refreshToken: String)
    case getAuthDetails(token: String)
    case refreshToken(refreshToken: String, deviceID: String)
    case getUser
    case uploadFCM(token: String)
    case updatePersonalInfo(name: String, surname: String, birthday: String, gender: String)
    case updateUser(name: String, surname: String, gender: String, email: String, birthday: String, bio: String, settings: [String: Any])
    case getPhoneCodes(locale: String)
    case tranfer(id: String, amount: Double)
    case checkMimoContact(phoneNumber: String)
    case getPackages(locale: String)
    case activatePackage(packageID: String)
    case getTarrifs(locale: String)
    case updateLanguage(languageCode: String)
    case updateTranslation(key: String, language: String, module: String, value: String)
    case getPaymentMethods
    case getWallet
    case attachCard(provider: String)
    case depositFromAttachedCard(ammount: Double)
    case depositFromUnAttachedCard(ammount: Double, locale: String)
    case depositWithTelcell(amount: Double, number: String)
    case depositWithFastshift(amount: Double, number: String)
    case depositWithMyAmeria(amount: Double)
    case depositWithEasyPay(amount: Double, number: String)
    case depositFromCrypto(ammount: Double)
    case getTransactions
    case getWihtdrawals
    case orderCard(address: String, birthday: String, email: String, socialCard: String, passportImageBase64: String, phone: String)
    case deleteCard
    case cancelBikeBook(bookID: String)
    case cancelScooterBook(bookID: String)
    case beepBookedBike
    case getZoning(long: Double, lat: Double)
    case getNotificationList
    case logout(deviceId: String, token: String)
    case getAccount
    case beepBookedScooter
    case deleteAccount
    case getGateway
    case attachNewCard(type:  String)
    case sendPromoCode(code: String)
    case checkPromoStatus
    case partnershipApplication(fullName: String, email: String, phoneNumber: String?, location: String)
    case subscribeEVChargerNews(email: String)
    case unlockBikeTrip(id: String)
    case updateServices(services: [String])
    case activateInsurance
    case deactivateInsurance
    case getInsurancePrice
    
    var base: String {
        switch self {
        case .getVersion:
            return MimoBaseURLs.accounts.rawValue
        case .getLanguage:
            return MimoBaseURLs.locale.rawValue
        case .updateBikeLock:
            return MimoBaseURLs.sharing.rawValue
        case .getBikeTripList:
            return MimoBaseURLs.sharing.rawValue
        case .getScooterTripList:
            return MimoBaseURLs.scooter.rawValue
        case .getChargerRentList:
            return MimoBaseURLs.charger.rawValue
        case .getEVChargerRentList:
            return MimoBaseURLs.evCharger.rawValue
        case .getState:
            return MimoBaseURLs.sharing.rawValue
        case .getFinancialState:
            return MimoBaseURLs.payment.rawValue
        case .trips:
            return MimoBaseURLs.sharing.rawValue
        case .checkLock(_, _):
            return MimoBaseURLs.sharing.rawValue
        case .getModules:
            return MimoBaseURLs.locale.rawValue
        case .depositWithTelcell:
            return MimoBaseURLs.payment.rawValue
        case .depositWithFastshift:
            return MimoBaseURLs.payment.rawValue
        case .depositWithMyAmeria:
            return MimoBaseURLs.payment.rawValue
        case .depositWithEasyPay:
            return MimoBaseURLs.payment.rawValue
        case .depositFromCrypto:
            return MimoBaseURLs.payment.rawValue
        case .sendPromoCode:
            return MimoBaseURLs.payment.rawValue
        case .getGlobalSettings:
            return MimoBaseURLs.accounts.rawValue
        case .preactivate:
            return MimoBaseURLs.sharing.rawValue
        case .bookBike:
            return MimoBaseURLs.sharing.rawValue
        case .bookScooter:
            return MimoBaseURLs.scooter.rawValue
        case .updateModule:
            return MimoBaseURLs.locale.rawValue
        case .getTransactions:
            return MimoBaseURLs.payment.rawValue
        case .getWihtdrawals:
            return MimoBaseURLs.payment.rawValue
        case .getTranslations:
            return MimoBaseURLs.locale.rawValue
        case .getMobileTranslations:
            return MimoBaseURLs.locale.rawValue
        case .getAccountsTranslations:
            return MimoBaseURLs.locale.rawValue
        case .getSharingTranslations:
            return MimoBaseURLs.locale.rawValue
        case .getScoterTranslations:
            return MimoBaseURLs.locale.rawValue
        case .getiPayTranslations:
            return MimoBaseURLs.locale.rawValue
        case .getChargerTranslations:
            return MimoBaseURLs.locale.rawValue
        case .getEVChargerTranslations:
            return MimoBaseURLs.locale.rawValue
        case .getCountryCode:
            return MimoBaseURLs.accounts.rawValue
        case .uploadFCM(_):
            print(UIDevice.current.name)
            print(UIDevice.current.systemVersion)
            print(UIDevice.current)
            print(UIDevice.current.identifierForVendor as Any)
            print(UIDevice.current.model)
            
            return MimoBaseURLs.accounts.rawValue
        case .auth:
            return MimoBaseURLs.accounts.rawValue
        case .deviceVerification:
            return MimoBaseURLs.accounts.rawValue
        case .sendCodeToEmail:
            return MimoBaseURLs.accounts.rawValue
        case .emailVerification:
            return MimoBaseURLs.accounts.rawValue
        case .refreshToken:
            return MimoBaseURLs.accounts.rawValue
        case .getUser:
            return MimoBaseURLs.accounts.rawValue
        case .updateUser, .updatePersonalInfo:
            return MimoBaseURLs.accounts.rawValue
        case .getToken:
            return MimoBaseURLs.auth.rawValue
        case .getAuthRefreshToken:
            return MimoBaseURLs.auth.rawValue
        case .getAuthDetails:
            return MimoBaseURLs.auth.rawValue
        case .getPhoneCodes:
            return MimoBaseURLs.accounts.rawValue
        case .getPackages:
            return MimoBaseURLs.sharing.rawValue
        case .getTarrifs:
            return MimoBaseURLs.sharing.rawValue
        case .updateLanguage:
            return MimoBaseURLs.locale.rawValue
        case .updateTranslation:
            return MimoBaseURLs.locale.rawValue
        case .getPaymentMethods:
            return MimoBaseURLs.payment.rawValue
        case .getWallet:
            return MimoBaseURLs.payment.rawValue
        case .tranfer:
            return MimoBaseURLs.payment.rawValue
        case .checkMimoContact:
            return MimoBaseURLs.accounts.rawValue
        case .inviteUser:
            return MimoBaseURLs.accounts.rawValue
        case .attachCard:
            return MimoBaseURLs.payment.rawValue
        case .attachNewCard:
            return MimoBaseURLs.payment.rawValue
        case .depositFromAttachedCard:
            return MimoBaseURLs.payment.rawValue
        case .depositFromUnAttachedCard:
            return MimoBaseURLs.payment.rawValue
        case .orderCard:
            return MimoBaseURLs.payment.rawValue
        case .activatePackage:
            return MimoBaseURLs.sharing.rawValue
        case .deleteCard:
            return MimoBaseURLs.payment.rawValue
        case .cancelBikeBook:
            return MimoBaseURLs.sharing.rawValue
        case .cancelScooterBook:
            return MimoBaseURLs.scooter.rawValue
        case .getScooterState:
            return MimoBaseURLs.scooter.rawValue
        case .beepBookedBike:
            return MimoBaseURLs.sharing.rawValue
        case .getZoning:
            return MimoBaseURLs.sharing.rawValue
        case .getNotificationList:
            return MimoBaseURLs.accounts.rawValue
        case .logout:
            return MimoBaseURLs.accounts.rawValue
        case .getAccount:
            return MimoBaseURLs.sharing.rawValue
        case .beepBookedScooter:
            return MimoBaseURLs.scooter.rawValue
        case .deleteAccount:
            return MimoBaseURLs.accounts.rawValue
        case .getGateway, .checkPromoStatus:
            return MimoBaseURLs.payment.rawValue
        case .partnershipApplication:
            return MimoBaseURLs.accounts.rawValue
        case .subscribeEVChargerNews:
            return MimoBaseURLs.accounts.rawValue
        case .unlockBikeTrip:
            return MimoBaseURLs.sharing.rawValue
        case .updateServices:
            return MimoBaseURLs.accounts.rawValue
        case .activateInsurance, .deactivateInsurance:
            return MimoBaseURLs.scooter.rawValue
        case .getInsurancePrice:
            return MimoBaseURLs.scooter.rawValue
        }
    }
    
    var path: String {
        switch self {
        case .getVersion:
            return "apk-version/IOS"
        case .checkPromoStatus:
            return "api/promo-code"
        case.sendPromoCode(let code):
            return "api/promo-code/\(code)"
        case .getLanguage:
            return "languages"
        case .getState:
            return "api/state"
        case .getBikeTripList:
            return "api/trip"
        case .getScooterTripList:
            return "api/trip"
        case .getChargerRentList:
            return "api/rent"
        case .getEVChargerRentList:
            return "api/charging"
        case .updateBikeLock:
            return "api/bike/lock-update"
        case .getFinancialState:
            return "api/state"
        case .trips(let bookId, _, _):
            return "api/trip/\(bookId)/scan"
        case .bookBike(let bookId, _, _):
            return "api/bike/\(bookId)/book"
        case .bookScooter(let bookId, _, _):
            return "api/scooter/\(bookId)/book"
        case .checkLock:
            return MimoBaseURLs.sharing.rawValue
        case .getModules:
            return "modules"
        case .getGlobalSettings:
            return "settings/default"
        case .preactivate:
            return "api/ride/pre-validate"
        case .depositWithTelcell:
            return "api/telcell/deposit"
        case .depositWithFastshift:
            return "api/fastshift/deposit"
        case .depositWithMyAmeria:
            return "api/myameria-pay/deposit"
        case .depositWithEasyPay:
            return "api/easypay/deposit"
            
        case .depositFromCrypto:
            return "api/crypto-cloud/deposit"
        case .updateModule:
            return "api/module"
        case .activatePackage(let packageId):
            return "api/package/\(packageId)/activate"
        case .getTranslations:
            return "languages"
        case .getMobileTranslations(let languageCode):
            return "mobile/translations/\(languageCode)"
        case .getAccountsTranslations(let languageCode):
            return "accounts/translations/\(languageCode)"
        case .getSharingTranslations(let languageCode):
            return "sharing/translations/\(languageCode)"
        case .getScoterTranslations(let languageCode):
            return "scooter/translations/\(languageCode)"
        case .getChargerTranslations(let languageCode):
            return "charger/translations/\(languageCode)"
        case .getEVChargerTranslations(let languageCode):
            return "ev_charger/translations/\(languageCode)"
        case .getiPayTranslations(let languageCode):
            return "ipay/translations/\(languageCode)"
        case .getCountryCode:
            return "phone-code/list"
        case .getTransactions:
            return "api/transactions"
        case .getWihtdrawals:
            return "api/transactions/withdrawals"
        case .auth:
            return "account/start"
        case .deviceVerification:
            return "account/verify-device"
        case .sendCodeToEmail:
            return "api/user/send-code"
        case .emailVerification:
            return "api/user/verify-mail"
        case .refreshToken:
            return "account/refresh-token"
        case .getUser:
            return "api/user"
        case .updateUser, .updatePersonalInfo:
            return "api/user"
        case .getAuthRefreshToken:
            fallthrough
        case .getToken:
            return "oauth/token"
        case .getAuthDetails(let token):
            return "interconnect/auth-service/\(token)"
        case .getPhoneCodes:
            return "phone-code/list"
        case .getPackages:
            return "api/package/list"
        case .getTarrifs:
            return "api/tariff/list"
        case .updateLanguage:
            return "api/language"
        case .updateTranslation:
            return "api/translation"
        case .getPaymentMethods:
            return "api/payment-methods"
        case .getWallet:
            return "api/wallet"
        case .tranfer:
            return "api/wallet/transfer"
        case .checkMimoContact(let phoneNumber):
            return "api/user/\(phoneNumber)"
        case .inviteUser(let phoneNumber):
            return "api/user/\(phoneNumber)/invite"
        case .attachCard(let provider):
            return "api/bank/card/\(provider)/attach"
        case .attachNewCard(let type):
            return "api/bank/card/\(type)/attach"
        case .depositFromAttachedCard:
            return "api/bank/card/attached/deposit"
        case .depositFromUnAttachedCard:
            return "api/bank/card/deposit"
        case .orderCard:
            return "api/card/order"
        case .deleteCard:
            return "api/bank/card/attached"
        case .cancelBikeBook(bookID: let string):
            return "api/bike/\(string)/cancel-book"
        case .cancelScooterBook(bookID: let string):
            return "api/scooter/\(string)/cancel-book"
        case .beepBookedBike:
            return "api/bike/booked/beep"
        case .getZoning:
            return "api/zone/near"
        case .uploadFCM:
            return "api/user/device"
        case .getNotificationList:
            return "api/notification"
        case .logout:
            return "api/account/logout"
        case .getAccount:
            return "api/account"
        case .deleteAccount:
            return "api/account/close"
        case .getScooterState:
            return "api/state/v2"
        case .beepBookedScooter:
            return "api/scooter/booked/beep"
        case .getGateway:
            return "api/gateway"
        case .partnershipApplication:
            return "api/partnership"
        case .subscribeEVChargerNews:
            return "api/ev-charger/news/subscribe"
        case .unlockBikeTrip(let id):
            return "api/trip/\(id)/unlock"
        case .updateServices:
            return "api/user/services"
        case .activateInsurance:
            return "insurance"
        case .deactivateInsurance:
            return "insurance/deactivate"
        case .getInsurancePrice:
            return "insurance/price"
        }
    }
    
    var header: [String : String] {
        switch self {
        case .auth:
            let header = [
                "Content-Type": "application/json",
                "locale": StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2)),
            ]
            print("header = \(header)")
            return header
        case .emailVerification:
            return [
                "Content-Type": "application/json"
            ]
        case .uploadFCM:
            return [
                "Content-Type": "application/json"
            ]
        case .updateBikeLock:
            return [
                "Content-Type": "application/json",
            ]
        case .bookBike, .bookScooter:
            return [
                "Content-Type": "application/json",
            ]
        case .trips:
            return [
                "Content-Type": "application/json"
            ]
        case .deviceVerification:
            return ["Content-Type": "application/json"]
        case .updateUser, .updatePersonalInfo:
            return ["Content-Type": "application/json"]
        case .getTranslations:
            return ["Content-Type": "application/json"]
        case .getMobileTranslations:
            return ["Content-Type": "application/json"]
        case .getAccountsTranslations:
            return ["Content-Type": "application/json"]
        case .getSharingTranslations, .getScoterTranslations, .getChargerTranslations, .getEVChargerTranslations:
            return ["Content-Type": "application/json"]
        case .updateModule(_, _, let token):
            return [
                "Authorization": "Bearer \(token)"
            ]
        case .getEVChargerRentList:
            return [
                "locale": StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))
            ]
        case .getCountryCode(let language):
            return ["locale": StorageManager().fetch(key: .language, type: String.self) ?? language]
        case .getAuthRefreshToken:
            fallthrough
        case .getToken:
            let username = "mimo"
            let password = "mimo_secret"
            
            let loginString = String(format: "%@:%@", username, password)
            let loginData = loginString.data(using: String.Encoding.utf8)!
            let base64LoginString = loginData.base64EncodedString()
            
            return ["Authorization": "Basic \(base64LoginString)"]
        case .depositFromUnAttachedCard(_, let locale):
            return [
                "Content-Type": "application/json",
                "locale": StorageManager().fetch(key: .language, type: String.self) ?? locale
            ]
        case .depositFromAttachedCard:
            return [
                "Content-Type": "application/json",
            ]
        case .depositWithTelcell:
            return [
                "Content-Type": "application/json",
            ]
        case .depositWithFastshift:
            return [
                "Content-Type": "application/json",
            ]
        case .depositWithMyAmeria:
            return [
                "Content-Type": "application/json",
            ]
        case .depositWithEasyPay:
            return [
                "Content-Type": "application/json",
            ]
        case .depositFromCrypto:
            return [
                "Content-Type": "application/json",
            ]
        case .getVersion:
            return [
                "Content-Type": "application/json",
            ]
        case .getPhoneCodes(let locale):
            return ["locale": StorageManager().fetch(key: .language, type: String.self) ?? locale]
        case .getPackages(let locale):
            return [
                "locale": locale == "" ? StorageManager().fetch(key: .language, type: String.self) ?? "en" : locale
            ]
        case .getTarrifs(let locale):
            return [
                "locale": locale == "" ? StorageManager().fetch(key: .language, type: String.self) ?? "en" : locale
            ]
        case .tranfer:
            return [
                "Content-Type": "application/json"
            ]
        case .getPaymentMethods, .attachCard:
            return [
                "locale": StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2)),
                "Content-Type": "application/json"
            ]
        case .orderCard:
            return [
                "Content-Type": "application/json"
            ]
        case .logout(_, _):
            
            let username = "mimo"
            let password = "mimo_secret"
            
            let loginString = String(format: "%@:%@", username, password)
            let loginData = loginString.data(using: String.Encoding.utf8)!
            let base64LoginString = loginData.base64EncodedString()
            
            return ["Content-Type": "application/json",
                    "Authorization": "Basic \(base64LoginString)"]
        case .getAccount, .checkPromoStatus, .partnershipApplication, .subscribeEVChargerNews, .unlockBikeTrip, .updateServices:
            return [
                "Content-Type": "application/json"
            ]
        case .attachNewCard:
            return [
                "Content-Type": "application/json",
                "locale": StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))
            ]
        case .activateInsurance, .getInsurancePrice, .deactivateInsurance:
            return [
                "locale": StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2)),
                "Content-Type": "application/json"
            ]
        default:
            return [:]
        }
    }
    
    var query: [String : String] {
        switch self {
        case .preactivate(let deviceId):
            return [
                "deviceId": deviceId
            ]
        case .getFinancialState(let deviceID):
            print("deviceID = \(deviceID)")
            return [
                "deviceId": deviceID
            ]
        case .getZoning(long: let long, lat: let lat):
            return [
                "longitude": String(long),
                "latitude": String(lat)
            ]
        case .getNotificationList:
            return ["sort" : "date,DESC"]
        case .getBikeTripList:
            return ["sort" : "end,DESC",
                    "size": "10000"]
        case .getScooterTripList:
            return ["sort" : "end,DESC",
                    "size": "10000"]
        case .getChargerRentList:
            return ["sort" : "end,DESC",
                    "size": "10000"]
        case .getEVChargerRentList:
            return ["sort" : "end,DESC",
                    "size": "10000"]
        default:
            return [:]
        }
    }
    
    var bodyString: String? {
        return nil
    }
    var body: [String : Any]? {
        switch self {
        case .getLanguage:
            return nil
        case .getCountryCode:
            return nil
        case let .auth(userId, deviceID):
            let params = [
                "userId": userId,
                "deviceId": deviceID
            ]
            print("params = \(params)")
            return params
        case let .updateBikeLock(state, bikeID):
            return [
                "bike": bikeID,
                "locked": state
            ]
        case let .deviceVerification(userId, deviceID, code):
            return [
                "userId": userId,
                "deviceId": deviceID,
                "code": code
            ]
        case .trips(_, let latitude, let longitude):
            return [
                "longitude": longitude,
                "latitude": latitude
            ]
        case .bookBike(_, let latitude, let longitude):
            return [
                "longitude": longitude,
                "latitude": latitude
            ]
        case .bookScooter(_, let latitude, let longitude):
            return [
                "longitude": longitude,
                "latitude": latitude
            ]
        case .checkLock(let bikeId, let command):
            return [
                "bike": bikeId,
                "command": command
            ]
        case .uploadFCM(let token):
            guard let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
                return [:]
            }
            let param = [
                "id": DeviceCheckManager.shared.deviceUnicToken, //UIDevice.current.identifierForVendor?.uuidString ?? "",
                "model": UIDevice.modelName,
                "osVersion": "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
                "appVersion": appVersion,
                "token": token
            ]
            print("param = \(param)")
            return param
        case let .updateUser(name, surname, gender, email, birthday, bio, settings):
            return [
                "name": name,
                "surname": surname,
                "gender": gender,
                "email": email,
                "birthday": birthday,
                "bio": bio,
                "settings": settings
            ]
        case let .updatePersonalInfo(name: name, surname: surname, birthday: birthday, gender: gender):
            return [
                "name": name,
                "surname": surname,
                "gender": gender,
                "birthday": birthday
            ]
        case .getToken(let username, let password):
            return [
                "username": username,
                "password": password,
                "grant_type": "password"
            ]
        case .getAuthRefreshToken(let refreshToken):
            return [
                "refresh_token": refreshToken,
                "grant_type": "refresh_token"
            ]
        case .updateModule(let id, let version, _):
            return [
                "id": id,
                "version": version
            ]
        case .updateLanguage(let languageCode):
            return [
                "id": languageCode
            ]
        case .updateTranslation(let key, let language, let module, let value):
            return [
                "key": key,
                "language": language,
                "module": module,
                "value": value
            ]
        case .tranfer(let id, let amount):
            return [
                "receiverId": id,
                "amount": amount
            ]
        case .depositFromAttachedCard(let ammout):
            return [
                "amount": ammout
            ]
        case .orderCard(let address, let birthday, let email, let socialCard, let passportImageBase64, let phone):
            var data =  [
                "address": address,
                "birthday": birthday,
                "email": email,
                "scn": socialCard,
                "pass64": passportImageBase64,
                "phone": phone
            ]
            
            var data2 =  [
                "address": address,
                "birthday": birthday,
                "email": email,
                "scn": socialCard,
                "pass64": "passportImageBase64",
                "phone": phone
            ]
            print("data2 = \(data2)")
            return data
        case .depositFromUnAttachedCard(let amount, _):
            return [
                "amount": amount,
            ]
        case .depositWithTelcell(let amount, let number):
            return [
                "amount": amount,
                "number": number
            ]
        case .depositWithMyAmeria(let amount):
            return [
                "amount": amount
            ]
        case .depositWithEasyPay(let amount, let number):
            return [
                "amount": amount,
                "number": number
            ]
        case .depositFromCrypto(let ammout):
            return [
                "amount": ammout
            ]
        case .emailVerification(let code):
            return [
                "code": code
            ]
        case let .refreshToken(refreshToken, deviceID):
            return [ "refreshToken": refreshToken,
                     "deviceId": deviceID
            ]
        case let .logout(deviceId, _):
            return [ "deviceId": deviceId ]
        case let .partnershipApplication(fullName: fullName, email: email, phoneNumber: phoneNumber, location: location):
            var dict: [String: String] = ["fullName": fullName, "email": email, "location": location]
            
            if let phoneNumber {
                dict.updateValue(phoneNumber, forKey: "phone")
            }
            
            return dict
        case .subscribeEVChargerNews(let email):
            return ["email": email]
        case .updateServices(let services):
            return ["services": services]
        default:
            return nil
        }
    }
    
    var formData: MultipartFormData? {
        return nil
    }
    
    var method: RequestMethod {
        switch self {
        case .getLanguage, .checkPromoStatus, .getVersion:
            return .get
        case .uploadFCM:
            return .put
        case .getCountryCode:
            return .get
        case .getBikeTripList:
            return .get
        case .getScooterTripList:
            return .get
        case .getChargerRentList:
            return .get
        case .getEVChargerRentList:
            return .get
        case .updateBikeLock:
            return .patch
        case .trips, .sendPromoCode:
            return .patch
        case .getState, .getScooterState:
            return .get
        case .bookBike:
            return .patch
        case .bookScooter:
            return .patch
        case .checkLock:
            return .get
        case .getFinancialState:
            return .get
        case .getTransactions:
            return .get
        case .getWihtdrawals:
            return .get
        case .getTranslations:
            return .get
        case .getMobileTranslations:
            return .get
        case .getAccountsTranslations:
            return .get
        case .getSharingTranslations, .getScoterTranslations, .getiPayTranslations, .getChargerTranslations, .getEVChargerTranslations:
            return .get
        case .depositWithTelcell, .depositWithFastshift, .depositWithEasyPay, .depositWithMyAmeria:
            return .patch
        case .auth:
            return .post
        case .deviceVerification:
            return .post
        case .sendCodeToEmail:
            return .patch
        case .emailVerification:
            return .patch
        case .refreshToken:
            return .post
        case .getUser:
            return .get
        case .updateUser, .updatePersonalInfo:
            return .put
        case .getToken:
            return .post
        case .getAuthRefreshToken:
            return .post
        case .getAuthDetails:
            return .get
        case .getPhoneCodes:
            return .get
        case .getPackages:
            return .get
        case .getTarrifs:
            return .get
        case .getModules:
            return .get
        case .updateModule:
            return .post
        case .updateLanguage:
            return .post
        case .updateTranslation:
            return .post
        case .getPaymentMethods:
            return .get
        case .getWallet:
            return .get
        case .tranfer:
            return .patch
        case .checkMimoContact:
            return .get
        case .inviteUser:
            return .patch
        case .attachCard:
            return .patch
        case .depositFromAttachedCard:
            return .patch
        case .depositFromUnAttachedCard:
            return .patch
        case .depositFromCrypto:
            return .post
        case .orderCard:
            return .post
        case .activatePackage:
            return .patch
        case .deleteCard:
            return .delete
        case .getGlobalSettings:
            return .get
        case .preactivate:
            return .get
        case .cancelBikeBook:
            return .patch
        case .cancelScooterBook:
            return .patch
        case .beepBookedBike:
            return .post
        case .getZoning:
            return .get
        case .getNotificationList:
            return .get
        case .deleteAccount:
            return .post
        case .logout:
            return .post
        case .getAccount:
            return .get
        case .beepBookedScooter:
            return .post
        case .getGateway:
            return .get
        case .attachNewCard:
            return .patch
        case .partnershipApplication:
            return .post
        case .subscribeEVChargerNews:
            return .post
        case .unlockBikeTrip:
            return .patch
        case .updateServices:
            return .post
        case .getInsurancePrice:
            return .get
        case .activateInsurance:
            return .post
        case .deactivateInsurance:
            return .get
        }
    }
}
