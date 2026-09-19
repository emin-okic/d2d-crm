import Foundation
import Testing
@testable import d2d_studio

struct AppointmentStatusTests {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    @Test
    func futureUncompletedAppointmentIsUpcoming() {
        let appointment = makeAppointment(date: now.addingTimeInterval(60))

        #expect(appointment.status(at: now) == .upcoming)
        #expect(appointment.isClosed == false)
        #expect(appointment.isUpcomingBucket(now: now))
    }

    @Test
    func pastUncompletedAppointmentIsMissedButRemainsOpen() {
        let appointment = makeAppointment(date: now.addingTimeInterval(-60))

        #expect(appointment.status(at: now) == .missed)
        #expect(appointment.isCompleted == false)
        #expect(appointment.completedAt == nil)
        #expect(appointment.isClosed == false)
        #expect(appointment.isPastBucket(now: now))
    }

    @Test
    func explicitCompletionTakesPrecedenceOverSchedule() {
        let futureDate = now.addingTimeInterval(60)
        let appointment = makeAppointment(
            date: futureDate,
            isCompleted: true,
            completedAt: now
        )

        #expect(appointment.status(at: now) == .completed)
        #expect(appointment.isClosed)
        #expect(appointment.isPastBucket(now: now))
    }

    private func makeAppointment(
        date: Date,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) -> Appointment {
        Appointment(
            title: "Follow Up",
            location: "123 Main Street",
            clientName: "Taylor",
            date: date,
            type: "Meeting",
            isCompleted: isCompleted,
            completedAt: completedAt
        )
    }
}
