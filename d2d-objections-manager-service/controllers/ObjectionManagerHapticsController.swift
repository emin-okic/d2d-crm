//
//  ObjectionManagerHapticsController.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/14/26.
//

import UIKit

@MainActor
final class ObjectionManagerHapticsController {

    static let shared = ObjectionManagerHapticsController()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let successFeedback = UINotificationFeedbackGenerator()

    private init() {
        prepare()
    }

    private func prepare() {
        lightImpact.prepare()
        mediumImpact.prepare()
        successFeedback.prepare()
    }

    /// Subtle feedback when user taps the map (feels responsive, not noisy)
    func screenTap() {
        lightImpact.impactOccurred()
    }

    /// Rewarding confirmation when a property is added
    func successAction() {
        successFeedback.notificationOccurred(.success)
    }

    /// Optional: stronger feedback for bulk adds or milestones
    func actionConfirmation() {
        mediumImpact.impactOccurred()
    }
}
