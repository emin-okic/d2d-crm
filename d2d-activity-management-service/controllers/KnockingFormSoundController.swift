//
//  KnockingFormSoundController.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/14/26.
//

import AudioToolbox
import UIKit

@MainActor
final class KnockingFormSoundController {

    static let shared = KnockingFormSoundController()

    private init() {}

    /// Plays when the Add Property sheet appears
    func playConfirmationSound() {
        AudioServicesPlaySystemSound(1104) // subtle UI tick
    }
}
