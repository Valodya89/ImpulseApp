//
//  CodeEmailViewController.swift
//  MimoBike
//
//  Created by Dose on 6/12/21.
//

import UIKit


final class CodeEmailViewController: UIViewController, StoryboardInitializable {
    
    //MARK: - Outlets
    
    @IBOutlet weak var codeTextField: MimoOneTimeCodeTextField!
    @IBOutlet weak var verifyButtonContentView: UIView!
    @IBOutlet weak var userPhoneNumberLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var requestAgainCodeButton: UIButton!
    @IBOutlet weak var requestAgainContentView: UIView!
    @IBOutlet weak var requestAgainLabel: UILabel!
    @IBOutlet weak var bottomContentViewBottomConstraint: NSLayoutConstraint!
    
    
    //MARK: - Variables

    private let authViewModel = VerifyEmailViewModel()
    private var timer = Timer()
    private var counter = 59
    private var tapGesture = UITapGestureRecognizer()
    private var code = ""
    var emailLabel = ""
     
    
    //MARK: - Life cycles

    override func viewDidLoad() {
        super.viewDidLoad()

        registerKeyboardNotifications()
        configureUI()
        startTimer()
    }
    
    
    //MARK: - Methods

    /// configure user interface
    private func configureUI() {
        configureOneTimeCodeTextField()
        configVerifyButton(enable: false)
        verifyButtonContentView.layer.cornerRadius = Constant.CornerRadius.cornerRadius24
        bottomContentViewBottomConstraint.constant = Constant.Constraint.constant37
        
        userPhoneNumberLabel.colorString(text: "MOBILE_sign_in_phone_number_which_received_code".localized().replacingOccurrences(of: "[phone num]", with: emailLabel), coloredText: ["\(emailLabel)"], color: .mimoBlackWith05alpha, font: UIFont(name: "Roboto-Regular", size: 17)!)
        
        timerLabel.colorString(text: "You will receive the code in 0:59", coloredText: ["0:59"], color: .mimoRed500, font: UIFont(name: "Roboto-Light", size: 15)!)
        
        requestAgainLabel.underLineText(texts: ["MOBILE_sign_in_request_again".localized()])
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyBoard))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    /// configure code text field
    private func configureOneTimeCodeTextField() {
        
        codeTextField.defaultCaracterValue = ""
        codeTextField.oneTimeDelegate = self
        codeTextField.isConfigured = false
        codeTextField.configure(with: 6)
        codeTextField.didEnterLastDigit = { [weak self] code in
            guard let self = self else { return }
            self.code = code
            if code.count == 6 {
                self.configVerifyButton(enable: true)
                self.view.endEditing(true)
            } else {
                self.configVerifyButton(enable: false)
            }
        }
    }
    
    /// start timer
    private func startTimer(){
        requestAgainButtonUserInteraction(enable: false)
        counter = 59
        let seconds = 1.0
        timer = Timer.scheduledTimer(timeInterval: seconds, target:self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }
    
    /// stop timer
    func stopTimer() {
        timer.invalidate()
        requestAgainButtonUserInteraction(enable: true)
    }
    
    /// timer selector function
    @objc private func updateCounter() {
        
        if counter > 0 {
            counter -= 1
            
            if counter < 10 {
                timerLabel.colorString(text: "MOBILE_sign_in_SMS_time".localized().replacingOccurrences(of: "[time]", with: "0:0\(counter)"), coloredText: ["0:0\(counter)"], color: .mimoRed500, font: UIFont(name: "Roboto-Light", size: 15)!)
            } else {
                timerLabel.colorString(text: "MOBILE_sign_in_SMS_time".localized().replacingOccurrences(of: "[time]", with: "0:\(counter)"), coloredText: ["0:\(counter)"], color: .mimoRed500, font: UIFont(name: "Roboto-Light", size: 15)!)
            }
        } else {
          
            if counter == 0 {
                stopTimer()
            }
        }
    }
    
    /// enable or desable requset again button user iteraction
    /// when timer is start or stop
    private func requestAgainButtonUserInteraction(enable: Bool) {
        requestAgainContentView.isHidden = !enable
        requestAgainCodeButton.isUserInteractionEnabled = enable
    }
    
    /// Configure verify button user interaction and color
    private func configVerifyButton(enable: Bool) {
        verifyButtonContentView.backgroundColor = enable ? .mimoYellow500 : .mimoBlackWith01alpha
        verifyButtonContentView.isUserInteractionEnabled = enable
    }
    
    /// tap gesture recognizer selector function view end editing
    @objc private func hideKeyBoard () {
        
        //aded this line for testing is valid phone code
        codeTextField.isValidCode = !codeTextField.isValidCode
        view.endEditing(true)
    }
    
    /// navigate to onboarding screen
    private func goToOnboardingVC() {
        stopTimer()
        let onboardingVC = OnboardingViewController.initFromStoryboard(name: Constant.Storyboards.signIn)
        navigationController?.pushViewController(onboardingVC, animated: true)
    }
    
    private func goToHomeVC() {
        let homeVC = HomeViewController.initFromStoryboard(name: Constant.Storyboards.home)
        homeVC.state = .accountDone
        let navVC = UINavigationController(rootViewController: homeVC)
        setRootViewController(navVC)
    }
    
    /// Verify device with phone number and code
    private func verifyDevice() {
      
        
    }
    
    /// Resend verification code to phone number
    private func resendVerificationCode() {
        
    }
    
    
    // MARK: - IBActions
    
    /// back button tapped
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    /// request code again
    @IBAction func requestCodeAgainTapped(_ sender: UIButton) {
        resendVerificationCode()
    }
    
    /// verify phone code tapped
    @IBAction func verifyTapped(_ sender: UIButton) {
        verifyDevice()
    }
}


// MARK: - MimoOneTimeCode TextField Delegate

extension CodeEmailViewController: MimoOneTimeCodeTextFieldDelegate {
    func didChangeChar() {
        
    }
}


// MARK: - Keyboard

extension CodeEmailViewController {
    ///Register for keyboard willHide willShow notifiication
    func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(notification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(notification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        let userInfo: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardInfo = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
        let keyboardSize = keyboardInfo.cgRectValue.size
        bottomContentViewBottomConstraint.constant = keyboardSize.height + Constant.Height.height15
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        bottomContentViewBottomConstraint.constant = Constant.Height.height37
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}
