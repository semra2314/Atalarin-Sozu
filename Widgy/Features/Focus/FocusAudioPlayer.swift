//
//  FocusAudioPlayer.swift
//  Kare  (app target only)
//
//  Loops an ambient focus sound. Drop the mp3s into the app bundle with these
//  names: rain.mp3, cafe.mp3, waves.mp3, whitenoise.mp3. Missing files are a safe
//  no-op, so the picker still works silently.
//

import Foundation
import AVFoundation

@MainActor
final class FocusAudioPlayer {
    static let shared = FocusAudioPlayer()
    private var player: AVAudioPlayer?

    func play(_ name: String?) {
        stop()
        guard let name,
              let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        player = try? AVAudioPlayer(contentsOf: url)
        player?.numberOfLoops = -1
        player?.volume = 0.7
        player?.play()
    }

    func stop() {
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}
