//
//  MimoQrScanManager.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 01.06.23.
//

import Foundation
import AVFoundation

protocol MimoQrScanManagerDelegate: AnyObject {
    func didFinishScan(with value: String)
    func didFailWith(with error: String)
    func accessChanged(granted: Bool)
}

final class MimoQrScanManager: NSObject {
    
    private let ERROR_MESSAGE: String = "Your device does not support scanning a code from an item. Please use a device with a camera."
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private var metadataOutput: AVCaptureMetadataOutput?
    private var videoInput: AVCaptureDeviceInput?
    
    private var hasCameraAccess: Bool = false {
        didSet {
            delegate?.accessChanged(granted: hasCameraAccess)
        }
    }
    
    weak var delegate: MimoQrScanManagerDelegate? {
        didSet {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.hasCameraAccess = granted
                }
            }
        }
    }
    
    func startScanning(_ preview: UIView) {
        guard hasCameraAccess else { return }
        
        configSession()
        configMetaDataOutput()
        setPreviewLayer(preview)
        
        DispatchQueue.global().async {
            self.captureSession?.startRunning()
        }
    }
    
    func stopScanning() {
        captureSession?.stopRunning()
        captureSession = nil
        metadataOutput = nil
        videoInput = nil
        previewLayer = nil
    }
    
    func updatePreview(frame: CGRect) {
        previewLayer?.frame = frame
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
    
    private func configSession() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if ((captureSession?.canAddInput(videoInput!)) != nil) {
                captureSession?.addInput(videoInput!)
            } else {
                delegate?.didFailWith(with: ERROR_MESSAGE)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func configMetaDataOutput() {
        metadataOutput = AVCaptureMetadataOutput()
        guard let metadataOutput, let captureSession else { delegate?.didFailWith(with: ERROR_MESSAGE); return }
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            delegate?.didFailWith(with: ERROR_MESSAGE)
        }
    }
    
    private func setPreviewLayer(_ previewView: UIView) {
        guard let captureSession else { return }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        guard let previewLayer else { return }
        
        previewLayer.videoGravity = .resizeAspectFill
        previewView.layer.addSublayer(previewLayer)
        
        previewLayer.frame = previewView.layer.bounds
    }
}

extension MimoQrScanManager: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            delegate?.didFinishScan(with: stringValue)
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
}
