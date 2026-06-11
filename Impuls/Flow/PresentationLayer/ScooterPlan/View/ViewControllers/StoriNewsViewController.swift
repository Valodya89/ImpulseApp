//
//  StoriNewsViewController.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 13.09.22.
//

import UIKit
//import FirebaseCore
//import FirebaseAnalytics

class StoriNewsViewController: UIViewController, StoryboardInitializable {

    @IBOutlet weak var progressVieew: UIProgressView!
    @IBOutlet weak var newsImage: UIImageView!
    @IBOutlet private weak var replenishButton: UIButton!
//    @IBOutlet weak var newsTitleLbl: UILabel!
//    @IBOutlet weak var newsDescription: UILabel!
    
//    @IBOutlet weak var cancelIcon: UIImageView!
    @IBOutlet weak var cancelBtn: UIButton!
    var progressValue = 0.001
    var timer: Timer?
    var news:  NewsObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressVieew.progress = 0.0
        self.cancelBtn.isHidden = false
//        self.cancelIcon.isHidden = false
        self.setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateProgressValye), userInfo: nil, repeats: true)
    }
    
    func setupUI() {
        if let news = news {
//            self.newsTitleLbl.text = news.title
//            self.newsDescription.text = news.content
            
            let avatar = "https://\(news.image.node).impulsepower.ru/files?id=\(news.image.id)&token="
            if let imageUrl = URL(string: avatar) {
                newsImage.sd_setImage(with: imageUrl)
            }            
        }
        
        replenishButton.layer.cornerRadius = 24
    }
    
    @objc func updateProgressValye() {
        
        progressValue += 0.001
        self.progressVieew.setProgress(Float(progressValue), animated: true)
        if progressValue >= 1.0 {
            self.cancelBtn.isHidden = false
//            self.cancelIcon.isHidden = false
        }
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction private func replenishAction() {
//        Analytics.logEvent("open_fastShift", parameters: [
//            "user_name": UserManager.share.userResponse?.name ?? "",
//            "user_email": UserManager.share.userResponse?.email ?? "",
//            "user_surname": UserManager.share.userResponse?.surname ?? "",
//        ])
        let url = URL(string: "https://bit.ly/40nGvoa")!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
