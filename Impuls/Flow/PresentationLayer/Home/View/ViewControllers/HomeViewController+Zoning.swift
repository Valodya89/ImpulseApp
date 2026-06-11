//
//  HomeViewController+Zoning.swift
//  MimoBike
//
//  Created by Dose on 7/14/21.
//

import UIKit

extension HomeViewController {
    func getZone() {
        if trip != nil {
            return
        }
        if bookedDevice != nil {
            return
        }
        MALocation.current.didReceiveLocationOnce = { location in
            guard let currentLocation = location else { return }
            ApplicationSettings.shared.getZoning(coordinates: currentLocation) { model in
                guard let model = model, !model.isEmpty else {
                    return
                }
                ZoningView.show(with: 10)
                self.mapView.drawCyrcle(zoningModels: model)
            }
        }
    }
}
