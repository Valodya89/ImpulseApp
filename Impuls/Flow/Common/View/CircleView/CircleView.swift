//
//  CircleView.swift
//  MimoBike
//
//  Created by Dose on 5/9/21.
//

import UIKit

class CircleView: UIView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(frame.width, frame.height) / 2
    }
}

class CircleButton: UILocalizedButton {

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(frame.width, frame.height) / 2
    }
}

class CircleImageView: UIImageView {

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(frame.width, frame.height) / 2
    }
}
