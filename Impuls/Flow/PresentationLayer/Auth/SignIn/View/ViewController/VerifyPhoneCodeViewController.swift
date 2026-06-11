//
//  VerifyPhoneCodeViewController.swift
//  MimoBike
//
//  Created by Vardan on 21.04.21.
//

import UIKit

final class VerifyPhoneCodeViewController: BaseViewController, StoryboardInitializable {

    
    //MARK: - Outlets
    
    @IBOutlet weak var codeTextField: MimoOneTimeCodeTextField!
    @IBOutlet weak var verifyButtonContentView: UIView!
    @IBOutlet weak var userPhoneNumberLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var requestAgainCodeButton: UIButton!
    @IBOutlet weak var requestAgainContentView: UIView!
    @IBOutlet weak var requestAgainLabel: UILabel!
    @IBOutlet weak var bottomContentViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var attantionText: UILocalizedLabel!
    
    
    //MARK: - Variables

    private let authViewModel = AuthViewModel()
    private var timer = Timer()
    private var counter = 59
    private var tapGesture = UITapGestureRecognizer()
    private var code = ""
    var phoneNumber = ""
     
    
    //MARK: - Life cycles

    override func viewDidLoad() {
        super.viewDidLoad()
//        var callObserver = CXCallObserver()
//        callObserver.setDelegate(self, queue: nil)
        self.attantionText.text = "MOBILE_fill_last_four_digit".localized()+" +7 (***) ***-12-34"
        
//        let provider = CXProvider(configuration: CXProviderConfiguration(localizedName: "My App"))
//                provider.setDelegate(self, queue: nil)
//                let update = CXCallUpdate()
//                update.remoteHandle = CXHandle(type: .generic, value: "Mama")
//                provider.reportNewIncomingCall(with: UUID(), update: update, completion: { error in
//                    print(error)
//                })
        
        registerKeyboardNotifications()
        configureUI()
        startTimer()
    }
    
    /// configure user interface
    private func configureUI() {
        configureOneTimeCodeTextField()
        configVerifyButton(enable: false)
        verifyButtonContentView.layer.cornerRadius = Constant.CornerRadius.cornerRadius24
        bottomContentViewBottomConstraint.constant = Constant.Constraint.constant37
        
        userPhoneNumberLabel.colorString(text: "MOBILE_sign_in_phone_number_which_received_code".localized().replacingOccurrences(of: "[phone num]", with: phoneNumber), coloredText: ["\(phoneNumber)"], color: .mimoBlackWith05alpha, font: UIFont(name: "Roboto-Regular", size: 17)!)
        timerLabel.colorString(text: "MOBILE_sign_in_SMS_time".localized().replacingOccurrences(of: "[time]", with: "0:59"), coloredText: ["0:59"], color: .mimoRed500, font: UIFont(name: "Roboto-Light", size: 15)!)
        
        requestAgainLabel.underLineText(texts: ["MOBILE_sign_in_request_again".localized()])
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyBoard))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    /// configure code text field
    private func configureOneTimeCodeTextField() {
        
        codeTextField.defaultCaracterValue = ""
        codeTextField.oneTimeDelegate = self
        codeTextField.isConfigured = false
        codeTextField.configure(with: 4)
        codeTextField.didEnterLastDigit = { [weak self] code in
            guard let self = self else { return }
            self.code = code
            if code.count == 4 {
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
//        UserDefaults.standard.setValue(false, forKey: "isAlreadyOpen")
//        UserDefaults.standard.setValue(false, forKey: "isAlreadyOpenPaymentTutorial")
        let onboardingVC = OnboardingViewController.initFromStoryboard(name: Constant.Storyboards.signIn)
        navigationController?.pushViewController(onboardingVC, animated: true)
    }
    
    private func goToHomeVC() {
//        let homeVC = HomeViewController.initFromStoryboard(name: Constant.Storyboards.home)
//        homeVC.state = .accountDone
////        UserDefaults.standard.setValue(false, forKey: "isAlreadyOpen")
////        UserDefaults.standard.setValue(false, forKey: "isAlreadyOpenPaymentTutorial")
//        let navVC = UINavigationController(rootViewController: homeVC)
//        goToNextVC(navVC)
        
//        HomeRouter.shared.showHomeViewController()
    }
    
    /// Verify device with phone number and code
    private func verifyDevice() {
        MILoader.show()
        authViewModel.verifyDevice(phoneNumber: phoneNumber, code: code) { [weak self] result in
            guard let self = self else { return }
            MILoader.hide()
            switch result {
            
            case .success(let isAccountComplete):
                if isAccountComplete {
                    self.goToHomeVC()
                } else {
                    self.goToOnboardingVC()
                }
            case .failure(let error):
                print(error)
                switch error {
                case .unknown(let description):
                    UIAlertController.showError(message: description.localized())
                case .serverError:
                    UIAlertController.showError(message: "Server Error")
                case .invalidPhoneValidatinoCode:
                    UIAlertController.showError(message: "ACCOUNTS_wrong_verification_code".localized())
                }
                
            }
        }
    }
    
    /// Resend verification code to phone number
    private func resendVerificationCode() {
        MILoader.show()
        authViewModel.signIn(phoneNumber: phoneNumber) { [weak self] result in
            MILoader.hide()
            guard let self = self else { return }
            switch result {
            case .success:
                self.codeTextField.text = ""
                self.code = ""
                self.configVerifyButton(enable: false)
                self.requestAgainButtonUserInteraction(enable: false)
                self.startTimer()
            case .failure(let error):
                print(error)
                UIAlertController.showError(message: error.localizedDescription)
            }
        }
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

extension VerifyPhoneCodeViewController: MimoOneTimeCodeTextFieldDelegate {
    func didChangeChar() {
        
    }
}


// MARK: - Keyboard

extension VerifyPhoneCodeViewController {
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
