//
//  JoinUsViewController.swift
//  MimoBike
//
//  Created by Vardan on 20.04.21.
//

import UIKit
import AVFoundation
import AVKit

final class JoinUsViewController: BaseViewController, StoryboardInitializable {

    
    //MARK: - Outlets
    
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var joinUsButtonContentView: UIView!
    @IBOutlet weak var guestButtonContentVIew: UIView!
    
    fileprivate var avPlayer: AVPlayer!
    fileprivate var avPlayerLayer: AVPlayerLayer!
    
    //MARK: - Life cycle

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
    
    
    //MARK: - Methods
    
    /// configure user interface
    private func configureUI() {
        welcomeLabel.text = "MOBILE_global_welcome_title".localized().replacingOccurrences(of: "MimoBike", with: "")
        joinUsButtonContentView.layer.cornerRadius = Constant.CornerRadius.cornerRadius24
        guestButtonContentVIew.layer.cornerRadius = Constant.CornerRadius.cornerRadius24
        
        guestButtonContentVIew.layer.borderWidth = 1
        guestButtonContentVIew.layer.borderColor = UIColor.mimoBlackWith025alpha.cgColor
    }
    
    /// navigate to signIn screen
    private func goToSignInVC() {
        let signInVC = SignInViewController.initFromStoryboard(name: Constant.Storyboards.signIn)
        let nc = UINavigationController(rootViewController: signInVC)
        goToNextVC(nc)
    }
    
    /// navigate to map screen
    private func goToMapVC() {
        let mapVC = MapViewController.initFromStoryboard(name: Constant.Storyboards.map)
        setRootViewController(UINavigationController(rootViewController: mapVC))
    }
    
    
    //MARK: - Actions

    @IBAction func joinUsTapped(_ sender: UIButton) {
        goToSignInVC()
    }
    
    @IBAction func guestButtonTapped(_ sender: UIButton) {
        goToMapVC()
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
