//
//  ScanViewController+Keyboard.swift
//  MimoBike
//
//  Created by Vardan on 27.05.21.
//

import UIKit

// MARK: - HomeViewController extension

extension ScanViewController {
    
    ///Register for keyboard willHide willShow notifiication
    func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ScanViewController.keyboardNotification(notification:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc func keyboardNotification(notification: NSNotification) {
        
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
            let animationCurve: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
            
            if (endFrame?.origin.y)! >= UIScreen.main.bounds.size.height {
                //close keyboard
                self.qrBottomMargin.constant = 40
                self.fieldBottomConstraint.constant = -40
                self.flashTopConstraint.constant = 40
                self.sendButton.alpha = 0
                
            } else {
                //open keyboar
                let height: CGFloat = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)!.size.height
                self.qrBottomMargin.constant = 5
                self.fieldBottomConstraint.constant = height + 5
                self.flashTopConstraint.constant = -140
                self.sendButton.alpha = 1
                self.scrollView.scrollToBottom(animated: true)
            }
            
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
    
//    @objc func keyboardWillShow(notification: NSNotification) {
//        let userInfo: NSDictionary = notification.userInfo! as NSDictionary
//        let keyboardInfo = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
//        let keyboardSize = keyboardInfo.cgRectValue.size
//        self.fieldBottomConstraint.constant = keyboardSize.height + 50
//        self.flashBottomConstraint.constant = keyboardSize.height + 60
//
//         UIView.animate(withDuration: 0.3) {
//            self.view.layoutIfNeeded()
//            self.sendButton.alpha = 1
//            self.scrollView.scrollToBottom(animated: true)
//
//        }
//    }
//
//    @objc func keyboardWillHide(notification: NSNotification) {
//        self.fieldBottomConstraint.constant = -40
//        self.flashBottomConstraint.constant = 10
//        UIView.animate(withDuration: 0.3) {
//            self.view.layoutIfNeeded()
//            self.sendButton.alpha = 0
//        }
//
//    }
}
