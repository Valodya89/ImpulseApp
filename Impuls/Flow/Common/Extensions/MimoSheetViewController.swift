//
//  SheetViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 21.05.23.
//

import Foundation

extension SheetViewController {
    
    func setupMimoConfigs() {
        allowPullingPastMaxHeight = false
        allowPullingPastMinHeight = false
        allowGestureThroughOverlay = false
        dismissOnPull = false
        dismissOnOverlayTap = false
        gripSize = .init(width: 38, height: 4)
        gripColor = .mimoBlackWith025alpha
        overlayColor = UIColor.alwaysBlack.withAlphaComponent(0.25)
        view.addShadow(color: UIColor.alwaysBlack.withAlphaComponent(0.25))
    }
}
