//
//  MimoBaseURL.swift
//  MimoBike-Dev
//
//  Created by Razmik Mkhitaryan on 01.05.23.
//

import Foundation

enum MimoBaseURLs: String {
    case locale = "https://locale.impulsepower.ru/"
    case accounts = "https://dev-accounts.impulsepower.ru/"
    case sharing = "https://dev-sharing.impulsepower.ru/"
    case auth = "https://dev-auth.impulsepower.ru"
    case payment = "https://dev-ipay.impulsepower.ru"
    case socket = "wss://dev-sharing.impulsepower.ru/ws"
    case scooterSoket = "wss://dev-scooter.impulsepower.ru/ws"
    case chargerSoket = "wss://dev-charger.impulsepower.ru/ws"
    case scooter = "http://dev-scooter.impulsepower.ru/"
    case charger = "https://dev-charger.impulsepower.ru/"
    case evCharger = "https://dev-ev-charger.impulsepower.ru/"
    case evChargerSoket = "wss://dev-ev-charger.impulsepower.ru/ws"
}
