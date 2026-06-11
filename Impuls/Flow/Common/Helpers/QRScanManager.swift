//
//  QRScanManager.swift
//  MimoBike
//
//  Created by Vardan on 10.05.21.
//

import UIKit
import AVFoundation

protocol QRScanManagerDelegate: AnyObject {
    func metadataOutput(_ stringValue: String)
}

final class QRScanManager: NSObject {
    
    private var cameraPreviewView: UIView!
    private weak var viewController: UIViewController?
    public var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    var metadataOutput: AVCaptureMetadataOutput? = AVCaptureMetadataOutput()
    var videoInput: AVCaptureDeviceInput?
    
    weak var delegate: QRScanManagerDelegate?
    
    var isCapturedQR = false
    
    init(cameraPreviewView: UIView, viewController: UIViewController?) {
        self.cameraPreviewView = cameraPreviewView
        self.viewController = viewController
    }
    
    deinit {
        print("deinit - \(String(describing: self))")
        stopQRScan()
    }
    
    func startQRScan() {
        isCapturedQR = false
        configSession()
        configMetaDataOutput()
        setPreviewLayer()
        DispatchQueue.global(qos: .default).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    func stopQRScan() {
        isCapturedQR = true
        captureSession?.stopRunning()
        captureSession = nil
        metadataOutput = nil
        videoInput = nil
    }
    
    private func configSession() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if ((captureSession?.canAddInput(videoInput!)) != nil) {
                captureSession?.addInput(videoInput!)
            } else {
                failed()
                return
            }
        } catch {
            return
        }
    }
    
    private func configMetaDataOutput() {
        metadataOutput = AVCaptureMetadataOutput()
        if metadataOutput == nil {
            failed()
            return
        }
        
        if ((captureSession?.canAddOutput(metadataOutput!)) != nil) {
            captureSession?.addOutput(metadataOutput!)
            
            metadataOutput!.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput!.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
    }
    
    private func setPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession ?? AVCaptureSession())
        previewLayer.videoGravity = .resizeAspectFill
        cameraPreviewView.layer.addSublayer(previewLayer)
        
        previewLayer.frame = cameraPreviewView.layer.bounds
    }

    func updateCameraPosition() {
        previewLayer.frame = cameraPreviewView.layer.bounds

    }
    
    private func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        viewController?.present(ac, animated: true)
        captureSession = nil
    }
    
    func toggleFlash() {
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
}

extension QRScanManager: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
//        captureSession.stopRunning()
        guard !isCapturedQR else { return }
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            isCapturedQR = true
            delegate?.metadataOutput(stringValue)
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
}
