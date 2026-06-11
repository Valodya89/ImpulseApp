//
//  BluetoothManager.swift
//  MimoBike
//
//  Created by Dose on 6/26/21.
//

import UIKit
import CoreBluetooth
import CommonCrypto

enum BleDeviceState {
    case locked
    case unLocked
    case connectionLost
}

protocol BLEManagerDelegate: AnyObject {
    func changeBleState(bleState: BleDeviceState)
}

struct BLEOption {
    
    struct AfterConnect {
        var unlockDevice: Bool = true
        var updateDeviceState: Bool = false
    }
    
    var afterConnectOption: AfterConnect
}

final class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate {
    
    
    weak var delegate: BLEManagerDelegate?
    var bluetoothPeripheralManager: CBPeripheralManager?

    fileprivate var timeToStart = 0
    var centralManager: CBCentralManager!
    fileprivate var lockDevice: CBPeripheral!
    fileprivate var bleNotifier: CBCharacteristic!
    fileprivate var bleReader: CBCharacteristic!
    fileprivate var bleWriter: CBCharacteristic!
    fileprivate var bleDescriptor: CBDescriptor!
    fileprivate var bleIsOn = false
    private var didUpdateBLEState: (()->())?
    
    fileprivate var ridenBikeId = ""
    fileprivate let SERVICE_UUID = CBUUID(string: "0000FEE7-0000-1000-8000-00805F9B34FB")
    fileprivate let WRITE_UUID = CBUUID(string: "000036f5-0000-1000-8000-00805f9b34fb")
    fileprivate let READ_UUID = CBUUID(string: "000036f6-0000-1000-8000-00805f9b34fb")
    fileprivate let NOTIFY_UUID = CBUUID(string: "0000feff-0000-1000-8000-00805f9b34fb")
    fileprivate let DESCRIPTOR_UUID = CBUUID(string: "00002902-0000-1000-8000-00805f9b34fb")
    fileprivate var BLE_TOKEN: Array<UInt8> = [239,191,189,42,32,239,191,189,239,191,189,53,239,191,189,39,94,239,191,189,239,191,189,115,239,191,189]
    fileprivate var BLE_KEY: Array<UInt8> = [32, 87, 47, 82, 54, 75, 63, 71, 48, 80, 65, 88, 17, 99, 45, 43]
    fileprivate var unlockCountDown = 30
    fileprivate var bleOpened = false
    
    private var option: BLEOption? = nil
    
    private var accessToken: Data? = nil
    
    private var didUnlockDevice: (()->())?
    private var didLockDevice: (()->())?
    var checkBluetoothConnectionState: ((_ state: CBManagerState)->())?
    static let shareInstance = BLEManager()
    
    var deviceMacAddress = ""
    var bikeID: String = ""
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.centralManager.delegate = self
        configBLE()
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        self.checkBluetoothConnectionState?(peripheral.state)
    }
    
    ///    BLE METHODS
    
    func configBLE() {
        let options = [CBCentralManagerOptionShowPowerAlertKey:0] //<-this is the magic bit!
        bluetoothPeripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: options)
    }
    
    func scan(for mac: String, bikeID: String, workOption: BLEOption? = nil) {
        self.option = workOption
        if bleIsOn {
            didUpdateBLEState = nil
            self.deviceMacAddress = mac
            self.bikeID = bikeID
            centralManager?.scanForPeripherals (
                withServices: [SERVICE_UUID], options: [
                    CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber(value: true as Bool)
                ]
            )
            print("========== BLE Scan Bike ================")
        } else {
            didUpdateBLEState = {[weak self] in
                guard let self = self else { return }
                self.scan(for: mac, bikeID: bikeID, workOption: workOption)
            }
        }
    }
    
    func dinsconnect() {
        self.deviceMacAddress = ""
        guard let device = lockDevice else { return }
        self.centralManager.cancelPeripheralConnection(device)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.bleIsOn = true
        } else {
            self.bleIsOn = false
            self.delegate?.changeBleState(bleState: .connectionLost)
        }
    }
    // TODO: Step 1
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == "KKSLOCK" {
            if let advData = advertisementData["kCBAdvDataManufacturerData"] as? NSData {
                let advDataString = advData.description
                
                guard let bytesRange = advDataString.range(of: "bytes = ") else { return }
                
                let upperBound = advDataString.index(bytesRange.upperBound, offsetBy: 6)
                let macAddress = String(advDataString[upperBound...].dropLast())
                
                let macAddressWithDots = macAddress.split(by: 2).joined(separator: ":").uppercased()
                if macAddressWithDots == deviceMacAddress {
                    self.lockDevice = peripheral
                    if peripheral.state == .disconnected {
                        peripheral.delegate = self
                        self.centralManager.stopScan()
                        peripheral.discoverServices([SERVICE_UUID])
                        self.centralManager.connect(peripheral, options: nil)
                    }
                }
            }
        }
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([SERVICE_UUID])
    }
    
    // TODO: step 2 connected and did discovered state
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error == nil {
            if let services = peripheral.services {
                for service in services {
                    if service.uuid == self.SERVICE_UUID {
                        peripheral.discoverCharacteristics(nil, for: service)
                        let _ = peripheral.state.rawValue
                        
                    }
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error == nil {
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    //
                    if characteristic.uuid == self.WRITE_UUID {
                        self.bleWriter = characteristic
                        peripheral.setNotifyValue(true, for: characteristic)
                        peripheral.discoverDescriptors(for: characteristic)
                        
                    }
                    if characteristic.uuid == self.READ_UUID {
                        self.bleReader = characteristic
                        peripheral.setNotifyValue(true, for: characteristic)
                        peripheral.discoverDescriptors(for: characteristic)
                    }
                    if characteristic.uuid == self.NOTIFY_UUID {
                        self.bleNotifier = characteristic
                        peripheral.setNotifyValue(true, for: characteristic)
                        peripheral.discoverDescriptors(for: characteristic)
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.getAccessToken(data: Data([0x06, 0x01, 0x01,0x01,0x2D,0x1A,0x68,0x3D,0x48,0x27,0x1A,0x18,0x31,0x6E,0x47,0x1A]))
                }
            }
        }
    }
    
    var obt = true
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        //peripheral.setNotifyValue(true, for: characteristic)
        print("didUpdateNotificationStateFor = ",error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("didDiscoverDescriptorsFor = ",error)
        if error == nil {
            if let descriptors = characteristic.descriptors {
                for descriptor in descriptors {
                    if descriptor.uuid == self.DESCRIPTOR_UUID {
                        self.bleDescriptor = descriptor
                        peripheral.setNotifyValue(true, for: characteristic)
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let recvData = characteristic.value?.aesEncrypt(keyData: Data(bytes: self.BLE_KEY), operation: kCCDecrypt)
        
        if let incomeDataBytes = recvData?.bytes {
            let accessTokenIndeify: [UInt8] = [0x06, 0x02, 0x07]
            if incomeDataBytes.hex[0...2].values == accessTokenIndeify {
                self.accessToken = Data(incomeDataBytes.hex[3...6].values)
                
                if let option = option {
                    if option.afterConnectOption.unlockDevice {
                        unlockDevice()
                    }
                    
                    if option.afterConnectOption.updateDeviceState {
                        getDeviceInfo()
                    }
                }
                
                return
            }
            let startPattern = incomeDataBytes[..<3]
//            if startPattern == [5 ,15, 1] || startPattern == [5,2,1] {
                let status = incomeDataBytes[3]
                if status == 0x00 {
                print("--->>>>>> OPENED")
                    
                    delegate?.changeBleState(bleState: .unLocked)
                    self.didUnlockDevice?()
                    SessionNetwork().request(with: URLBuilder(from: AuthAPI.updateBikeLock(state: false, bikeID: bikeID)), {
                        response in
                    })
                } else {
                    self.didLockDevice?()
                    print("--->>>>>> CLOSED")
                    delegate?.changeBleState(bleState: .locked)
                    SessionNetwork().request(with: URLBuilder(from: AuthAPI.updateBikeLock(state: true, bikeID: bikeID)), {
                        response in
                    })
                    centralManager.cancelPeripheralConnection(lockDevice)
                }
//            }
        }
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("AAAAAA")
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) { }
    
    fileprivate func writeToBle(dataToWrite: Data) {
        if self.lockDevice != nil && self.bleWriter != nil && self.lockDevice.state == .connected {
            self.lockDevice.writeValue(dataToWrite, for: self.bleWriter, type: .withResponse)
        }
    }
    
    //     BLE COMMANDS
    
    func unlockDevice(incomeDataBytes: [UInt8], completion: (()->())?) {
        let accessToken = [incomeDataBytes[3], incomeDataBytes[4], incomeDataBytes[5], incomeDataBytes[6]]
        let lockStatus: Array<UInt8> = [0x05, 0x01, 0x06, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, accessToken[0], accessToken[1], accessToken[2], accessToken[3], 0x00, 0x00, 0x00]
        self.didLockDevice = completion
        if let encCom = Data(bytes: lockStatus).aesEncrypt(keyData: Data(bytes: self.BLE_KEY), operation: kCCEncrypt) {
            self.writeToBle(dataToWrite: encCom)
        }
    }
    
    func unlockDevice() {
        guard let accessToken = accessToken else { return }
        let data = Data([0x05, 0x01, 0x06] + [0x30, 0x30, 0x30,0x30,0x30,0x30] + accessToken + [0x00,0x00,0x00])
        if let encCom = Data(data).aesEncrypt(keyData: Data(self.BLE_KEY), operation: kCCEncrypt) {
            self.writeToBle(dataToWrite: encCom)
        }
    }
    
    func getDeviceInfo() {
        guard let accessToken = accessToken else { return }
        let data = Data([0x05, 0x0E, 0x01, 0x01] + accessToken + [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        
        if let encCom = Data(data).aesEncrypt(keyData: Data(self.BLE_KEY), operation: kCCEncrypt) {
            self.writeToBle(dataToWrite: encCom)
        }
    }
    
    func getDeviceInfo(incomeDataBytes: [UInt8]) {
        let accessToken = [incomeDataBytes[3], incomeDataBytes[4], incomeDataBytes[5], incomeDataBytes[6]]
        let lockStatus: Array<UInt8> = [5, 14, 1, 1,accessToken[0], accessToken[1], accessToken[2], accessToken[3],0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        
        if let encCom = Data(bytes: lockStatus).aesEncrypt(keyData: Data(bytes: self.BLE_KEY), operation: kCCEncrypt) {
            self.writeToBle(dataToWrite: encCom)
        }
    }
    
    func getAccessToken(data: Data) {
        if let encCom = Data(bytes: data).aesEncrypt(keyData: Data(bytes: self.BLE_KEY), operation: kCCEncrypt) {
            self.writeToBle(dataToWrite: encCom)
        }
    }
    
}


extension String {
    func split(by length: Int) -> [String] {
        var startIndex = self.startIndex
        var results = [Substring]()
        
        while startIndex < self.endIndex {
            let endIndex = self.index(startIndex, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            results.append(self[startIndex..<endIndex])
            startIndex = endIndex
        }
        
        return results.map { String($0) }
    }
}
