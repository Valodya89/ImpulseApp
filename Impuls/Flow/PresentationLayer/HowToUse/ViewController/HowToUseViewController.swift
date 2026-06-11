//
//  HowToUseViewController.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/4/21.
//

import UIKit
import AVKit
import WebKit

class HowToUseViewController: UIViewController, StoryboardInitializable {
    
    @IBOutlet weak var playerView: UIView!
    
    @IBOutlet weak var muteIcon: UIImageView!
    var player: AVPlayerLayer!
    var avPlayer: AVPlayer?
    let viewModel = HowToUseViewModel()
    private var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.setup()
        self.setupYouTubePlayer()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        player.position = playerView.bounds.origin
//        player.frame = playerView.bounds
    }

    func setup() {
        viewModel.getUrl { (result) in
            switch result {
            case .success(let videoUrl):
                avPlayer = AVPlayer(url: videoUrl)
                let playerLayer = AVPlayerLayer(player: avPlayer!)
                playerView.layer.addSublayer(playerLayer)
                avPlayer!.play()
                avPlayer!.isMuted = true
                self.player = playerLayer
            case .failure(let error):
                assertionFailure(error.localizedDescription)
            }
        }
    }
    
    
    private func setupYouTubePlayer() {
        webView = WKWebView(frame: playerView.bounds)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerView.addSubview(webView)

        // if your URL is https://www.youtube.com/watch?v=tVNFj9CWQdM
        let videoID = "tVNFj9CWQdM"

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="referrer" content="strict-origin-when-cross-origin">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            html, body {
              margin: 0;
              padding: 0;
              background-color: #000;
              height: 100%;
              overflow: hidden;
            }
            .container {
              position: fixed;
              top: 0; left: 0; right: 0; bottom: 0;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <iframe
              width="100%" height="100%"
              src="https://www.youtube-nocookie.com/embed/\(videoID)?playsinline=1"
              frameborder="0"
              referrerpolicy="strict-origin-when-cross-origin"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
              allowfullscreen>
            </iframe>
          </div>
        </body>
        </html>
        """

        // baseURL can be nil; if 153 persists you can try a dummy https baseURL
        webView.loadHTMLString(html, baseURL: URL(string: "https://example.com"))
    }
    
    
    @IBAction func muteAction(_ sender: UIButton) {
//        switch sender.tag {
//        case 0 :
//            avPlayer!.isMuted = false
//            sender.tag = 1
//            muteIcon.image = UIImage(named: "unMute")
//        case 1:
//            avPlayer!.isMuted = true
//            sender.tag = 0
//            muteIcon.image = UIImage(named: "mute")
//        default: break
//        }
    }
    
    @IBAction func dismissTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

}
