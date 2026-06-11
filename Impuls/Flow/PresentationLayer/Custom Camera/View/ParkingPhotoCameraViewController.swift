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
    
    //MARK: - Variables
//    @IBOutlet weak var fieldBottomConstraint: NSLayoutConstraint!
    
    let captureSession = AVCaptureSession()
    let stillImageOutput = AVCaptureStillImageOutput()
    var error: NSError?
    
    let locationManager = CLLocationManager()
    var userLocation: CLLocationCoordinate2D?
    
    var qrScanManager: QRScanManager!
    
    var homeViewModel = HomeViewModel()
    
    private var loopAnimation: Bool = true
    
    //MARK: - Life cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        configureUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        qrScanManager?.updateCameraPosition()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.qrScanManager.stopQRScan()
    }
    //MARK: - Methods
    
    func configureUI() {

        retakeBgViwe.layer.cornerRadius = retakeBgViwe.frame.size.height / 2
        sendBgView.layer.cornerRadius = sendBgView.frame.size.height / 2
        
        let devices = AVCaptureDevice.devices().filter{ $0.hasMediaType(AVMediaType.video) && $0.position == AVCaptureDevice.Position.back }
                if let captureDevice = devices.first as? AVCaptureDevice  {

                    try? captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
                    captureSession.sessionPreset = AVCaptureSession.Preset.photo
                    captureSession.startRunning()
                    stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
                    if captureSession.canAddOutput(stillImageOutput) {
                        captureSession.addOutput(stillImageOutput)
                    } 
                    let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                        previewLayer.bounds = cameraPreviewView.bounds
                        previewLayer.position = CGPoint(x: cameraPreviewView.bounds.midX, y: cameraPreviewView.bounds.midY)
                        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                
                    cameraPreviewView.layer.addSublayer(previewLayer)
//                    takePhotoButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action:"saveToCamera:"))
                    
                }

        blureView.setMask(with: curtainContentView.frame, cornerRadius: 12)
        curtainContentView.layer.cornerRadius = 12
    }
    
    func saveToCamera(sender: UITapGestureRecognizer) {
        if let videoConnection = stillImageOutput.connection(with: AVMediaType.video) {
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection) {
                    (imageDataSampleBuffer, error) -> Void in
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
        if let videoConnection = stillImageOutput.connection(with: AVMediaType.video) {
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection) {
                    (imageDataSampleBuffer, error) -> Void in
                if let imageDataSampleBuffer = imageDataSampleBuffer {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    if let imageData = imageData, let photo = UIImage(data: imageData) {
                        self.previeewImage.image = photo
//                        UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil)
                    }
                }
              
                
                }
            }
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
    
    @IBAction func sendPhoto(_ sender: UIButton) {
        
    }
}

//MARK: - extension QRScanManagerDelegate

extension ParkingPhotoCameraViewController: QRScanManagerDelegate {
    
    func metadataOutput(_ stringValue: String) {
        guard let userLocation = userLocation,
              let code = URL(string: stringValue)?.query else {
            self.showAlertMessage("Incorrect scan qr", actionText: "Ok", action: {
                self.qrScanManager.startQRScan()
            })
            return
        }
        if requestInProgress {
            return
        }
        if Reachability.isConnectedToNetwork() {
            print("Internet Connection Available!")
        } else {
            let splashVC = NoInternetViewController.initFromStoryboard(name: Constant.Storyboards.splash)
            setRootViewController(splashVC)
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
                self?.showAlertMessage("MOBILE_global_attention".localized(), meassage: error.message.localized(), actionText: "OK".localized()) {
                    self?.qrScanManager.startQRScan()
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
