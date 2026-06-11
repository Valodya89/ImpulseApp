//
//  NumericTextField.swift
//  MimoBike
//
//  Created by Dose on 6/3/21.
//

import UIKit

final class NumericTextField: UITextField {
    
    @IBInspectable var rightOffset: Int = 0
    @IBInspectable var numberCount: Int = 10
    @IBInspectable var removeOnTyping: String = "0.00"
   
    weak var numDelegate: UITextFieldDelegate?
    
    
    var numberText: Double?  {
        get {
        guard let text = self.text else { return nil }
        guard let numberPart = text.components(separatedBy: " ").first else { return nil }
        return Double(numberPart)
        }
        set {
            self.text = "\(newValue ?? 0.00) ֏"
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        delegate = self
    }
    
}

extension NumericTextField: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        text = text?.replacingOccurrences(of: removeOnTyping, with: "")
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        numDelegate?.textFieldDidChangeSelection?(textField)
        
        let position = textField.endOfDocument
        let cursorPosition = textField.position(from: position, in: .left, offset: rightOffset)!
        if let selectedRange = textField.selectedTextRange {
            let relatedPosition = textField.offset(from: textField.endOfDocument, to: selectedRange.start)
            if relatedPosition >= -rightOffset {
                textField.selectedTextRange = textField.textRange(from: cursorPosition, to: cursorPosition)
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let mutableString = string
        
        let onlyNumericAllowed = CharacterSet(charactersIn: "0123456789").inverted
        
        let componets = mutableString.components(separatedBy: onlyNumericAllowed)
        
        let filtered = componets.joined(separator: "")
        
        guard mutableString == filtered  else { return false }
        
        if range.location >= (textField.text!.count + string.count) - 2 {
            return false
        }
        
        if string == "" {
            return true
        }
        
        if textField.text!.count >= numberCount {
            return false
        }
        
        return numDelegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string) ?? true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        if text?.count == rightOffset, let text = text {
            textField.text = "\(removeOnTyping)" + text
        }

        return numDelegate?.textFieldShouldReturn?(textField) ?? true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        numDelegate?.textFieldDidEndEditing?(textField)
        if text?.count == rightOffset, let text = text {
            textField.text = "\(removeOnTyping)" + text
        }
    }

}
