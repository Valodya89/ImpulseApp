//
//  WelcomePlayerUIView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 16.09.23.
//

import UIKit
import SwiftUI
import AVFoundation

class WelcomePlayerUIView: UIView {
    
    private var playerLayer = AVPlayerLayer()
    private var playerLooper: AVPlayerLooper?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Load Video
        let fileURL = Bundle.main.url(forResource: "BackgroundVid", withExtension: "mp4")!
        let playerItem = AVPlayerItem(url: fileURL)
        
        // Setup Player
        let player = AVQueuePlayer(playerItem: playerItem)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
        
        // Loop
        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        
        // Play
        player.play()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        playerLayer.frame = bounds
    }
    
    @objc func rewindVideo(notification: Notification) {
        playerLayer.player?.seek(to: .zero)
    }
}

struct WelcomePlayerView: UIViewRepresentable {
    typealias UIViewType = WelcomePlayerUIView
    
    func makeUIView(context: Context) -> WelcomePlayerUIView {
        WelcomePlayerUIView(frame: .zero)
    }
    
    func updateUIView(_ uiView: WelcomePlayerUIView, context: Context) {
        
    }
}
