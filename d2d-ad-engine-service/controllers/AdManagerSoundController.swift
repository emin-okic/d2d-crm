//
//  AdManagerSoundController.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/15/26.
//

import AudioToolbox
import UIKit

@MainActor
final class AdManagerSoundController {

    static let shared = AdManagerSoundController()

    private init() {}

    /// Plays when the Add Property sheet appears
    func playSubtleSuccessSound() {
        AudioServicesPlaySystemSound(1104) // subtle UI tick
    }

}
