//
//  PhonePicker.swift
//  MimoBike
//
//  Created by Dose on 5/9/21.
//

import UIKit
import SwiftMaskTextfield

final class PhonePickerView: UIView {
    
    private var countryImage: UIImage = UIImage()
    private var countryCode: String = "+374"
    private var phoneCode: String = ""
    
    @IBOutlet weak var countryCodeButton: UIButton!
    @IBOutlet weak var phoneTextField: SwiftMaskTextfield!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        loadFromNib()
        
    }
    
    func getPhoneNumber() -> String {
        
        return countryCode
    }
}
