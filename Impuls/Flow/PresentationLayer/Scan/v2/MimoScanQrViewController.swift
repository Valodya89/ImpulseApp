//
//  MimoScanQrViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 01.06.23.
//

import UIKit
import AVFoundation
import MercariQRScanner

protocol MimoScanQrViewControllerDelegate: AnyObject {
    func didFinishScan(with value: String, type: MimoType)
}

class MimoScanQrViewController: MimoBaseViewController {
    
    @IBOutlet private weak var qrTextField: MITextFieldView!
    
    @IBOutlet private weak var flashButton: UIButton!
    @IBOutlet private weak var doneButton: UIBarButtonItem!
    
    @IBOutlet private weak var qrTextFieldBottomConstraint: NSLayoutConstraint!
    
    var mimoType: MimoType?
    weak var delegate: MimoScanQrViewControllerDelegate?
    
    private var qrScannerView: QRScannerView?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardNotification(notification:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if qrScannerView == nil {
            if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
                self.setupQRScanner()
            } else {
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    guard let self else { return }
                    DispatchQueue.main.async {
                        if granted {
                            self.setupQRScanner()
                        } else {
                            self.showCameraAccessAlert()
                        }
                    }
                }
            }
        }
    }
    
    private func setupQRScanner() {
        guard qrScannerView == nil else { return }
        self.qrScannerView = QRScannerView(frame: self.view.bounds)
        self.qrScannerView?.configure(delegate: self, input: .init(isBlurEffectEnabled: true))
        self.qrScannerView?.startRunning()
        self.view.addSubview(self.qrScannerView!)
        self.view.sendSubviewToBack(self.qrScannerView!)
    }
    
    private func setupUI() {
        doneButton.possibleTitles = ["MOBILE_global_done".localized()]
        doneButton.title = "MOBILE_global_done".localized()
        qrTextField.text = "MOBILE_scan_bike_code".localized()
        qrTextField.delegate = self
        qrTextField.keyboardType = .numberPad
        qrTextField.textField.addDoneButtonOnKeyboard()
    }
}

// MARK: - Actions
extension MimoScanQrViewController {
    
    @IBAction private func flashAction() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }

        do {
            try device.lockForConfiguration()

            if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                device.torchMode = AVCaptureDevice.TorchMode.off
            } else {
                do {
                    try device.setTorchModeOn(level: 1.0)
                } catch {
                    print(error)
                }
            }
            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    @IBAction private func doneAction() {
        self.dismiss(animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension MimoScanQrViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.count == 0 { return true }
        if qrTextField.fieldText.count >= 10 {
            return false
        } else {
            return true
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        if qrTextField.fieldText.isEmpty {
            qrTextField.shake()
        } else {
            qrTextField.endTyping()
            var value = qrTextField.fieldText
            if !value.hasPrefix("1001") && !value.hasPrefix("200") {
                value = "https://testHost.com?\(value)"
            }
            
            qrScannerView(qrScannerView!, didSuccess: value)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
}

// MARK: - Keyboard Notification
extension MimoScanQrViewController {
    
    @objc func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
            let animationCurve: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
            
            if (endFrame?.origin.y)! >= UIScreen.main.bounds.size.height {
                qrTextFieldBottomConstraint.constant = 18
                flashButton.isHidden = false
                
            } else {
                //open keyboar
                let height: CGFloat = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)!.size.height
                qrTextFieldBottomConstraint.constant = height - 20
                flashButton.isHidden = true
            }
            
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
}

extension MimoScanQrViewController: QRScannerViewDelegate {
    func qrScannerView(_ qrScannerView: QRScannerView, didFailure error: QRScannerError) {
        showAlertMessage("Scanning not supported", meassage: error.localizedDescription)
    }
    
    func qrScannerView(_ qrScannerView: QRScannerView, didSuccess code: String) {        
        let scooterQrValidator = Validator(data: code)
                                    .isValidScooterCode()
                                    .validate()
        
        let chargerQrValidator = Validator(data: code)
                                    .isValidChargerCode()
                                    .validate()
        let evChargerQrValidator = Validator(data: code)
                                    .isValidEVChargerCode()
                                    .validate()
        
        let bikeQrValidator = Validator(data: code)
                                .isValidBikeCode()
                                .validate()
        
        if scooterQrValidator.isValid {
            mimoType = .scooter
        } else if chargerQrValidator.isValid {
            mimoType = .charger
        } else if bikeQrValidator.isValid {
            mimoType = .bike
        } else if evChargerQrValidator.isValid {
            mimoType = .evCharger
        }
        
        if mimoType == .scooter {
            UserDefaults.standard.set("scooter", forKey: "BikeState")
        } else if mimoType == .charger {
            //
        } else if mimoType == .evCharger {
            //
        } else if mimoType == .bike {
            UserDefaults.standard.set("bike", forKey: "BikeState")
        } else {
            self.showAlertMessage("MOBILE_incorrect_qr".localized(), actionText: "MOBILE_global_ok".localized(), action: {
                qrScannerView.rescan()
            })
            
            return
        }
        
        self.dismiss(animated: true) { [code, mimoType, delegate] in
            var val: String
            switch mimoType {
            case .scooter:
                val = code
            case .bike:
                val = URL(string: code)?.query ?? ""
            case .charger:
                val = URL(string: code)?.lastPathComponent ?? ""
            case .evCharger:
                val = URL(string: code)?.lastPathComponent ?? ""
            case nil:
                val = ""
            }
            delegate?.didFinishScan(with: val, type: mimoType ?? .scooter)
        }
    }
}
