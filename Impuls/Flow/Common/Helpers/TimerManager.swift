//
//  TimerManager.swift
//  MimoBike
//
//  Created by Vardan on 11.05.21.
//

import UIKit

enum TimerState {
    case increment
    case decrement
}

protocol TimerManagerDelegate: AnyObject {
    func didExpireDuration(timer: TimerManager)
    func didChanchTimeSeconds(seconds: Double)
}

class TimerManager {
    
    private weak var timerLabel: UILabel?
    var timer: Timer? = Timer()
    private var initialDuration: TimeInterval = 300.0
    var duration: TimeInterval = 300.0
    private let formatter = DateComponentsFormatter()
    var formattedDuration = ""
    var timerState: TimerState = .increment
    var timerPredicateText = ""
    var labelFont = UIFont(name: "Roboto-Bold", size: 18)!
    var timerDurationColor = UIColor.mimoBlack
    weak var delegate: TimerManagerDelegate?
    
    init(timerLabel: UILabel, duration: TimeInterval, formaterUnits: NSCalendar.Unit, timerState: TimerState) {
        self.timerLabel = timerLabel
        self.initialDuration = duration
        self.duration = duration
        self.timerState = timerState
        
        // Use the appropriate positioning for the current locale
        formatter.unitsStyle = .positional
        // Units to display in the formatted string
        formatter.allowedUnits = formaterUnits
        // Pad with zeroes where appropriate for the locale
        formatter.zeroFormattingBehavior = [ .pad ]
    }
    
    /// start timer
    func startTimer() {
        duration = initialDuration
        formattedDuration = formatter.string(from: initialDuration) ?? ""
        print("formattedDuration = \(formattedDuration)")
        print("timerPredicateText = \(timerPredicateText)")
        timerLabel?.colorString(text: "\(timerPredicateText)", coloredText: ["\(formattedDuration )"], color: timerDurationColor, font: labelFont)
        
        let seconds = 1.0
//        timer = Timer.scheduledTimer(timeInterval: seconds, target:self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
        timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: true, block: { [weak self] _ in
            self?.updateCounter()
        })
        timer?.fire()
    }
    
//    func  isStartedd() -> Bool {
//        return timer?.
//    }
    /// stop timer
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func pauseTimer() {
        timer?.invalidate()
    }

    func continueTimer() {
        let seconds = 1.0
        if timer == nil {
//            timer = Timer.scheduledTimer(timeInterval: seconds, target:self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
            timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: true, block: { [weak self] _ in
                self?.updateCounter()
            })
        }
        timer?.fire()
    }
    /// timer selector function
    @objc  func updateCounter() {

        formattedDuration = formatter.string(from: duration) ?? ""
        
        if duration > 0 || timerState == .increment {
            
            switch timerState {
            case .increment:
                duration += 1
            case .decrement:
                duration -= 1
            }
            delegate?.didChanchTimeSeconds(seconds: duration)
            timerLabel?.colorString(text: "\(timerPredicateText)\(formattedDuration)", coloredText: ["\(formattedDuration)"], color: timerDurationColor, font: labelFont)
        } else {
            if duration <= 0 && timerState != .increment {
                delegate?.didExpireDuration(timer: self)
                stopTimer()
            }
        }
    }
}
