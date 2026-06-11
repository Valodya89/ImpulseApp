//
//  CryptoCommon.swift
//  MimoBike
//
//  Created by Dose on 6/26/21.
//

import Foundation
import CommonCrypto

extension Data {
    func hexString() -> String {
        return self.reduce("") { string, byte in
            string + String(format: "%02X", byte)
        }
    }
    var bytes: [UInt8] {
        return [UInt8](self)
    }
    func aesEncrypt(keyData: Data, operation: Int) -> Data? {
        let dataLength = self.count
        let cryptLength  = size_t(dataLength + kCCBlockSizeAES128)
        var cryptData = Data(count: cryptLength)
        let keyLength = size_t(kCCKeySizeAES128)
        //let options = CCOptions(kCCOptionPKCS7Padding)
        let options = CCOptions(kCCOptionECBMode)
        var numBytesEncrypted: size_t = 0
        let cryptStatus = cryptData.withUnsafeMutableBytes ({ cryptBytes in
            self.withUnsafeBytes { dataBytes in
                keyData.withUnsafeBytes { keyBytes in
                    CCCrypt(CCOperation(operation),
                            CCAlgorithm(kCCAlgorithmAES),
                            options,
                            keyBytes, keyLength,
                            nil,
                            dataBytes, dataLength,
                            cryptBytes, cryptLength,
                            &numBytesEncrypted)
                }
            }
        })
        if UInt32(cryptStatus) == UInt32(kCCSuccess) {
            cryptData.removeSubrange(numBytesEncrypted..<cryptData.count)
            return cryptData
        }
        return nil
    }
}
