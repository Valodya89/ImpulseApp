//
//  ParkingPhotoCameraViewController.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 18.07.22.
//

import UIKit
import AVFoundation
import CoreLocation

final class ParkingPhotoCameraViewController: UIViewController, StoryboardInitializable {
    @IBOutlet weak var blureView: UIVisualEffectView!
    
    @IBOutlet weak var takePhotoView: UIView!
    @IBOutlet weak var sendPhotoView: UIView!
    //MARK: - Outlets
    @IBOutlet weak var cameraPreviewView: UIView!
    @IBOutlet weak var curtainContentView: UIView!
    @IBOutlet weak var previeewImage: UIImageView!
    @IBOutlet weak var takePhotoButton: UIButton!
    
    @IBOutlet weak var retakeBgViwe: UIView!
    @IBOutlet weak var sendBgView: UIView!
    var requestInProgress = false
    var scannedTrip: ((TripActionModel) -> ())?
    
    var scoterSoket = ScooterSocketService.shared
    var trip: ScooterStateModel?
    var tripIdForFinish = ""
    
    //MARK: - Variables
//    @IBOutlet weak var fieldBottomConstraint: NSLayoutConstraint!
    
    let captureSession = AVCaptureSession()
    let stillImageOutput = AVCaptureStillImageOutput()
    var error: NSError?
    
    let locationManager = CLLocationManager()
    var userLocation: CLLocationCoordinate2D?
    
    var qrScanManager: QRScanManager?
    
    var homeViewModel = HomeViewModel()
    
    private var loopAnimation: Bool = true
    
//    lazy var homeViewController: HomeViewController = {
//        let homeVC = HomeViewController.initFromStoryboard(name: Constant.Storyboards.home)
//        homeVC.state = .smallBottomSheet
//        return homeVC
//    }()
    
    //MARK: - Life cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        
        DispatchQueue.global(qos: .default).async { [weak self] in
            if CLLocationManager.locationServicesEnabled() {
                self?.locationManager.delegate = self
                self?.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                self?.locationManager.startUpdatingLocation()
            }
            DispatchQueue.main.sync {
                self?.configureUI()
            }
        }
    }
    
    deinit {
        print("deinit - \(String(describing: self))")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        blureView.setMask(with: curtainContentView.frame, cornerRadius: 12)
        curtainContentView.layer.cornerRadius = 12
        retakeBgViwe.layer.cornerRadius = retakeBgViwe.frame.size.height / 2
        sendBgView.layer.cornerRadius = sendBgView.frame.size.height / 2
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        qrScanManager?.updateCameraPosition()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.qrScanManager?.stopQRScan()
    }
    //MARK: - Methods
    
    func configureUI() {

        retakeBgViwe.layer.cornerRadius = retakeBgViwe.frame.size.height / 2
        sendBgView.layer.cornerRadius = sendBgView.frame.size.height / 2
        
        let devices = AVCaptureDevice.devices().filter{ $0.hasMediaType(AVMediaType.video) && $0.position == AVCaptureDevice.Position.back }
        
        DispatchQueue.global(qos: .default).async { [weak self] in
            if let captureDevice = devices.first as? AVCaptureDevice  {
                
                try? self?.captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
                self?.captureSession.sessionPreset = AVCaptureSession.Preset.photo
                
                self?.captureSession.startRunning()
                self?.stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecType.jpeg]
                if ((self?.captureSession.canAddOutput(self?.stillImageOutput ?? AVCaptureStillImageOutput())) != nil) {
                    self?.captureSession.addOutput(self?.stillImageOutput ?? AVCaptureStillImageOutput())
                }
                DispatchQueue.main.sync {
                    let previewLayer = AVCaptureVideoPreviewLayer(session: self?.captureSession ?? AVCaptureSession())
                    previewLayer.bounds = self?.cameraPreviewView.bounds ?? .zero
                    previewLayer.position = CGPoint(x: self?.cameraPreviewView.bounds.midX ?? 0, y: self?.cameraPreviewView.bounds.midY ?? 0)
                    previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    
                    self?.cameraPreviewView.layer.addSublayer(previewLayer)
                    //                    takePhotoButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action:"saveToCamera:"))
                    
                }
            }
        }

        blureView.setMask(with: curtainContentView.frame, cornerRadius: 12)
        curtainContentView.layer.cornerRadius = 12
    }
    
    func saveToCamera(sender: UITapGestureRecognizer) {
        if let videoConnection = stillImageOutput.connection(with: AVMediaType.video) {
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection) { (imageDataSampleBuffer, error) -> Void in
                if let imageDataSampleBuffer = imageDataSampleBuffer {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    if let imageData = imageData, let photo = UIImage(data: imageData) {
                        UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil)
                    }
                }
            }
        }
    }
    
    //MARK: - Actions
    
    @IBAction func takePhoto(_ sender: UIButton) {
        self.sendPhotoView.isHidden = false
        self.takePhotoView.isHidden = true
        self.previeewImage.isHidden = false
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            //already authorized
            if let videoConnection = stillImageOutput.connection(with: AVMediaType.video) {
                stillImageOutput.captureStillImageAsynchronously(from: videoConnection) { [weak self] (imageDataSampleBuffer, error) -> Void in
                    guard let self else { return }
                    if let imageDataSampleBuffer = imageDataSampleBuffer {
                        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                        if let imageData = imageData, let photo = UIImage(data: imageData) {
                            self.previeewImage.image = photo
                            self.sendPhotoView.isHidden = false
                            self.takePhotoView.isHidden = true
                            self.previeewImage.isHidden = false
                            //                        UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil)
                        }
                    }   
                }
            }
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] (granted: Bool) in
                guard let self else { return }
                if granted {
                    //access allowed
                    if let videoConnection = self.stillImageOutput.connection(with: AVMediaType.video) {
                        self.stillImageOutput.captureStillImageAsynchronously(from: videoConnection) { [weak self] (imageDataSampleBuffer, error) -> Void in
                            guard let self else { return }
                            
                            if let imageDataSampleBuffer = imageDataSampleBuffer {
                                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                                if let imageData = imageData, let photo = UIImage(data: imageData) {
                                    self.previeewImage.image = photo
                                    self.sendPhotoView.isHidden = false
                                    self.takePhotoView.isHidden = true
                                    self.previeewImage.isHidden = false
                                    //                        UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil)
                                }
                            }
                        }
                    }
                } else {
                    //access denied
                    DispatchQueue.main.async {
                        self.presentCameraSettings()                        
                    }
                }
            })
        }
        

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

        self.present(alertController, animated: true)
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction func flashLightButtonTapped(_ sender: UIButton) {
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
    
    @IBAction func retakePhoto(_ sender: UIButton) {
        self.sendPhotoView.isHidden = true
        self.previeewImage.isHidden = true
        self.takePhotoView.isHidden = false
    }
    
    func checkIfReceiveTripEnd() {
        print("==== CHECK FINISHS ===== self.tripIdForFinish = \(self.tripIdForFinish)")
        self.homeViewModel.getTripBy(tripId: self.tripIdForFinish) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let trip):
                MILoader.hide()
                
                self.dismiss(animated: true) { [trip] in
                    let vc = ThanksForTheRideViewController.initFromStoryboard(name: Constant.Storyboards.scooterPlan)
                    vc.modalPresentationStyle = .fullScreen
                    
                    let model = TripScooterSocketDataModel(
                        state: nil,
                        scooter: nil,
                        data: SocketData(
                            billingModeTariff: nil,
                            end: trip.start,
                            endMileage: trip.endMileage,
                            endPosition: nil,
                            id: trip.id,
                            pauses: trip.pauses,
                            scan: trip.scan,
                            speedModeTariff: nil,
                            start: trip.start,
                            startMileage: trip.startMileage,
                            startPosition: nil,
                            user: trip.user,
                            distance: ((trip.endMileage ?? 0) - (trip.startMileage ?? 0)),
                            amount: trip.payment?.amount
                        )
                    )
                    
                    vc.tripEndData = model
                    vc.view.backgroundColor = .white
                    vc.updateUI(data: model)
                    UIApplication.topController()?.present(vc, animated: true)
                }
            case .failure(let err):
                if MimoError(error: err).message == "SCOOTER_active_trip_not_exists" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.checkIfReceiveTripEnd()
                    }
                }
            }
        }
    }
    
    @IBAction func sendPhoto(_ sender: UIButton) {
        
//        guard DrawPolygone.shared.isContain(coordinate: locationManager.location!.coordinate) else {
//            print("in location")
//            self.showErrorAlertMessage("SCOOTER_out_of_zone".localized())
//            return
//        }
        
        if let selectedImage = previeewImage.image {
            let sesson = SessionNetwork()
            MILoader.show()
            
            print("==== FINISHS ===== self.tripIdForFinish = \(self.tripIdForFinish)")
            let sendSelectedImage = selectedImage.resizeImage(targetSize: CGSize(width: selectedImage.size.width / 7, height: selectedImage.size.height / 7))
            sesson.request(with: URLBuilder(from: ImageUploadAPI.finish(tripId: self.tripIdForFinish, image: sendSelectedImage))) { [weak self] res in
                guard let self else { return }
                switch res {
                case .success(let data):
                    
                    print("image upload data = \(data)")

                    guard let scooter = MimoConverter<BaseResponseModel<ScooterScanResponse>>.parseJson(data: data as Any) else {
                        return
                    }
                    if scooter.statusCode != 200 {
                        MILoader.hide()
                        UIAlertController.showError(message: scooter.message.localized())
                    } else {
                        self.checkIfReceiveTripEnd()
                    }
                case .failure(let error):
                    MILoader.hide()
                    print(error.localizedDescription)
                }
            }
        } else {
            
        }
    }
}

//MARK: - extension QRScanManagerDelegate

extension ParkingPhotoCameraViewController: QRScanManagerDelegate {
    
    func metadataOutput(_ stringValue: String) {
        guard let userLocation = userLocation,
              let code = URL(string: stringValue)?.query else {
            self.showAlertMessage("Incorrect scan qr", actionText: "Ok", action: {
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
            BaseRouter.shared.showSplashView()
            return
        }
        requestInProgress = true
        MILoader.show()
        
        self.homeViewModel.scanBike(bookId: code, location: userLocation) { [weak self] (result) in
            self?.requestInProgress = false
            switch result {
            case .success(let model):
                QRStore.sharedInstance.qr = code
                guard let mac = model.bikeDto?.mac, let bikeID = model.bikeDto?.id else {
                    self?.showAlertMessage("Failed to scan qr", actionText: "Ok", action: {
                        
                    })
                    return
                }
                if model.action == .TripScanned || model.action == .TripStarted {
                    BLEManager.shareInstance.scan(for: mac, bikeID: bikeID, workOption: BLEOption(afterConnectOption: BLEOption.AfterConnect(unlockDevice: true, updateDeviceState: false)))
                }
                self?.scannedTrip?(model)
            case .failure(let error):
                MILoader.hide()
                self?.showAlertMessage("MOBILE__global_attention".localized(), meassage: error.localizedDescription.localized(), actionText: "OK".localized()) {
                    self?.qrScanManager?.startQRScan()
                }
            }
        }
    }
}

extension ParkingPhotoCameraViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        userLocation = locValue
    }
}

extension Double {
    func toInt() -> Int {
        Int(self)
    }
}
