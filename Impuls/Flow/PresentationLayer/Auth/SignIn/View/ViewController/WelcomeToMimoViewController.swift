//
//  WelcomeToMimoViewController.swift
//  MimoBike
//
//  Created by Vardan on 16.04.21.
//

import UIKit
import AVFoundation
import AVKit

final class WelcomeToMimoViewController: BaseViewController, StoryboardInitializable {

    
    //MARK: - Outlets
    
    @IBOutlet weak var selectLanguageButtonView: UIView!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var languageLabel: UILabel!
    @IBOutlet weak var flagImageView: UIImageView!
    @IBOutlet weak var downArrowImageView: UIImageView!
    @IBOutlet weak var nextButtonView: UIView!
    @IBOutlet weak var nextLabel: UILabel!
    
    fileprivate var avPlayer: AVPlayer!
    fileprivate var avPlayerLayer: AVPlayerLayer!
    
    //MARK: - Variables
    
    private let authViewModel = AuthViewModel()
    var languages = [LanguageResult]()
    
    
    //MARK: - Life cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        
        if let str = Bundle.main.path(forResource: "BackgroundVid", ofType: "mp4") {
            let theURL = URL(fileURLWithPath: str)
            self.avPlayer = AVPlayer(url: theURL)
            self.avPlayer.isMuted = true
            self.avPlayer.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
            self.avPlayer.preventsDisplaySleepDuringVideoPlayback = false
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default, options: .mixWithOthers)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {}
            self.avPlayerLayer = AVPlayerLayer(player: avPlayer)
            self.avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            self.avPlayerLayer.frame = view.layer.bounds
            self.view.layer.insertSublayer(self.avPlayerLayer, at: 0)
            self.initialPlay()
            
        }
        addObservers()
        avPlayer?.actionAtItemEnd = .none

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: avPlayer?.currentItem)

    }
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
        }
    }
    
    fileprivate  func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc fileprivate func applicationDidBecomeActive() {
        self.initialPlay()
    }
    
    fileprivate  func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    fileprivate func play(fromStart: Bool = false) -> Bool {
        if let pl = self.avPlayer {
            if pl.status == .readyToPlay && pl.currentItem?.status == .readyToPlay {
                self.avPlayer.play()
                if fromStart {
                    pl.currentItem?.seek(to: CMTime.zero) { (finished) in _ = self.avPlayer.play() }
                }
                return true
            } else {
                return false
            }
        }
        return false
    }
    
    fileprivate func initialPlay() {
        if !self.play() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { self.initialPlay() })
        }
    }

    //MARK: - methods
    
    /// Configure screen UI
    private func configureUI() {
        welcomeLabel.text = "MOBILE_global_welcome_title".localized().replacingOccurrences(of: "MimoBike", with: "")
        
        var hasLanguageSelected = false
        languages.forEach { language in
            if language.isSelected {
                hasLanguageSelected = true
                self.setLanguage(language)
                StorageManager().store(language.id, key: .language)
                return
            }
        }
        
        if !hasLanguageSelected {
            let defaultLanguage = languages.filter { $0.id == Locale.current.languageCode }.first
            
            let armeniaFlag = #imageLiteral(resourceName: "ic_armenia")
            let armLanguage = LanguageResult(id: "hy", name: "հայերեն", flag: armeniaFlag.jpegData(compressionQuality: 1.0)!, isSelected: true)
            
            let unwrapLanguage = defaultLanguage ?? armLanguage

            StorageManager().store(unwrapLanguage.id, key: .language)
            self.setLanguage(unwrapLanguage)
        }
        
        selectLanguageButtonView.layer.borderWidth = 1
        selectLanguageButtonView.layer.borderColor = UIColor.mimoBlackWith025alpha.cgColor
        selectLanguageButtonView.layer.cornerRadius = Constant.CornerRadius.cornerRadius24
        nextButtonView.layer.cornerRadius = Constant.CornerRadius.cornerRadius24
    }
    
    /// present language view controller
    private func presentLanguageVC() {
        let languageVC = LanguageViewController.initFromStoryboard(name: Constant.Storyboards.signIn)
        languageVC.languages = languages
        languageVC.delegate = self
        present(languageVC, animated: true, completion: nil)
    }
    
    /// Open join us view controller
    private func gotoJoinUsVC() {
        let joinUsVC = JoinUsViewController.initFromStoryboard(name: Constant.Storyboards.signIn)
        goToNextVC(joinUsVC)
    }
    
    /// Set selected language
    private func setLanguage(_ language: LanguageResult) {
        languageLabel.text = language.name
        flagImageView.image = UIImage(data: language.flag)
    }
    
    /// select one item
    private func selectOneItem(index: Int) {
        for i in 0..<languages.count {
            if i == index {
                languages[i].isSelected = true
                setLanguage(languages[i])
            } else {
                languages[i].isSelected = false
            }
        }
    }
    
    
    //MARK: - IBActions
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        gotoJoinUsVC()
    }
    
    @IBAction func selectLanguageTapped(_ sender: UIButton) {
        presentLanguageVC()
    }
}


// MARK: - Language ViewController Delegate
extension WelcomeToMimoViewController: LanguageViewControllerDelegate {
    func didChoose(index: Int) {
       selectOneItem(index: index)
    }
}
