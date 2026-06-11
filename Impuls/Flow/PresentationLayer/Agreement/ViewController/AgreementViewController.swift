//
//  AgreementViewController.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/4/21.
//

import WebKit

class AgreementViewController: UIViewController, StoryboardInitializable {
    
    @IBOutlet weak var webView: WKWebView!
    
    let storageManager = StorageManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        var languageKey = storageManager.fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))
        let urlString = Constant.URLString.terms.replacingOccurrences(of: "<language>", with: languageKey)
        let request = URLRequest(url: URL(string: urlString)!)
        self.webView.load(request)
        self.webView.navigationDelegate = self
        MILoader.show()
    }
    
    @IBAction func dismissTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension AgreementViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        MILoader.hide()
    }
}
