//
//  TelcellCollectionViewCell.swift
//  MimoBike
//
//  Created by Vardan on 24.05.21.
//

import UIKit
import ContactsUI

enum TelcellState {
    case open
    case close
    case findFromContacts
    case chooseNumber
}

protocol TelcellCollectionViewCellDelegate: AnyObject {
    
    func pickFromContacts(state: TelcellState)
    func didChangeState(_ state: TelcellState, in cell: UICollectionViewCell)
    func didActivate(phone: String)
}

enum TelCellCollectionPhoneState {
    case userPhone(phone: String)
    case contactPhone(phone: String)
    case custom
}

class TelcellCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var radiuButtonView: UIView!
    @IBOutlet weak var contextView: UIView!
    @IBOutlet weak var contextHeightConstant: NSLayoutConstraint!
    @IBOutlet weak var telCellTopConstant: NSLayoutConstraint!
    @IBOutlet weak var radioButton: UIButton!
    @IBOutlet weak var telcellView: UIView!
    @IBOutlet weak var phoneNumberField: MIPhonePicker!
    
    @IBOutlet weak var findContactButton: UIButton!
    @IBOutlet weak var chooseNumberButton: UIButton!
    
    //MARK: - Variables
    
    
    weak var delegate: TelcellCollectionViewCellDelegate?
    
    private var keepSelectedUserPhone: Bool = false
    
    
    var phoneState: TelCellCollectionPhoneState = .custom
    var userPhone: String? {
        didSet {
            chooseNumberButton.setTitle("MOBILE_wallet_current_number".localized().replacingOccurrences(of: "[phone]", with: userPhone ?? ""), for: .normal)
            chooseNumberButton.titleLabel?.adjustsFontSizeToFitWidth = true

        }
    }
    
    //MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.phoneNumberField.selectedCountryCode = "AM"
        configureUI()

    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        phoneNumberField.fixDefaultRegion = true
        chooseNumberButton.gestureRecognizers?.forEach({$0.cancelsTouchesInView  = true })
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

    }
    
    //MARK: - Methods
    
    func configureUI() {
        self.phoneNumberField.phoneTextField.keyboardType = .phonePad
        self.phoneNumberField.didUpdateStatus = { [weak self] _ in
            guard let phoneNumber = self?.phoneNumberField.phoneNumber else {
                return
            }
            
            self?.chooseNumberButton.isSelected = false
            self?.delegate?.didActivate(phone: phoneNumber)
        }
        radioButton.setImage(UIImage(named: "ic_seected_radioButton_image"), for: .selected)
        chooseNumberButton.setImage(UIImage(named: "ic_checkBox_empty"), for: .normal)
        chooseNumberButton.setImage(UIImage(named: "ic_checkBox_filled"), for: .selected)
        telcellView.isUserInteractionEnabled = true 
        telcellView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(radioButtonTapped)))
    }
    
    func changeCell(state: TelcellState, animatable: Bool = false) {
        delegate?.didChangeState(state, in: self)
        self.telCellTopConstant.constant = state == .open ? 21 : bounds.midY - radiuButtonView.bounds.height / 2
        animationClosure(animatable: animatable, duration: 0.3, delay: 0.0, animationOption: .curveEaseInOut) {
            self.phoneNumberField.alpha = state == .open ? 1 : 0
            self.findContactButton.alpha = state == .open ? 1 : 0
            self.chooseNumberButton.alpha = state == .open ? 1 : 0
            self.telcellView.transform = state == .open ? CGAffineTransform(scaleX: 0.3, y: 0.3) : .identity
            self.layoutIfNeeded()
            self.setNeedsLayout()
        } completion: { _ in
            
        }
    }
    
    func changePhoneState(_ newState: TelCellCollectionPhoneState) {
        phoneState = newState
        switch newState {
        case .contactPhone(let phone):
            chooseNumberButton.isSelected = false
            phoneNumberField.phoneNumber = phone
            delegate?.didActivate(phone: phone)

        case .custom:
            
            chooseNumberButton.isSelected = false
            phoneNumberField.phoneNumber = ""
        
        case .userPhone(let phone):
            delegate?.didActivate(phone: phone)
            chooseNumberButton.isSelected = true
            phoneNumberField.phoneNumber = phone
        }
        
    }
    
    @IBAction func radioButtonTapped(_ sender: Any) {
        
        radioButton.isSelected.toggle()
        if radioButton.isSelected {
            changeCell(state: .open, animatable: true)
        } else {
            changeCell(state: .close, animatable: true)
        }
        self.layoutIfNeeded()
    }
    
    
    
    @IBAction func findFromContactsTapped(_ sender: UIButton) {
        delegate?.pickFromContacts(state: .chooseNumber)
    }
    
    @IBAction func chooseUserPhoneTapped(_ sender: Any) {
        guard let userPhone = userPhone else { return }
        if case .userPhone = phoneState {
            changePhoneState(.custom)
        } else {
            changePhoneState(.userPhone(phone: userPhone))
        }
    }
}
