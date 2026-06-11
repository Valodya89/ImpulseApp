//
//  SignInViewController.swift
//  MimoBike
//
//  Created by Vardan on 21.04.21.
//

import UIKit
import SwiftMaskTextfield
import CoreLocation

final class SignInViewController: BaseViewController, StoryboardInitializable, UIGestureRecognizerDelegate, CLLocationManagerDelegate {

    
    //MARK: - Outlets
    
    @IBOutlet weak var phoneNumber: MIPhonePicker!
    @IBOutlet weak var termsButton: UIButton!
    @IBOutlet weak var termsTextView: UITextView!
    @IBOutlet weak var nextButton: ActionButton!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var agreementTextView: UITextView!
    @IBOutlet weak var agrementButton: UIButton!
    
    @IBOutlet weak var noteView: UIView!
    @IBOutlet weak var noteLbl: UILabel!
    
    @IBOutlet weak var bottomContentViewBottomConstraint: NSLayoutConstraint!
    
    
    //MARK: - Variables
    
    private let authViewModel = AuthViewModel()
    private let splashViewModel = SplashViewModel()
    
    private var termsURL: URL!
    private var privacyURL: URL!
    
    let locationManager = CLLocationManager()
    let geoCoder = CLGeocoder()
    
    //MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestAlwaysAuthorization()
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.delegate = self
                self.locationManager.startMonitoringSignificantLocationChanges()
            }
        }
        configureUI()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.first else { return }
        
        geoCoder.reverseGeocodeLocation(currentLocation) { (placemarks, error) in
            guard let currentLocPlacemark = placemarks?.first else { return }
            print(currentLocPlacemark.country ?? "No country found")
            print(currentLocPlacemark.isoCountryCode ?? "No country code found")
            self.phoneNumber.selectedCountryCode = currentLocPlacemark.isoCountryCode ?? "AM"
        }
    }
    
    //MARK: - Methods
    
    /// configure user interface
    private func configureUI() {
        
        noteView.layer.cornerRadius = 8
        welcomeLabel.text = "MOBILE_global_welcome_title".localized().replacingOccurrences(of: "MimoBike", with: "")
        
        noteLbl.text = "MOBILE_login_agreement_transferred_to_child".localized() + "\n\n" + "MOBILE_login_agreement_riding_more_than_one".localized() + "\n\n" + "MOBILE_login_agreement_scooter_transfer_to_others".localized() + "\n\n" +  "MOBILE_login_agreement_respect_other_road_users".localized()
        // add gesture on view to hide with tap keyboard
        let tapGestureHideKeyboard =  UITapGestureRecognizer(target: self, action: #selector(hideKeyBoard))
        view.addGestureRecognizer(tapGestureHideKeyboard)
        configTermsPrivacy()
        phoneNumber.phoneTextField.keyboardType = .numberPad
        phoneNumber.didUpdateStatus = {[weak self] _ in
            self?.updateNextButton()
        }
    }
    
    override func viewDidLayoutSubviews() {
        noteView.layer.cornerRadius = 8
    }
    
    private func configTermsPrivacy() {
        
        let _ = "MOBILE_profile_privacy_and_policy".localized()
        let _ = "Terms".localized()
//        var text = "I agree to [terms] and [privacy policy]".localized()
//
//        text = text.replacingOccurrences(of: "[terms]", with: terms)
//        text = text.replacingOccurrences(of: "[privacy policy]", with: privacy)
        
        termsButton.setImage(UIImage(named: "ic_checkBox_filled"), for: .selected)
        termsButton.setImage(UIImage(named: "ic_checkBox_empty"), for: .normal)
        agrementButton.setImage(UIImage(named: "ic_checkBox_filled"), for: .selected)
        agrementButton.setImage(UIImage(named: "ic_checkBox_empty"), for: .normal)

        termsTextView.text = "MOBILE_agree_Mimo_Privacy_Policy".localized()
        agreementTextView.text = "MOBILE_agree_Mimo_Agreement ".localized()

        
//        guard let termsRange = termsTextView.text.range(of: terms) else {
////            assertionFailure("Culdn find terms text")
//            return
//        }
//
        guard let _ = termsTextView.text.lowercased().range(of: termsTextView.text.lowercased()) else {
//            assertionFailure("Culdn find privacy range")
            return
        }
        
        let language = StorageManager().fetch(key: .language, type: String.self)
        let privacyURL = Constant.URLString.privacyPolicy.replacingOccurrences(of: "<language>", with: language ?? "en")
        let termsURL = Constant.URLString.terms.replacingOccurrences(of: "<language>", with: language ?? "en")
        self.termsURL = URL(string: termsURL)!
        self.privacyURL = URL(string: privacyURL)!

        let mutableString = NSMutableAttributedString()
        mutableString.setAttributedString(NSAttributedString(string: termsTextView.text))
        mutableString.addAttributes([NSAttributedString.Key.link: privacyURL, NSAttributedString.Key.font: UIFont(name: "Roboto-regular", size: 13)!,.foregroundColor: UIColor.mimoBlackWith075alpha], range: NSRange(location: 0, length: termsTextView.text.count))
        mutableString.addAttributes([.foregroundColor: UIColor.mimoBlackWith075alpha], range: NSRange(location: 0, length: termsTextView.text.count))
        termsTextView.linkTextAttributes = [.foregroundColor: UIColor.mimoBlackWith075alpha, .underlineColor: UIColor.mimoBlackWith075alpha, .underlineStyle: NSUnderlineStyle.single.rawValue]
        termsTextView.attributedText = mutableString
        termsTextView.delegate = self

    }

    /// Configure next button user interaction and color
    /// navigate to verify phone code
    private func goToVerifyPhoneCodeVC(phoneNumber: String) {
        let verifyPhoneCodeVC = VerifyPhoneCodeViewController.initFromStoryboard(name: Constant.Storyboards.signIn)
        verifyPhoneCodeVC.phoneNumber = phoneNumber
        navigationController?.pushViewController(verifyPhoneCodeVC, animated: true)
    }

    /// navigate to home screen
    private func goToHomeVC(isAccountComplete: Bool) {
//        let homeVC = HomeViewController.initFromStoryboard(name: Constant.Storyboards.home)
//        homeVC.state = isAccountComplete ? .accountDone : .smallBottomSheet
//        let navVC = UINavigationController(rootViewController: homeVC)
//        setRootViewController(navVC)
        
//        HomeRouter.shared.showHomeViewController()
    }
    
    /// tap gesture recognizer selector function view end editing
    @objc private func hideKeyBoard () {
        view.endEditing(true)
    }
    
    /// tap gesture recognizer selector function on agreeTermsAndConditionLabel
    // detect what text is tapped
    
    /// Open Terms
    private func openTerms() {
        let language = authViewModel.getLanguage()
        let urlString = Constant.URLString.terms.replacingOccurrences(of: "<language>", with: language)
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    /// Open privacy and policy
    private func openPrivacyPolicy() {
        let language = authViewModel.getLanguage()
        let urlString = Constant.URLString.privacyPolicy.replacingOccurrences(of: "<language>", with: language)
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
   
    private func updateNextButton() {
        nextButton.isActive = phoneNumber.isValid && termsButton.isSelected && agrementButton.isSelected
    }
    
    @IBAction func checkBoxTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        updateNextButton()
    }
    
    @IBAction func agreementCheckboxTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        updateNextButton()
    }
    
    @IBAction func openAgrementScreen(_ sender: UIButton) {
        self.openTerms()
    }
    @IBAction func openPrivacyScreen(_ sender: UIButton) {
        self.openPrivacyPolicy()
    }
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        
        phoneNumber.phoneTextField.resignFirstResponder()
        guard let phone = phoneNumber.phoneNumber else { return }
//        self.goToVerifyPhoneCodeVC(phoneNumber: phone)
//        return
        MILoader.show()
        authViewModel.signIn(phoneNumber: phone) { [weak self] result in
            guard let self = self else { return }
            MILoader.hide()
            switch result {
            case .success(let (isDeviceVerified, isAccountComplete)):
                if isDeviceVerified {
                    self.splashViewModel.getFinansialState { result in
                        switch result {
                        case .success(let state):
                            UserManager.share.debtState = state
                            UserManager.share.debtAmount = state.additional
                            self.goToHomeVC(isAccountComplete: isAccountComplete)
                        case .failure(let error):
                            UIAlertController.showError(message: error.message.localized())
                        }
                    }
                } else {
                    UserManager.share.debtState = FinancialStateModel(state: .Success, message: nil, additional: 0.0, wallets: [])
                    
                    self.goToVerifyPhoneCodeVC(phoneNumber: phone)
                }
            case .failure(let error):
                print(error)
                MILoader.hide()
                switch error {
                case .invalidParse(let message):
                    UIAlertController.showError(message: message.localized())
                default: break
                }
            }
        }
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension SignInViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL == termsURL {
            let termsController = AgreementViewController.initFromStoryboard(name: "AccountCover")
            let navController = UINavigationController(rootViewController: termsController)

            present(navController, animated: true, completion: nil)
        } else if URL == privacyURL {
            let privacyController = PrivacyPolicyViewController.initFromStoryboard(name: "AccountCover")
            let navController = UINavigationController(rootViewController: privacyController)
            present(navController, animated: true, completion: nil)
        }
        return false
    }
}
