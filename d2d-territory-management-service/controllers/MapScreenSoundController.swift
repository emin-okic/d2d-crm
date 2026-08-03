//
//  MapScreenSoundController.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/8/26.
//

import AudioToolbox
import UIKit

@MainActor
final class MapScreenSoundController {

    static let shared = MapScreenSoundController()

    private init() {}

    /// Plays when the Add Property sheet appears
    func playPropertyOpen() {
        AudioServicesPlaySystemSound(1104) // subtle UI tick
    }

    /// Plays when a property is successfully added
    func playPropertyAdded() {
        AudioServicesPlaySystemSound(1104) // rewarding success tap
    }

    func playScorecardSelectorOpen() {
        AudioServicesPlaySystemSound(1104)
    }

    func playScorecardSelectorClose() {
        AudioServicesPlaySystemSound(1157)
    }

    func playScorecardAdded() {
        AudioServicesPlaySystemSound(1104)
    }

    func playScorecardRemoved() {
        AudioServicesPlaySystemSound(1155)
    }

    func playScorecardLimitReached() {
        AudioServicesPlaySystemSound(1053)
    }
}
