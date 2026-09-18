//
//  MimoFeedback.swift
//  Impuls
//
//  One place for the small physical feedback the app gives: haptics and the
//  two short sounds used by pull-to-refresh. Both are user-switchable in
//  Settings; sounds also follow the silent switch (ambient audio session) and
//  stay quiet in Low Power Mode.
//

import UIKit
import AVFoundation

final class MimoFeedback {

    static let shared = MimoFeedback()

    enum Sound: String {
        /// Ring completed, the pull "locked in". 60 ms.
        case refreshTick = "refresh_tick"
        /// Refresh finished. 90 ms.
        case refreshPop = "refresh_pop"
    }

    private let storage = StorageManager()
    private var players: [Sound: AVAudioPlayer] = [:]

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let notification = UINotificationFeedbackGenerator()

    private init() {}

    // MARK: - Preferences

    var isHapticsEnabled: Bool {
        get { storage.fetch(key: .hapticsEnabled, type: Bool.self) ?? true }
        set { storage.store(newValue, key: .hapticsEnabled) }
    }

    var isSoundsEnabled: Bool {
        get { storage.fetch(key: .soundsEnabled, type: Bool.self) ?? true }
        set { storage.store(newValue, key: .soundsEnabled) }
    }

    // MARK: - Haptics

    /// Warm the Taptic Engine up while a gesture is in progress, so the first
    /// impact lands with no latency.
    func prepareImpact() {
        guard isHapticsEnabled else { return }
        lightImpact.prepare()
    }

    func impactLight() {
        guard isHapticsEnabled else { return }
        lightImpact.impactOccurred()
    }

    func success() {
        guard isHapticsEnabled else { return }
        notification.notificationOccurred(.success)
    }

    func error() {
        guard isHapticsEnabled else { return }
        notification.notificationOccurred(.error)
    }

    // MARK: - Sounds

    func play(_ sound: Sound) {
        guard isSoundsEnabled, !ProcessInfo.processInfo.isLowPowerModeEnabled else { return }

        if players[sound] == nil {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav"),
                  let player = try? AVAudioPlayer(contentsOf: url) else { return }
            player.volume = 0.6
            player.prepareToPlay()
            players[sound] = player
        }

        // `.ambient` mixes with whatever is playing and is muted by the silent
        // switch - a UI tick must never interrupt the rider's music or call.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true, options: [])

        let player = players[sound]
        player?.currentTime = 0
        player?.play()
    }
}
