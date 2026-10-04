//
//  PrivacyPolicyViewController.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/4/21.
//

import WebKit

class PrivacyPolicyViewController: UIViewController, StoryboardInitializable {

    @IBOutlet weak var webView: WKWebView!
    
    let storageManager = StorageManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let request = URLRequest(url: Constant.URLString.legalURL(.privacyPolicy))
        self.webView.load(request)
        self.webView.navigationDelegate = self
        MILoader.show()
    }
    

    @IBAction func dismissTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }


}

extension PrivacyPolicyViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        MILoader.hide()
    }
}
