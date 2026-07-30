//
//  CalendarHelper.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/31/25.
//

import Foundation
@preconcurrency import EventKit
import SwiftUI

private struct SendableEventStore: @unchecked Sendable {
    let store: EKEventStore
}

final class CalendarHelper: ObservableObject {

    func addToAppleCalendar(appointment: Appointment, completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        let eventStore = SendableEventStore(store: EKEventStore())
        let title = appointment.title
        let startDate = appointment.date
        let endDate = appointment.date.addingTimeInterval(60 * 30)
        let location = appointment.location
        let notes = appointment.notes.joined(separator: "\n")

        @Sendable func handleAccess(granted: Bool, error: Error?) {
            if let error = error {
                completion(.failure(error))
                return
            }

            guard granted else {
                completion(.failure(NSError(domain: "CalendarAccess", code: 1, userInfo: [NSLocalizedDescriptionKey: "Access denied"])))
                return
            }

            let event = EKEvent(eventStore: eventStore.store)
            event.title = title
            event.startDate = startDate
            event.endDate = endDate
            event.location = location
            event.notes = notes
            event.calendar = eventStore.store.defaultCalendarForNewEvents

            do {
                try eventStore.store.save(event, span: .thisEvent)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }

        if #available(iOS 17.0, *) {
            eventStore.store.requestFullAccessToEvents { granted, error in
                handleAccess(granted: granted, error: error)
            }
        } else {
            eventStore.store.requestAccess(to: .event) { granted, error in
                handleAccess(granted: granted, error: error)
            }
        }
    }


    @MainActor
    func addToGoogleCalendar(appointment: Appointment) {
        // Google Calendar expects UTC in this exact format: yyyyMMdd'T'HHmmss'Z'
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC

        let startUTC = formatter.string(from: appointment.date)
        let endUTC = formatter.string(from: appointment.date.addingTimeInterval(60 * 30))

        let title = appointment.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let location = appointment.location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let details = appointment.notes.joined(separator: "\n").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let urlString = """
        https://calendar.google.com/calendar/render?action=TEMPLATE&text=\(title)&dates=\(startUTC)/\(endUTC)&details=\(details)&location=\(location)&sf=true&output=xml
        """

        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func iso8601String(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date).replacingOccurrences(of: ":", with: "")
    }
}
