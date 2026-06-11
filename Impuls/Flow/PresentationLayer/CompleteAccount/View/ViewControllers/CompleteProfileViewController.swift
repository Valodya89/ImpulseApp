//
//  CompleteProfileViewController.swift
//  MimoBike
//
//  Created by Vardan on 05.05.21.
//

import UIKit

struct UserModelLight {
    let name: String
    let surname: String
    let gender: String
    let email: String
    let birthday: String
    let avatar: UIImage?
    let bio: String
}

protocol CompleteProfileViewControllerDelegate: AnyObject {
    func didUpdateModel(new model: UserModelLight)
}

final class CompleteProfileViewController: UIViewController, StoryboardInitializable {

    
    //MARK: - Outlets
    
    @IBOutlet weak var sircleIndicator: FPActivityLoader!
//    @IBOutlet weak var doneBarButton: UIButton!
    @IBOutlet weak var userProfileImageView: UIImageView!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var dateOfBirthTextField: MITextFieldView!
    @IBOutlet weak var firstNameTextField: MITextFieldView!
    @IBOutlet weak var emailTextField: MITextFieldView!
    @IBOutlet weak var lastNameTextField: MITextFieldView!
    @IBOutlet weak var sexTextField: MITextFieldView!
    @IBOutlet weak var bioTextView: MITextView!
    @IBOutlet weak var keyboardScrollView: KeyboardScrollView!
    @IBOutlet weak var saveButton: SaveButton!
    
    
    //MARK: - Variables
    weak var resultDelegate: CompleteProfileViewControllerDelegate?
    
    private var currentSelectedImage: UIImage?
    private let completeAccountViewModel = CompleteAccountViewModel()
    private var imagePicker: ImagePickerManager!
    private var datePicker: DatePickerManager!
    private var pickerManager: PickerViewManager!
    private var pickerData = [UserGender.male, UserGender.female]
    private var selectedSex: UserGender?
    
    var existingModel: UserResponse?
    
    //MARK: - Life cycles

    override func viewDidLoad() {
        super.viewDidLoad()
        sircleIndicator.isHidden = true
        configureTextFields()
        MITextFieldView.animatable = false
        configureUI()
        MITextFieldView.animatable = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        let messageService: MessageServiceProtocol = Resolver.resolve()
        messageService.publish(.refreshUser)
    }

    //MARK: - Methods

    private func configureUI() {
        
        DispatchQueue.global().async { [weak self] in
            self?.completeAccountViewModel.getPhoneNumber { [weak self] phoneNumber in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.phoneLabel.text = phoneNumber
                }
            }
        }
        
        emailTextField.textField.keyboardType = .emailAddress
        keyboardScrollView.keyboardDismissMode = .onDrag
        bioTextView.needsUpdateLayout = { [weak self] in
            guard let self = self else { return }
            self.keyboardScrollView.updateScrollDirectionBasedLastResponder()
        }
        
        imagePicker = ImagePickerManager(presentationController: self, delegate: self)
        datePicker = DatePickerManager(view: view, textField: dateOfBirthTextField.textField, hasDoneButton: true, dateFormat: "dd MMMM yyyy", maxDate: Calendar.current.date(byAdding: .year, value: -18, to: Date()))
        
        pickerManager = PickerViewManager(view: view, textField: sexTextField.textField, hasDoneButton: true)
        pickerManager.delegate = self
        pickerManager.dataSource = self
//        doneBarButton.isHidden = true
        title = "MOBILE_on_boarding_edit_profile".localized()

        if let existingModel = existingModel {
            self.userProfileImageView.setImage( existingModel.avatar?.getURL()?.absoluteString, defaultImage: #imageLiteral(resourceName: "ic_default_avatar"))
            firstNameTextField.fieldText = existingModel.name ?? ""
            lastNameTextField.fieldText = existingModel.surname ?? ""
            emailTextField.fieldText = existingModel.email ?? ""
            dateOfBirthTextField.fieldText = existingModel.birthday ?? ""
            sexTextField.fieldText = (existingModel.gender ?? "") == "MALE" ? UserGender.male.rawValue.localized() : UserGender.female.rawValue.localized()
            bioTextView.text = existingModel.bio?.count ?? 0 > 0 ? existingModel.bio : "MOBILE_registartion_bio".localized()
            title = "MOBILE_on_boarding_edit_profile".localized()
//            doneBarButton.isHidden = false
        }
    }
    
    private func configureTextFields() {
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        emailTextField.delegate = self
        dateOfBirthTextField.delegate = self
        sexTextField.delegate = self
        bioTextView.delegate = self
    }
    
    private func presentAccountVC() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AccountDidComplete"), object: nibBundle)
        let accountVC = AccountViewController.initFromStoryboard(name: Constant.Storyboards.account)
        navigationController?.pushViewController(accountVC, animated: true)
    }
    
    private func completeAccount() {
        
        if let selectedImage = currentSelectedImage {
            let sesson = SessionNetwork()
            sesson.request(with: URLBuilder(from: ImageUploadAPI.upload(image: selectedImage))) { res in
                NotificationCenter.default.post(name: Constant.Notifications.updateUserPicture, object: nil)
            }
        }
        
        UserManager.share.getUser { [weak self] result in
            guard let unwrapSelf = self else { return }
            
            switch result {
            case .failure(let error):
                unwrapSelf.showAlertMessage(error.localizedDescription)
            case .success(let user):
                unwrapSelf.completeAccountViewModel.completeAccount(firstName: unwrapSelf.firstNameTextField.textField.text,
                                                         lastName: unwrapSelf.lastNameTextField.textField.text,
                                                         email: unwrapSelf.emailTextField.textField.text,
                                                         dob: unwrapSelf.datePicker.datePickerView.date,
                                                         sex: unwrapSelf.selectedSex,
                                                         bio: unwrapSelf.bioTextView.textView.text,
                                                         settings: user.settings ?? UserResponse.SettingsModel(locale: "en",
                                                                                                               sendPush: true, mode: .light)) { [weak self] result in
                    guard let self = self else { return }
                    
                    switch result {
                    case .success:
//                        self.presentAccountVC()
                        self.dismiss(animated: true)
                    case .failure(let error):
                        self.showAlertMessage(error.message.localized())
                    }
                }
            }
        }
        
    }
    
    private func validate() {
        completeAccountViewModel.validate(firstName: firstNameTextField.textField.text, lastName: lastNameTextField.textField.text, email: emailTextField.textField.text, dob: datePicker.datePickerView.date, sex: sexTextField.textField.text, bio: bioTextView.textView.text) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.saveButton.change(to: .active)
            case .failure:
                self.saveButton.change(to: .inActive)
            }
        }
    }
    
    
    //MARK: - Actions

    @IBAction func saveTapped(_ sender: UIButton) {
        if let delegate = resultDelegate {
            
            if let selectedImage = currentSelectedImage {
                let sesson = SessionNetwork()
                MILoader.show()
                sircleIndicator.isHidden = false
                sircleIndicator.animating = true
                sircleIndicator.circleTime = 5
                sesson.request(with: URLBuilder(from: ImageUploadAPI.upload(image: selectedImage))) { res in
                    switch res {
                    case .success(let data):
                        print("image upload data = \(data)")
                        guard let userResponse = MimoConverter<BaseResponseModel<UserResponse>>.parseJson(data: data as Any) else {
                            return
                        }
                        
                        let date =  self.datePicker.datePickerView.date.toString(format: .custom("dd-MM-yyyy"))
                        self.sircleIndicator.isHidden = true
                        self.sircleIndicator.animating = false
                        delegate.didUpdateModel(new: UserModelLight(name: self.firstNameTextField.fieldText, surname: self.lastNameTextField.fieldText, gender: self.selectedSex?.key ?? "MALE", email: self.emailTextField.fieldText, birthday: date, avatar: self.currentSelectedImage, bio: self.bioTextView.fieldText))
                        
                        if let content = userResponse.content, userResponse.statusCode == 200 {
                            print("UserResponse === \(userResponse)")
                            UserDefaults.standard.set(content.avatar?.id, forKey: "avatarId")
                        }
                        NotificationCenter.default.post(name: Constant.Notifications.updateUserPicture, object: nil)
                        self.saveButton.change(to: .inActive)
                        
                        
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                    
                    MILoader.hide()
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                var date =  ""
                if self.dateOfBirthTextField.textField.text?.count ?? 0 == 10 {
                    date  = self.dateOfBirthTextField.textField.text ?? ""
                } else {
                    date = self.datePicker.datePickerView.date.toString(format: .custom("dd-MM-yyyy"))
                }
                delegate.didUpdateModel(new: UserModelLight(name: self.firstNameTextField.fieldText, surname: self.lastNameTextField.fieldText, gender: self.selectedSex?.key ?? "MALE", email: self.emailTextField.fieldText, birthday: date, avatar: self.currentSelectedImage, bio: self.bioTextView.fieldText))
                self.saveButton.change(to: .inActive)
            }
        } else {
            completeAccount()
        }
    }
    
    @IBAction func addProfilePhoto(_ sender: UIButton) {
        imagePicker.present(from: sender)
    }
    
    @IBAction func doneTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}


// MARK: - ImagePicker Delegate

extension CompleteProfileViewController: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        VibrateManager.vibrate()
        guard let image = image else { return }
        userProfileImageView.image = image
        currentSelectedImage = image
        validate()
    }
}


// MARK: - UITextField Delegate

extension CompleteProfileViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        switch textField {
        case dateOfBirthTextField.textField:
            datePicker.showDatePicker(mode: .date)
        case sexTextField.textField:
            pickerManager.showPickerView()
        default:
            break
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        
        if textField == sexTextField.textField {
            sexTextField.textField.text = selectedSex?.rawValue.localized() ?? pickerData[0].rawValue.localized()
            if selectedSex == nil {
                selectedSex = .male
            }
        }
        validate()
    }
}

extension CompleteProfileViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        validate()
    }
}


// MARK: - PickerViewManager Delegate and DataSource

extension CompleteProfileViewController: PickerViewManagerDelegate, PickerViewManagerDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return pickerData[row].rawValue.localized()
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        VibrateManager.vibrate()
        selectedSex = pickerData[row]
        sexTextField.textField.text = pickerData[row].rawValue.localized()
    }
}

extension CompleteProfileViewController {
    
    static func config(with navigation: Bool, existingModel: UserResponse?, delegate: CompleteProfileViewControllerDelegate?) -> UIViewController {
    
        let controller = CompleteProfileViewController.initFromStoryboard(name: Constant.Storyboards.completeAccount)
        controller.existingModel = existingModel
        controller.resultDelegate = delegate
        return navigation ? controller.navigationController ?? UINavigationController(rootViewController: controller) : controller
    }
}
