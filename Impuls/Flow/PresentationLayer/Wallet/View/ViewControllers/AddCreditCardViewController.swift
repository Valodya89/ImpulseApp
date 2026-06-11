//
//  AddCreditCardViewController.swift
//  MimoBike
//
//  Created by Vardan on 20.05.21.
//

import UIKit
import WebKit

protocol AddCreditCardDelegate: AnyObject {
    func didSuccess()
    func didFailure(with error: Error)
}

final class AddCreditCardViewController: UIViewController, StoryboardInitializable {

    fileprivate enum State {
        case attach
        case deposit
    }
    
    //MARK: - Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var attachInfoContent: UIView!
    
    var walletViewModel: WalletViewModel = WalletViewModel()
    
    var gatewayList: [GatewayModel] = []
    
    //MARK: - Life cycle
    private(set) var walletModel: AttachCardModel!
    private var state: State = .attach
    
    var hasOldCards: Bool!
    
    weak var delegate: AddCreditCardDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
    }
    
    
    //MARK: - Methods

    func configureUI() {
//        infoLabel.text = infoLabel.text?.replacingOccurrences(of: "[price]", with: "20")
//        infoLabel.colorString(text: infoLabel.text, coloredText: ["20 \("MOBILE_global_total_currency".localized())"], color: .mimoRed500, font: infoLabel.font)
//        if hasOldCards {
//            infoLabel.text = infoLabel.text?.replacingOccurrences(of: "[num]", with: "2")
//            infoLabel.colorString(text: infoLabel.text, coloredText: ["2 \("MOBILE_global_total_currency".localized())"], color: .mimoRed500, font: infoLabel.font)
//        } else {
//            infoLabel.text = infoLabel.text?.replacingOccurrences(of: "[num]", with: "10")
//            infoLabel.colorString(text: infoLabel.text, coloredText: ["10 \("MOBILE_global_total_currency".localized())"], color: .mimoRed500, font: infoLabel.font)
//        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 30, left: 0, bottom: 0, right: 0)
        webView.uiDelegate = self
        webView.navigationDelegate = self
//        if case .deposit = state {
            webView.isHidden = false
            attachInfoContent.isHidden = true
            webView.load(URLRequest(url: walletModel.formUrl))
//        } else {
//            webView.isHidden = true
//            attachInfoContent.isHidden = false
//        }
//        webView.isHidden = false
//        getGatewayList()
    }
        
    func getGatewayList() {
        MILoader.show()
        walletViewModel.getGateway { result in
            switch result {
            case .success(let success):
                self.gatewayList = success
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    MILoader.hide()
                }
            case .failure(let failure):
                MILoader.hide()
                switch  failure {
                case .custom(let message):
                    self.showErrorAlertMessage(message)
                case .internalError:
                    self.showErrorAlertMessage()
                case .parseError:
                    self.showErrorAlertMessage()
                    
                }
            }
        }
    }
    //MARK: - Actions
    
//    @IBAction func attachTapped(_ sender: CircleButton) {
//        webView.alpha = 0
//        webView.isHidden = false
//        webView.load(URLRequest(url: walletModel.formUrl))
//        UIView.animate(withDuration: 0.3) {
//            self.attachInfoContent.alpha = 0
//            self.webView.alpha = 1
//        }
//    }
}

extension AddCreditCardViewController {
    
    static func config(isDeposit: Bool, hasAttachedCard: Bool, with navigation: Bool = false, walletModel: AttachCardModel, delegate: AddCreditCardDelegate?) -> UIViewController {
        let controller = AddCreditCardViewController.initFromStoryboard(name: "Wallet")
        controller.walletModel = walletModel
        controller.delegate = delegate
        controller.hasOldCards = hasAttachedCard
        controller.state = isDeposit ? .deposit : .attach
        if walletModel.formUrl.absoluteString.contains("cryptocloud") {
            controller.title = "MOBILE__global_payment".localized()
        }
        return navigation ? UINavigationController(rootViewController: controller) : controller
        
    }
}

extension AddCreditCardViewController: WKUIDelegate, WKNavigationDelegate {
    
    func webViewDidClose(_ webView: WKWebView) { }
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) { }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { }
}

extension AddCreditCardViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gatewayList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "GatewayCell", for: indexPath) as? GatewayCell
        cell?.setData(gateway: gatewayList[indexPath.row])
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        MILoader.show()
        let gateway = gatewayList[indexPath.row]
        self.walletViewModel.attachNeweCard(type: gateway.type ?? "") { result in
            
            switch result {
            case .success(let success):
                DispatchQueue.main.async {
                    MILoader.hide()
                    self.webView.alpha = 0
                    self.webView.isHidden = false
                    if let formUrl = URL(string: success.formUrl ?? "") {
                        self.webView.load(URLRequest(url: formUrl))
                        UIView.animate(withDuration: 0.3) {
                            self.attachInfoContent.alpha = 0
                            self.webView.alpha = 1
                        }
                    }
                }
            case .failure(let failure):
                MILoader.hide()
                switch  failure {
                case .custom(let message):
                    self.showErrorAlertMessage(message)
                case .internalError:
                    self.showErrorAlertMessage()
                case .parseError:
                    self.showErrorAlertMessage()
                    
                }
            }
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
}
