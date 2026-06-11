//
//  VibrateManager.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 23.08.22.
//

import UIKit

class VibrateManager: NSObject {

    class func vibrate() {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
    }
}
