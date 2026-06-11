//
//  AccountHintView.swift
//  MimoBike
//
//  Created by Dose on 6/13/21.
//

import UIKit
import SwiftUI

protocol AccountHintViewDelegate: AnyObject {
    func closeHint()
}

class AccountHintView: UIViewController, StoryboardInitializable {
    
    @IBOutlet weak var circleVieew: CircleView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBOutlet weak var textLabel: UILocalizedLabel!
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var circleTopConstraint: NSLayoutConstraint!
    
    weak var delegate: AccountHintViewDelegate?
    
    override func viewDidLoad() {
        
    }
    
    @IBAction func closeHintActioon(_ sender: UIButton) {
        guard let delegate = delegate else { return }
        delegate.closeHint()
    }
}
