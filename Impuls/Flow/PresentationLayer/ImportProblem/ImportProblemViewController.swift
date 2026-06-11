//
//  ImportProblemViewController.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/16/21.
//

import UIKit

final class ImportProblemViewController: UIViewController, StoryboardInitializable {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var qrImageField: ImageField!
    @IBOutlet weak var attachImageField: ImageField!
    @IBOutlet weak var descriptionField: UITextView!
    
    let textViewPlaceHolder = "Description"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.text = textViewPlaceHolder
        textView.textContainerInset.left = 15
        textView.textColor = UIColor.lightGray
        start()
    }
    
    /// Responsible for set observer to keyboard actions
    func start() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    // MARK: - Keyboard Selectors -
    
    /// Action when keyboard hides
    @objc private func keyboardWillHide(notification: Notification) {
        self.scrollView.contentInset = .zero
        self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset
    }
    
    /// Action when keyboard shows
    @objc private func keyboardWasShown(notification: Notification) {
        /// Than
        let userInfo = notification.userInfo
        
        /// Get keyboard size
        guard let keyboardSize = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            /// Failed
            debugPrint("Can not get keyboard size")
            
            return
        }
        
        
        guard let textFieldFrame = textView.superview?.convert(textView.frame, to: nil) else { return }
        self.scrollView.contentInset.bottom = keyboardSize.height
        self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset
        
        self.scrollView.scrollRectToVisible(textFieldFrame, animated: true)
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func hideKeyboardTapped(_ sender: Any) {
        self.textView.endEditing(true)
    }
}

extension ImportProblemViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = textViewPlaceHolder
            textView.textColor = UIColor.lightGray
        }
    }
}
