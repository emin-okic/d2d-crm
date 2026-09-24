import CoreLocation
import Foundation
import SwiftData
import WidgetKit

@MainActor
enum KnockNowSnapshotService {
    private static let appGroup = "group.okic.d2dcrm"
    private static let snapshotKey = "knockNow.snapshot.v1"
    private static let pendingActionsKey = "knockNow.pendingActions.v1"
    private static let widgetKind = "knock_now_widget"

    static func refresh(modelContext: ModelContext, now: Date = .now) {
        applyPendingActions(modelContext: modelContext)

        let prospects = (try? modelContext.fetch(FetchDescriptor<Prospect>())) ?? []
        let appointments = (try? modelContext.fetch(FetchDescriptor<Appointment>())) ?? []
        let coordinate = LocationManager.shared.currentLocation

        let appointmentDoors = appointments
            .filter { !$0.isCompleted }
            .compactMap { appointment -> KnockNowCandidate? in
                let address = appointment.location.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !address.isEmpty else { return nil }
                let prospect = appointment.prospect
                return KnockNowCandidate(
                    id: prospect?.uuid.uuidString ?? appointment.id.uuidString,
                    name: appointment.clientName.isEmpty ? appointment.title : appointment.clientName,
                    address: address,
                    latitude: prospect?.latitude,
                    longitude: prospect?.longitude,
                    etaMinutes: estimatedMinutes(
                        from: coordinate,
                        latitude: prospect?.latitude,
                        longitude: prospect?.longitude
                    ),
                    priorityDate: appointment.date,
                    reason: "appointment"
                )
            }

        let dueDoors = prospects
            .filter { prospect in
                prospect.list.localizedCaseInsensitiveCompare("Prospects") == .orderedSame
                    && !prospect.isUnqualified
                    && !prospect.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && !prospect.fullName.localizedCaseInsensitiveContains("do not knock")
            }
            .map { prospect in
                let lastKnock = prospect.knockHistory.map(\.date).max() ?? .distantPast
                return KnockNowCandidate(
                    id: prospect.uuid.uuidString,
                    name: prospect.fullName,
                    address: prospect.address,
                    latitude: prospect.latitude,
                    longitude: prospect.longitude,
                    etaMinutes: estimatedMinutes(
                        from: coordinate,
                        latitude: prospect.latitude,
                        longitude: prospect.longitude
                    ),
                    priorityDate: lastKnock.addingTimeInterval(24 * 60 * 60),
                    reason: "dueLead"
                )
            }

        let rankedDoors = NextBestDoorSelectionEngine().rankedDoors(
            appointments: appointmentDoors,
            leads: dueDoors,
            now: now
        )
        let snapshot = KnockNowSnapshot(
            generatedAt: now,
            candidates: rankedDoors
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults(suiteName: appGroup)?.set(data, forKey: snapshotKey)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    private static func applyPendingActions(modelContext: ModelContext) {
        guard
            let defaults = UserDefaults(suiteName: appGroup),
            let data = defaults.data(forKey: pendingActionsKey),
            let actions = try? JSONDecoder().decode([KnockNowPendingAction].self, from: data),
            !actions.isEmpty
        else { return }

        let prospects = (try? modelContext.fetch(FetchDescriptor<Prospect>())) ?? []
        let coordinate = LocationManager.shared.currentLocation

        for action in actions where action.kind == "log" {
            guard
                let id = UUID(uuidString: action.candidateID),
                let prospect = prospects.first(where: { $0.uuid == id }),
                let outcome = action.outcome
            else { continue }

            prospect.knockCount += 1
            prospect.knockHistory.append(
                Knock(
                    date: action.timestamp,
                    status: outcome == "notHome" ? "Wasn't Home" : "Interested",
                    latitude: coordinate?.latitude ?? prospect.latitude ?? 0,
                    longitude: coordinate?.longitude ?? prospect.longitude ?? 0
                )
            )
        }

        try? modelContext.save()
        defaults.removeObject(forKey: pendingActionsKey)
    }

    private static func estimatedMinutes(
        from origin: CLLocationCoordinate2D?,
        latitude: Double?,
        longitude: Double?
    ) -> Int {
        guard let origin, let latitude, let longitude else { return 0 }
        let start = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let destination = CLLocation(latitude: latitude, longitude: longitude)
        let miles = start.distance(from: destination) / 1_609.344
        return max(1, Int(ceil((miles / 25) * 60)))
    }
}

private struct KnockNowSnapshot: Codable {
    let generatedAt: Date
    let candidates: [KnockNowCandidate]
}

struct KnockNowCandidate: Codable {
    let id: String
    let name: String
    let address: String
    let latitude: Double?
    let longitude: Double?
    let etaMinutes: Int
    let priorityDate: Date
    let reason: String
}

private struct KnockNowPendingAction: Codable {
    let id: UUID
    let candidateID: String
    let kind: String
    let outcome: String?
    let timestamp: Date
}
