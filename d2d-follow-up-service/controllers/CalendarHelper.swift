//
//  CalendarHelper.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/31/25.
//

import Foundation
import EventKit
import SwiftUI

final class CalendarHelper: ObservableObject {

    func addToAppleCalendar(appointment: Appointment, completion: @escaping (Result<Void, Error>) -> Void) {
        let store = EKEventStore()
        store.requestAccess(to: .event) { granted, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard granted else {
                completion(.failure(NSError(domain: "CalendarAccess", code: 1, userInfo: [NSLocalizedDescriptionKey: "Access denied"])))
                return
            }

            let event = EKEvent(eventStore: store)
            event.title = appointment.title
            event.startDate = appointment.date
            event.endDate = appointment.date.addingTimeInterval(60 * 30)
            event.location = appointment.location
            event.notes = appointment.notes.joined(separator: "\n")
            event.calendar = store.defaultCalendarForNewEvents

            do {
                try store.save(event, span: .thisEvent)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func addToGoogleCalendar(appointment: Appointment) {
        // Build a Google Calendar link for web or app
        let start = iso8601String(for: appointment.date)
        let end = iso8601String(for: appointment.date.addingTimeInterval(60 * 30))
        let title = appointment.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let location = appointment.location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let details = appointment.notes.joined(separator: "\n").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let urlString = """
        https://calendar.google.com/calendar/render?action=TEMPLATE&text=\(title)&dates=\(start)/\(end)&details=\(details)&location=\(location)&sf=true&output=xml
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
