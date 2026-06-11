//
//  ScanViewController.swift
//  MimoBike
//
//  Created by Vardan on 09.05.21.
//

import UIKit
import AVFoundation
import CoreLocation
import AudioToolbox

final class ScanViewController: UIViewController, StoryboardInitializable {

    
    //MARK: - Outlets
    
    @IBOutlet weak var qrTextField: MITextFieldView!
    @IBOutlet weak var backgroundShadeView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var cameraPreviewView: UIView!
    @IBOutlet weak var flashLightButton: CircleButton!
    @IBOutlet weak var curtainView: GradientView!
    @IBOutlet weak var scanLineView: UIView!
    @IBOutlet weak var curtainContentView: UIView!
    @IBOutlet weak var transparentView: UIView!
    @IBOutlet weak var sendButton: CircleButton!
    @IBOutlet weak var flashTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var qrBottomMargin: NSLayoutConstraint!
    
    var requestInProgress = false
    var scannedTrip: ((TripActionModel) -> ())?
    var minBalanceVC = DebtInfoViewController()
    
    //MARK: - Variables
    @IBOutlet weak var fieldBottomConstraint: NSLayoutConstraint!
    
    weak var delegate: HomeScanQrSheetViewControllerDelegate?
    
    let locationManager = CLLocationManager()
    var userLocation: CLLocationCoordinate2D?
    
    var qrScanManager: QRScanManager?//!
    
    var homeViewModel = HomeViewModel()
    
    private var loopAnimation: Bool = true
    
    var currentMode = "bike"
    
    weak var testDelegate: TestDelegate?
    
    //MARK: - Life cycles

    override func viewDidLoad() {
        super.viewDidLoad()
        self.qrTextField.text = "MOBILE_scan_bike_code".localized()
        self.locationManager.requestAlwaysAuthorization()
        self.qrTextField.delegate = self
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        DispatchQueue.global(qos: .default).async { [weak self] in
            if CLLocationManager.locationServicesEnabled() {
                self?.locationManager.delegate = self
                self?.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                self?.locationManager.startUpdatingLocation()
            }
        }
        registerKeyboardNotifications()
        configureUI()
        configureTapGesture()
    }
    
    deinit {
        print("deinit - \(String(describing: self))")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        if qrScanManager == nil {
//            qrScanManager = QRScanManager(cameraPreviewView: cameraPreviewView, viewController: self)
//            qrScanManager.delegate = self
//            qrScanManager.startQRScan()
            requestInProgress = false
//        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        qrScanManager?.updateCameraPosition()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.qrScanManager != nil {
            self.qrScanManager?.stopQRScan()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.qrScanManager != nil {
            self.qrScanManager?.stopQRScan()
        }
    }
    //MARK: - Methods

    func configureUI() {
       let currency = "MOBILE_global_total_currency".localized()
        let ridingText = "MOBILE_scan_minute_cos".localized().replacingOccurrences(of: "[num]", with: 9.99.description)
        
        let minimalText = "MOBILE_scan_minimal_fee".localized().replacingOccurrences(of: "[num]", with: 99.9.description)
        
        priceLabel.text = ridingText + minimalText
        priceLabel.text = priceLabel.text?.replacingOccurrences(of: "[currency]", with: currency)
        
        priceLabel.colorString(text: priceLabel.text, coloredText: ["9.99 \(currency)", "99.9 \(currency)"], color: .mimoWhite, font: UIFont(name: "Roboto-Regular", size: 15)!)
        flashLightButton.addShadow(color: .mimoBlackWith05alpha)
        curtainView.backgroundColor = .clear
        curtainView.fill(colorOne: .mimoYellow500, colorTwo: .clear, cornerRadius: 0)
        scanLineView.layer.cornerRadius = 2
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            //already authorized
            qrScanManager = QRScanManager(cameraPreviewView: cameraPreviewView, viewController: self)
            qrScanManager?.delegate = self
            qrScanManager?.startQRScan()
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] (granted: Bool) in
                guard let self = self else { return }
                if granted {
                    //access allowed
                    self.qrScanManager = QRScanManager(cameraPreviewView: self.cameraPreviewView, viewController: self)
                    self.qrScanManager?.delegate = self
                    self.qrScanManager?.startQRScan()
                } else {
                    //access denied
                    self.presentCameraSettings()
                }
            })
        }
        
        sendButton.alpha = 0
        sendButton.isHidden = false

        transparentView.backgroundColor = .clear
        view.setNeedsLayout()
        view.layoutIfNeeded()
        var frameTransparent = scrollView.getConvertedFrame(fromSubview: curtainView)!
        frameTransparent.origin.y += transparentView.frame.origin.y + curtainView.frame.height - 12
        backgroundShadeView.setMask(with: frameTransparent, cornerRadius: 12)
        curtainView.frame.origin.y = -(self.curtainView.frame.height)
        self.scanLineView.frame.origin.y = 0
        repeatStrickeAnimation(isTop: false)
        curtainContentView.layer.cornerRadius = 12
        qrTextField.keyboardType = .numberPad
    }
    
    func presentCameraSettings() {
        let alertController = UIAlertController(title: "Error",
                                      message: "Camera access is denied",
                                      preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default))
        alertController.addAction(UIAlertAction(title: "Settings", style: .cancel) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                    // Handle
                })
            }
        })

        present(alertController, animated: true)
    }
    
    func repeatStrickeAnimation(isTop: Bool) {
        curtainView.animatePositionY(to: isTop ? -(self.curtainView.frame.height / 2) : self.curtainView.frame.height / 2, duration: 1.6)
        self.scanLineView.animatePositionY(to: isTop ?  0 : self.curtainView.frame.height, duration: 1.6) { [weak self] in
            guard let self = self else { return }
            if self.loopAnimation {
                self.repeatStrickeAnimation(isTop: !isTop)
            }
        }
    }
    
    private func configureTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func tapAction(_ tap: UITapGestureRecognizer) {
        qrTextField.resignFirstResponder()
        self.view.endEditing(true)
    }
    
    //MARK: - Actions

    @IBAction func doneButtonTapped(_ sender: UIButton) {
        if self.qrScanManager != nil {
            self.qrScanManager?.stopQRScan()
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func flashLightButtonTapped(_ sender: UIButton) {
//        AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) { }
        VibrateManager.vibrate()
        qrScanManager?.toggleFlash()
    }
 
    @IBAction func sendButtonTapped(_ sender: Any) {
        if qrTextField.fieldText.isEmpty {
            qrTextField.shake()
        } else {
            qrTextField.endTyping()
            if qrTextField.fieldText.hasPrefix("1001") {
                self.metadataOutput(qrTextField.fieldText)
            } else {
                self.metadataOutput("https://testHost.com?\(qrTextField.fieldText)")
            }
            
        }
    }
}

extension ScanViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.count == 0 { return true }
        if qrTextField.fieldText.count >= 10 {
            return false
        } else {
            return true
        }
    }
}

//MARK: - extension QRScanManagerDelegate

extension ScanViewController: QRScanManagerDelegate {
    
    func metadataOutput(_ stringValue: String) {
        var scanedCode = ""
        if let code = URL(string: stringValue)?.query, code.count == 10 {
            self.currentMode = "bike"
            scanedCode = code
        } else if stringValue.hasPrefix("1001") && stringValue.count == 8 {
            self.currentMode = "scooter"
        } else {
            self.showAlertMessage("MOBILE_incorrect_qr".localized(), actionText: "MOBILE_global_ok".localized(), action: {
                self.qrScanManager?.startQRScan()
            })
            return
        }
        guard let userLocation = userLocation else {
            self.showAlertMessage("Incorrect Loccation", actionText: "MOBILE_global_ok".localized(), action: {
                self.qrScanManager?.startQRScan()
            })
            return
        }
        if requestInProgress {
            return
        }
        if Reachability.isConnectedToNetwork() {
            print("Internet Connection Available!")
        } else {
//            let splashVC = NoInternetViewController.initFromStoryboard(name: Constant.Storyboards.splash)
//            setRootViewController(splashVC)
            BaseRouter.shared.showSplashView()
            return
        }
        requestInProgress = true
        MILoader.show()
        
        if currentMode == "bike" {
            UserDefaults.standard.set("bike", forKey: "BikeState")
            self.homeViewModel.scanBike(bookId: scanedCode, location: userLocation) { [weak self] (result) in
                self?.requestInProgress = false
                switch result {
                case .success(let model):
                    QRStore.sharedInstance.qr = scanedCode
                    guard let mac = model.bikeDto?.mac, let bikeID = model.bikeDto?.id else {
                        self?.showAlertMessage("Failed to scan qr", actionText: "Ok", action: {

                        })
                        return
                    }
                    if model.action == .TripScanned || model.action == .TripStarted {
                        BLEManager.shareInstance.scan(for: mac, bikeID: bikeID, workOption: BLEOption(afterConnectOption: BLEOption.AfterConnect(unlockDevice: true, updateDeviceState: false)))
                    }
                    print("=============== Scan QR SUccess =================")
                    self?.scannedTrip?(model)
                    MILoader.hide()
//                    self?.dismiss(animated: true)
                case .failure(let error):
                    MILoader.hide()
                    switch error {
                    case .tooFar(let er):
                    self?.showErrorMinBalanceVC(message: er.localized(), isShowOK: false)
                    case .invalidParse(let er):
                        self?.showErrorMinBalanceVC(message: er.localized())
                    case .validatorError(let er):
                        self?.showErrorMinBalanceVC(message: er.localized())
                    case .responseError(let er):
                        self?.showErrorMinBalanceVC(message: er.localized())
                    case .serverError:
                        self?.showErrorMinBalanceVC(message: "MOBILE_something_wrong".localized())
                    default:
                        self?.showErrorMinBalanceVC(message: error.localizedDescription.localized())
                    }
                    
//                    self?.showAlertMessage("MOBILE__global_attention".localized(), meassage: error.message.localized(), actionText: "OK".localized()) {
//                        self?.qrScanManager.startQRScan()
    //                    self?.loopAnimation = true
    //                    controller.dismiss(animated: true)
//                    }
                }
            }
        } else {
            UserDefaults.standard.set("scooter", forKey: "BikeState")
            
            dismiss(animated: true) { [stringValue, testDelegate] in
                let scooterPlanView = ScooterPlanViewController.initFromStoryboard(name: Constant.Storyboards.scooterPlan)
                scooterPlanView.testDelegate = testDelegate
                scooterPlanView.modalPresentationStyle = .fullScreen
                scooterPlanView.scooterId = stringValue
                UIApplication.topController()?.present(scooterPlanView, animated: true)
            }
        }
        
//        self.loopAnimation = false
    }
    
    func showErrorMinBalanceVC(message: String, isShowOK: Bool = true) {
        minBalanceVC = DebtInfoViewController.initFromStoryboard(name: Constant.Storyboards.scooterPlan)
        minBalanceVC.view.backgroundColor = .white
        minBalanceVC.delegate = self
        minBalanceVC.errorDescription = message
        minBalanceVC.isBike = true
        minBalanceVC.isShowOK  = isShowOK
        self.present(minBalanceVC, animated: true)
    }
}

extension ScanViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        userLocation = locValue
    }
}

extension ScanViewController: DebtInfoViewControllerDelegate {
    func didClose() {
        minBalanceVC.dismiss(animated: true)
        self.openWalletVC()
    }
    
    func openWalletVC() {
        var walletNavigationController: UINavigationController?
        let walletVC = WalletViewController.initFromStoryboard(name: Constant.Storyboards.wallet)
        walletNavigationController = UINavigationController(rootViewController: walletVC)
        walletNavigationController?.navigationBar.barTintColor = .white
        walletNavigationController?.navigationBar.backgroundColor = .white
        
        self.present(walletNavigationController!, animated: true, completion: nil)
    }
}
