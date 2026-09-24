import Foundation

/// Deterministic policy for choosing the next door, kept independent of persistence and UI.
struct NextBestDoorSelectionEngine {
    static let appointmentWindow: TimeInterval = 90 * 60

    func rankedDoors(
        appointments: [KnockNowCandidate],
        leads: [KnockNowCandidate],
        now: Date
    ) -> [KnockNowCandidate] {
        let upcomingAppointments = appointments
            .filter {
                $0.priorityDate >= now
                    && $0.priorityDate <= now.addingTimeInterval(Self.appointmentWindow)
            }
            .sorted { $0.priorityDate < $1.priorityDate }

        let dueLeads = leads
            .filter { $0.priorityDate <= now }
            .sorted {
                if $0.etaMinutes != $1.etaMinutes {
                    return $0.etaMinutes < $1.etaMinutes
                }
                return $0.priorityDate < $1.priorityDate
            }

        return upcomingAppointments + dueLeads
    }
}
