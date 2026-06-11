//
//  Configuration.swift
//  MimoBike
//
//  Created by Andrey Lupin on 01.02.26.
//

import KeychainAccess

public class Config {
    static let bundleIdentifier = "com.mimo.MimoBike"
    public let keychain = Keychain(service: bundleIdentifier)
    let bundle = Bundle(for: Config.self)
}
