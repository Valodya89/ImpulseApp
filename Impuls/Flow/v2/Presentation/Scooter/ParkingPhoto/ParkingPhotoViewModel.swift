//
//  ParkingPhotoViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 23.05.24.
//

import AVFoundation
import SwiftUI
import os.log
import Combine

final class ParkingPhotoViewModel: MimoBaseViewModel, ObservableObject {
    
    private var BAG = Set<AnyCancellable>()
    
    private let worker: ParkingPhotoWorkerProtocol
    private let tripId: String
    
    let camera = Camera()
    
    @Published var viewfinderImage: Image?
    @Published var isRunning: Bool = true
    @Published var isFlashOn: Bool = false
    @Published var isAuthorized: Bool = false
    var finishData: CurrentValueSubject<TripScooterDataModel?, Never> = .init(nil)
    
    private var uiImage: UIImage?
    
    init(worker: ParkingPhotoWorkerProtocol, tripId: String) {
        self.worker = worker
        self.tripId = tripId
        super.init()
        
        Task {
            await camera.start()
        }
        
        Task {
            await handleCameraPreviews()
        }
        
        Task {
            let authorized = await camera.checkAuthorization()
            self.isAuthorized = authorized
        }
    }
    
    func handleCameraPreviews() async {
        for await image in camera.previewStream {
            Task { @MainActor in
                DispatchQueue.main.async {
                    self.viewfinderImage = image.image
                    self.uiImage = image.uiImage
                }
            }
        }
    }
    
    func start() {
        Task {
            await camera.start()
            isRunning = true
        }
    }
    
    func stop() {
        camera.stop()
        isRunning = false
    }
    
    func switchFlashLight() {
        camera.switchTorch()
        isFlashOn = camera.torchMode == .on
    }
    
    func finishTrip() {
        guard let image = uiImage else { return }
        worker.finishTrip(id: tripId, image: image)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.mimoError = error
                }
            } receiveValue: { [weak self] _ in
                self?.checkFinish()
            }
            .store(in: &BAG)
    }
    
    func checkFinish() {
        self.worker.getTrip(id: self.tripId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    if error.message == "SCOOTER_active_trip_not_exists" {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self?.checkFinish()
                        }
                    } else {
                        self?.mimoError = error
                    }
                }
            } receiveValue: { [weak self] tripData in
                self?.finishData.send(tripData)
            }
            .store(in: &BAG)
    }
}

fileprivate extension CIImage {
    var image: Image? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: self.extent) else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
    
    var uiImage: UIImage? {
        return UIImage(ciImage: self, scale: 1, orientation: .up)
    }
}

fileprivate extension Image.Orientation {

    init(_ cgImageOrientation: CGImagePropertyOrientation) {
        switch cgImageOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}

fileprivate let logger = Logger(subsystem: "com.apple.swiftplaygroundscontent.capturingphotos", category: "DataModel")
