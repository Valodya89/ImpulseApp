//
//  LanguageViewController.swift
//  MimoBike
//
//  Created by Vardan on 16.04.21.
//

import UIKit

protocol LanguageViewControllerDelegate: AnyObject {
    func didChoose(index: Int)
}

final class LanguageViewController: BaseViewController, StoryboardInitializable {


    //MARK: - Outlets
    
    @IBOutlet weak var tableView: UITableView!
    
    private let authRepository = AuthRepository()

    
    //MARK: - Variables

    var languages = [LanguageResult]()
    weak var delegate: LanguageViewControllerDelegate?
    
    //MARK: - Life cycles

    override func viewDidLoad() {
        super.viewDidLoad()

        registerCell()
        configureDelegates()
    }
    
    
    //MARK: - Methods
    
    /// register tableView cell
    private func registerCell() {
        tableView.register(UINib(nibName: SelectLanguageTableViewCell.reuseIdentifier(), bundle: nil), forCellReuseIdentifier: SelectLanguageTableViewCell.reuseIdentifier())
    }
    
    ///configure delegates
    private func configureDelegates() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    //MARK: - Actions

    /// close button tapped
    @IBAction func closeTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}


//MARK: - tableView dataSource, delegate

extension LanguageViewController: UITableViewDelegate, UITableViewDataSource {
    
    /// number of rows in section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }
    
    /// create and reuse table view cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = SelectLanguageTableViewCell.reuseIdentifire(from: tableView, indexPath: indexPath)
        cell.setInfo(item: languages[indexPath.row])
        return cell
    }

    /// which cell the user tapped
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        VibrateManager.vibrate()
        let id = self.languages[indexPath.row].id
        if !languages[indexPath.row].isSelected {
            if let _ = KeychainManager().getAccessToken() {
                MILoader.show()
                UserManager.share.getUser { result in
                    switch result {
                    case .failure(let error):
                        MILoader.hide()
                        self.showErrorAlertMessage(error.localizedDescription)
                    case .success(let user):
                        var settings = user.settings
                        settings?.locale = self.languages[indexPath.row].id
                        StorageManager().store(settings?.locale, key: .language)
//                        UserManager.share.updateSettings(settings: settings) { result in
                            MILoader.hide()
                            
                            StorageManager().store(id, key: .language)
                        self.getTranslations(lng: id) { _ in
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(name: Constant.Notifications.LanguageUpdate, object: nil)
                                    BaseRouter.shared.showSplashView()
//                                    UIApplication.shared.windows[0].rootViewController = SplashViewController.initFromStoryboard(name: "Splash")
                                }
                            }
//                        }
                    }
                }
            } else {
                StorageManager().store(self.languages[indexPath.row].id, key: .language)
                self.getTranslations(lng: id) { _ in
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Constant.Notifications.LanguageUpdate, object: nil)
//                        UIApplication.shared.windows[0].rootViewController = SplashViewController.initFromStoryboard(name: "Splash")
                        BaseRouter.shared.showSplashView()
                    }
                }
            }
        }
        
        if !languages[indexPath.row].isSelected {
            delegate?.didChoose(index: indexPath.row)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func getTranslations(lng: String, completion: @escaping (Result<Void, Error>) -> Void) {
        StorageManager().store(lng, key: .language)
        authRepository.getKeyTranslations(lng: lng) { (result) in
            switch result {
            case .success:
                print("language success 1")
                print("result = \(result)")
                completion(.success(()))
            case .failure(let error):
                print("language failure 1")
                completion(.failure(error))
            }
        }
        
    }
    
    /// calculate and return cell height in a row
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constant.Height.height54
    }
}
