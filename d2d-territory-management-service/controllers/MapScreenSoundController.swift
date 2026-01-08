//
//  MapScreenSoundController.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/8/26.
//

import AVFoundation

@MainActor
final class MapScreenSoundController {

    static let shared = MapScreenSoundController()

    private var openPlayer: AVAudioPlayer?
    private var successPlayer: AVAudioPlayer?

    private init() {
        prepare()
    }

    private func prepare() {
        openPlayer = loadSound(named: "property_open")
        successPlayer = loadSound(named: "property_add")

        openPlayer?.prepareToPlay()
        successPlayer?.prepareToPlay()
    }

    private func loadSound(named name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            print("❌ Missing sound file:", name)
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.7 // subtle, premium
            return player
        } catch {
            print("❌ Failed to load sound:", error)
            return nil
        }
    }

    /// Plays when the Add Property sheet appears
    func playPropertyOpen() {
        openPlayer?.currentTime = 0
        openPlayer?.play()
    }

    /// Plays when a property is successfully added
    func playPropertyAdded() {
        successPlayer?.currentTime = 0
        successPlayer?.play()
    }
}
