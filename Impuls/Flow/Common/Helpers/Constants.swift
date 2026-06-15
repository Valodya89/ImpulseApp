//
//  Constants.swift
//  MimoBike
//
//  Created by Vardan on 15.04.21.
//

import Foundation
import UIKit

struct Constant {
    
    static let screenSize = UIScreen.main.bounds
    
    struct APIKeys {
        static let GOOGLE_MAPS_API_KEY = "AIzaSyBBnsPKB01veDAEZd0MYs13FFuwJJi7KKo"

        /// 2GIS Mobile SDK access key. Obtain from https://dev.2gis.com (the key is
        /// bound to this app's bundle id). The map renders blank until a valid key
        /// is set here.
        static let TWO_GIS_API_KEY = "0a0add79-3ab9-43bf-ab9b-7e2d548fd73d"
    }

    struct Storyboards {
        static let splash = "Splash"
        static let signIn = "SignIn"
        static let map = "Map"
        static let home = "Home"
        static let completeAccount = "CompleteAccount"
        static let account = "Account"
        static let accountCover = "AccountCover"
        static let scan = "Scan"
        static let wallet = "Wallet"
        static let transfer = "Transfer"
        static let plan = "MIPlan"
        static let orderCard = "OrderCard"
        static let scooterPlan = "ScooterPlan"
        static let parkingPhotoCamera = "ParkingPhotoCamera"
    }
   
    struct CellIdentifiers {
        
    }
    
    struct Segues {

    }
    
    struct NotificationNames {
    }
    
    /// calculations based on iPhone 11 pro screen size  (375 x 812)
    struct CornerRadius {
        
        /// proportions from height
        static let cornerRadius8 = screenSize.height * 0.009852216749
        static let cornerRadius12 = screenSize.height * 0.01477832512
        static let cornerRadius19 = screenSize.height * 0.023399015
        static let cornerRadius21 = screenSize.height * 0.02586206897
        static let cornerRadius23 = screenSize.height * 0.02832512315
        static let cornerRadius24 = screenSize.height * 0.02955665025
        static let cornerRadius32 = screenSize.height * 0.039408867
        static let cornerRadius53 = screenSize.height * 0.06527093596

        /// proportions from width
        static let cornerRadiusFromScreenWidth8 = screenSize.width * 0.02133333333
        static let cornerRadiusFromScreenWidth17half = screenSize.width * 0.04666666667
        static let cornerRadiusFromScreenWidth19 = screenSize.width * 0.05066666667
        static let cornerRadiusFromScreenWidth20 = screenSize.width * 0.05333333333
        static let cornerRadiusFromScreenWidth24 = screenSize.width * 0.064
    }
    
    struct Height {
        
        static let height15 = screenSize.height * 0.0184729064
        static let height37 = screenSize.height * 0.04556650246
        static let height54 = screenSize.height * 0.06650246305
        static let height70 = screenSize.height * 0.08620689655
        static let height106 = screenSize.height * 0.1305418719
        static let height184 = screenSize.height * 0.226601
    }
    
    struct Width {
        
        static let width15 = screenSize.width *  0.04
        static let width68 = screenSize.width *  0.1813333333
        static let width79 = screenSize.width * 0.2106666667
        static let width200 = screenSize.width * 0.5333333333
        static let width250 = screenSize.width * 0.6666666667
        static let width288 = screenSize.width * 0.768
        static let width335 = screenSize.width * 0.8933
        
        static let width075 = screenSize.width * 0.75
        static let width085 = screenSize.width * 0.85
    }
    
    struct Constraint {
        static let constant15 = screenSize.height * 0.0184729064
        static let constant37 = screenSize.height * 0.04556650246
        static let constant72 = screenSize.height * 0.08866995074
        static let constant184 = screenSize.height * 0.166601
        static let constant224 = screenSize.height * 0.275862069
    }
    
    struct URLString {
        static let terms = "https://privacy.impulsepower.ru/<language>/agreement"
        static let privacyPolicy = "https://privacy.impulsepower.ru/<language>/privacy-policy"
    }
    
    struct Lottie {
        static let logo = "logo"
        static let bike = "bike"
        static let plus = "plus"
    }
    
    struct MeasureName {
        static let distance = "km"
        static let calories = "kcal"
        static let carbon = "car"
    }
    
    struct Font {
        static let robotoBold = "Roboto-Bold"
    }
    
    struct Notifications {
        static let LanguageUpdate = NSNotification.Name(rawValue: "Mimo.Notification.Language")
        static let updateUserUI = NSNotification.Name(rawValue: "Mimo.Notification.UpdateUser")
        static let updateUserPicture = NSNotification.Name(rawValue: "Mimo.Notification.UpdatePicture")
        static let updateFinansialState = NSNotification.Name(rawValue: "Mimo.Notification.UpdatePicture")
        static let accountVerified = NSNotification.Name(rawValue: "Mimo.Notification.AccountVerified")
        static let updateBlureState = NSNotification.Name(rawValue: "Mimo.Notification.updateBlureState")
        static let emailVerificationCode = NSNotification.Name(rawValue: "Mimo.Notification.emailVerificationCode")
        static let paymentCallback = NSNotification.Name(rawValue: "Mimo.Notification.paymentCallback")
    }
}
