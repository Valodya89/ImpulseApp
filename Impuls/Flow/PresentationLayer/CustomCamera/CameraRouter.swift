//
//  CameraRouter.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 05.06.23.
//

import Foundation
import SwiftUI

class CameraRouter {
    
    public static let shared = CameraRouter()
    
    private let storyboard = UIStoryboard(name: Constant.Storyboards.parkingPhotoCamera, bundle: nil)
    
    private init() {}
    
    func showParkingPhotoCameraViewController(_ viewController: UIViewController?, trip: ScooterStateModel) {
        guard let tripID = trip.data?.id else { return }
        let parkingPhotoVC = UIHostingController(rootView: ParkingPhotoView(viewModel: ParkingPhotoViewModel(worker: Resolver.resolve(), tripId: tripID)))
        viewController?.present(parkingPhotoVC, animated: true)
    }
}
