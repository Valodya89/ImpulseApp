//
//  MimoOneTimeCodeTextField.swift
//  MimoBike
//
//  Created by Vardan on 21.04.21.
//

import UIKit

protocol MimoOneTimeCodeTextFieldDelegate: AnyObject {
    func didChangeChar()
}

class MimoOneTimeCodeTextField: UITextField {

    var didEnterLastDigit: ((String) -> ())?
    var defaultCaracterValue = "-"
    weak var oneTimeDelegate: MimoOneTimeCodeTextFieldDelegate?
    
    var isConfigured = false
    var digitLabels = [UILabel]()
    var isValidCode = false {
        didSet {
            colorAllLabelsBorederToRed(isInValid: !isValidCode)
        }
    }
    
    private lazy var tapRecognizer: UITapGestureRecognizer = {
       let recognizer = UITapGestureRecognizer()
        recognizer.addTarget(self, action: #selector(becomeFirstResponder))
        return recognizer
    }()
    
    func configure(with slotCount: Int = 6) {
        guard isConfigured == false else { return }
        isConfigured.toggle()
        configureTextField()
        
        let lebelsStackView = createLabelsStackView(with: slotCount)
        addSubview(lebelsStackView)
        
        addGestureRecognizer(tapRecognizer)
        
        NSLayoutConstraint.activate([
            lebelsStackView.topAnchor.constraint(equalTo: topAnchor),
            lebelsStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            lebelsStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            lebelsStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func configureTextField() {
        tintColor = .clear
        textColor = .clear
        keyboardType = .numberPad
        textContentType = .oneTimeCode
        
        addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        delegate = self
    }
    
    private func createLabelsStackView(with count: Int) -> UIStackView {
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        digitLabels = []
        for _ in 1...count {
            
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.font = UIFont(name: "Roboto-Regular", size: 24)
            label.textColor = UIColor(named: "mimoBlack")
            label.text = defaultCaracterValue
            label.isUserInteractionEnabled = true
            label.backgroundColor = .mimoWhite
            label.layer.borderWidth = 0.5
            label.layer.borderColor = UIColor.mimoBlackWith025alpha.cgColor
            label.layer.cornerRadius = Constant.CornerRadius.cornerRadius8
            label.layer.masksToBounds = true
            
            stackView.addArrangedSubview(label)
            digitLabels.append(label)
        }
        
        return stackView
    }
    
    @objc func textDidChange() {
        guard let text = self.text, text.count <= digitLabels.count else { return }
        
        for i in 0 ..< digitLabels.count {
            let currentLabel = digitLabels[i]

            if i < text.count {
                let index = text.index(text.startIndex, offsetBy: i)
                currentLabel.text = String(text[index])
                currentLabel.textColor = .black

            } else {
                currentLabel.textColor =  UIColor(named: "mimoBlack")
                currentLabel.text = defaultCaracterValue
            }
            
            // checkk is current label in text field cnd cgange only it border color
            if i == text.count - 1 {
                currentLabel.layer.borderColor = UIColor.mimoAmber500.cgColor
                currentLabel.layer.borderWidth = 1
            } else {
                currentLabel.layer.borderColor = UIColor.mimoBlackWith025alpha.cgColor
                currentLabel.layer.borderWidth = 0.5
            }

        }
        
        didEnterLastDigit?(text)
    }
    
    private func colorAllLabelsBorederToRed(isInValid: Bool) {
        guard let text = self.text, text.count <= digitLabels.count else { return }
        
        for i in 0 ..< digitLabels.count {
            let currentLabel = digitLabels[i]
            currentLabel.layer.borderWidth = isInValid ? 1 : 0.5
            currentLabel.layer.borderColor = isInValid ? UIColor.mimoRed500.cgColor : UIColor.mimoBlackWith025alpha.cgColor
            
            if !isInValid {
                currentLabel.layer.borderWidth = i == text.count - 1 ? 1 : 0.5
                currentLabel.layer.borderColor = i ==  text.count - 1 ? UIColor.mimoAmber500.cgColor : UIColor.mimoBlackWith025alpha.cgColor
            }
        }
    }
}
extension MimoOneTimeCodeTextField: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        self.oneTimeDelegate?.didChangeChar()
        guard let characterCount = textField.text?.count else { return false }
        
        
        return characterCount < digitLabels.count || string == ""
        
    }
}
