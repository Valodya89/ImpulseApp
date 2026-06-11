//
//  VibrateEffectManager.swift
//  MimoBike
//
//  Created by Andrey Lupin on 07.03.26.
//

import Foundation
import AudioToolbox

class VibrateEffectManager {
    static let shared = VibrateEffectManager()
    
    
    func errorVibration() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
        
        vibrate()
    }
    
    func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}
