import Foundation
import Testing
@testable import d2d_studio

struct NextBestDoorSelectionEngineTests {
    @Test
    func appointmentInsideWindowPrecedesNearerDueLead() {
        let now = Date(timeIntervalSince1970: 1_000)
        let appointment = candidate(id: "appointment", eta: 20, priorityDate: now.addingTimeInterval(60 * 60), reason: "appointment")
        let lead = candidate(id: "lead", eta: 1, priorityDate: now.addingTimeInterval(-60), reason: "dueLead")

        let result = NextBestDoorSelectionEngine().rankedDoors(
            appointments: [appointment],
            leads: [lead],
            now: now
        )

        #expect(result.map(\.id) == ["appointment", "lead"])
    }

    @Test
    func ignoresAppointmentsOutsideNinetyMinutesAndLeadsNotYetDue() {
        let now = Date(timeIntervalSince1970: 1_000)
        let lateAppointment = candidate(id: "late", eta: 1, priorityDate: now.addingTimeInterval(91 * 60), reason: "appointment")
        let futureLead = candidate(id: "future", eta: 1, priorityDate: now.addingTimeInterval(60), reason: "dueLead")

        let result = NextBestDoorSelectionEngine().rankedDoors(
            appointments: [lateAppointment],
            leads: [futureLead],
            now: now
        )

        #expect(result.isEmpty)
    }

    @Test
    func dueLeadsSortByEtaThenOldestDueDate() {
        let now = Date(timeIntervalSince1970: 1_000)
        let farther = candidate(id: "farther", eta: 8, priorityDate: now.addingTimeInterval(-500), reason: "dueLead")
        let newer = candidate(id: "newer", eta: 3, priorityDate: now.addingTimeInterval(-100), reason: "dueLead")
        let older = candidate(id: "older", eta: 3, priorityDate: now.addingTimeInterval(-300), reason: "dueLead")

        let result = NextBestDoorSelectionEngine().rankedDoors(
            appointments: [],
            leads: [farther, newer, older],
            now: now
        )

        #expect(result.map(\.id) == ["older", "newer", "farther"])
    }

    private func candidate(
        id: String,
        eta: Int,
        priorityDate: Date,
        reason: String
    ) -> KnockNowCandidate {
        KnockNowCandidate(
            id: id,
            name: id,
            address: "1 Main Street",
            latitude: nil,
            longitude: nil,
            etaMinutes: eta,
            priorityDate: priorityDate,
            reason: reason
        )
    }
}
