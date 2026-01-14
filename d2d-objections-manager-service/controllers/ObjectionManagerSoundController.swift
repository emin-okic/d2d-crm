//
//  ObjectionManagerSoundController.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/14/26.
//

import AudioToolbox
import UIKit

@MainActor
final class ObjectionManagerSoundController {

    static let shared = ObjectionManagerSoundController()

    private init() {}

    /// Plays when the Add Property sheet appears
    func playActionSound() {
        AudioServicesPlaySystemSound(1104) // subtle UI tick
    }

}
