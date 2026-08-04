//
//  StreakNotificationController.swift
//  d2d-studio
//
//  Created by Codex on 8/3/26.
//

import Foundation
import UserNotifications

@MainActor
final class StreakNotificationController {
    static let shared = StreakNotificationController()

    private let notificationIdentifier = "com.d2d-studio.knock-streak-risk"
    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    func refreshSchedule(for knocks: [Knock]) {
        let summary = KnockStreakCalculator.summary(from: knocks)

        guard summary.isAtRiskToday else {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
            return
        }

        Task {
            let isAuthorized = await requestAuthorizationIfNeeded()
            guard isAuthorized else { return }

            await scheduleRiskReminder(currentStreak: summary.currentStreak)
        }
    }

    private func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await notificationCenter.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            do {
                return try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    private func scheduleRiskReminder(currentStreak: Int) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "Your knock streak is at risk"
        content.body = "Your \(currentStreak)-day streak needs a knock today. Get back to knocking before the day ends."
        content.sound = .default
        content.threadIdentifier = "knock-streak"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: reminderDelayFromNow(), repeats: false)
        let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)

        try? await notificationCenter.add(request)
    }

    private func reminderDelayFromNow(calendar: Calendar = .current, now: Date = Date()) -> TimeInterval {
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 18
        components.minute = 0
        components.second = 0

        guard let sixPM = calendar.date(from: components), sixPM > now else {
            return 5 * 60
        }

        return sixPM.timeIntervalSince(now)
    }
}
