//
//  FollowUpScreenSoundController.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/15/26.
//

import AudioToolbox
import UIKit

@MainActor
final class FollowUpScreenSoundController {

    static let shared = FollowUpScreenSoundController()

    private init() {}

    /// Plays when the Add Property sheet appears
    func playSound1() {
        AudioServicesPlaySystemSound(1104) // subtle UI tick
    }

}
