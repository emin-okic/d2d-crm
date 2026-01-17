//
//  RecordingScreenSoundController.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/17/26.
//

import AudioToolbox
import UIKit

@MainActor
final class RecordingScreenSoundController {

    static let shared = RecordingScreenSoundController()

    private init() {}

    /// Plays when the Add Property sheet appears
    func playSound1() {
        AudioServicesPlaySystemSound(1104) // subtle UI tick
    }

}
