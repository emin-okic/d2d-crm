//
//  KnockingFormHapticsController.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/14/26.
//

import UIKit

@MainActor
final class KnockingFormHapticsController {

    static let shared = KnockingFormHapticsController()

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
    
    func lightTap() {
        lightImpact.impactOccurred()
    }

    /// Rewarding confirmation when a property is added
    func successFeedbackConfirmation() {
        successFeedback.notificationOccurred(.success)
    }

    /// Optional: stronger feedback for bulk adds or milestones
    func mediumTap() {
        mediumImpact.impactOccurred()
    }
}
