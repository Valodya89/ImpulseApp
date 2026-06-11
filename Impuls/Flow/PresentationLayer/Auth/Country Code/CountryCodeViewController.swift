//
//  CountryCodeViewController.swift
//  MimoBike
//
//  Created by Vardan on 21.04.21.
//

import UIKit

protocol CountryCodeViewControllerDelegate: AnyObject {
    func didSelectCountry(_ country: CountryCodeResponse)
}

final class CountryCodeViewController: UIViewController, StoryboardInitializable {
    
    
    //MARK: - Outlets
    
    @IBOutlet weak var viewForTabelView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchFieldContentView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    
    
    //MARK: - Variables
    
    var countryCodesStore: [CountryCodeResponse] = ApplicationSettings.shared.countryCodes
    var countryCodes: [CountryCodeResponse] = ApplicationSettings.shared.countryCodes
    private(set) var selectedID: String? = nil
    
    weak var delegate: CountryCodeViewControllerDelegate?
    
    
    //MARK: - Life cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        countryCodes = []
        ApplicationSettings.shared.fetchCountryCodes()
        countryCodes = ApplicationSettings.shared.countryCodes
        registerCell()
        configureDelegates()
        configureUI()
    }
    
    
    //MARK: - Methods
    
    /// configure delegates
    private func configureDelegates() {
        tableView.delegate = self
        tableView.dataSource = self
        searchTextField.delegate = self
    }
    
    /// register tableView cell
    private func registerCell() {
        tableView.register(UINib(nibName: CountryCodeTableViewCell.reuseIdentifier(), bundle: nil), forCellReuseIdentifier: CountryCodeTableViewCell.reuseIdentifier())
    }
    
    /// configure user iterface
    private func configureUI() {
        searchFieldContentView.layer.cornerRadius = Constant.CornerRadius.cornerRadius21
    }
    
    /// dismiss view controller
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}


//MARK: - tableView dataSource delegate

extension CountryCodeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countryCodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = CountryCodeTableViewCell.reuseIdentifire(from: tableView, indexPath: indexPath)
        if countryCodes.count > 0 {
            cell.isSelected = selectedID == countryCodes[indexPath.row].id
        } else {
            cell.isSelected = false
        }
        if countryCodes.count > 0 {
            cell.setInfo(item: countryCodes[indexPath.row])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        VibrateManager.vibrate()
        if tableView.indexPathsForSelectedRows?.contains(indexPath) ?? false {
            delegate?.didSelectCountry(countryCodes[indexPath.row])
        }
        closeButtonTapped(UIButton())
    }
    
    func search(text: String) {
        self.countryCodes = self.countryCodesStore.filter {
            if text.isEmpty {
                return true
            };
            return ($0.country?.lowercased().contains(text.lowercased()) ?? false) || $0.dial_code?.contains(text) ?? false
        }
        
        self.countryCodes = self.countryCodes.unique(map: {$0.id})
        self.tableView.reloadData()
    }
}

extension Collection where Element: Hashable {
    var orderedSet: [Element] {
        var set: Set<Element> = []
        return reduce(into: []){ set.insert($1).inserted ? $0.append($1) : ()  }
    }
}

extension Array {
    func unique<T:Hashable>(map: ((Element) -> (T)))  -> [Element] {
        var set = Set<T>() //the unique list kept in a Set for fast retrieval
        var arrayOrdered = [Element]() //keeping the unique list of elements but ordered
        for value in self {
            if !set.contains(map(value)) {
                set.insert(map(value))
                arrayOrdered.append(value)
            }
        }

        return arrayOrdered
    }
}
//MARK: - UITextFieldDelegate

extension CountryCodeViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.countryCodes = []
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text,
              let textRange = Range(range, in: text) else {
            return true
        }
        
        let updatingString = text.replacingCharacters(in: textRange, with: string)
        self.search(text: updatingString)
        
        return true
    }
}

// MARK: - Keyboard

extension CountryCodeViewController {
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
        
        let bottomInset = keyboardSize.height
        
        tableView.contentInset.bottom = bottomInset
        
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset.bottom = 0
    }
}

extension CountryCodeViewController {
    static func configure(selectedID: String? = nil, delegate: CountryCodeViewControllerDelegate?) -> UIViewController {
        let controller = CountryCodeViewController.initFromStoryboard(name: "CountryCode")
        controller.delegate = delegate
        controller.selectedID = selectedID
        return controller
    }
}
