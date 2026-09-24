import AppIntents
import Foundation
import SwiftUI
import WidgetKit

private enum KnockNowConstants {
    static let appGroup = "group.okic.d2dcrm"
    static let kind = "knock_now_widget"
    static let snapshotKey = "knockNow.snapshot.v1"
    static let pendingActionsKey = "knockNow.pendingActions.v1"
    static let analyticsKey = "knockNow.analytics.v1"
    static let staleInterval: TimeInterval = 30 * 60
}

private struct KnockNowCandidate: Codable, Hashable {
    let id: String
    let name: String
    let address: String
    let latitude: Double?
    let longitude: Double?
    let etaMinutes: Int
    let priorityDate: Date
    let reason: String
}

private struct KnockNowSnapshot: Codable {
    var generatedAt: Date
    var candidates: [KnockNowCandidate]
}

private struct KnockNowPendingAction: Codable {
    let id: UUID
    let candidateID: String
    let kind: String
    let outcome: String?
    let timestamp: Date
}

private struct KnockNowAnalyticsEvent: Codable {
    let id: UUID
    let name: String
    let candidateID: String?
    let timestamp: Date
    let secondsSinceLastDoor: TimeInterval?
}

private enum KnockNowStore {
    static var defaults: UserDefaults? {
        UserDefaults(suiteName: KnockNowConstants.appGroup)
    }

    static func loadSnapshot() -> KnockNowSnapshot? {
        guard
            let data = defaults?.data(forKey: KnockNowConstants.snapshotKey),
            let snapshot = try? JSONDecoder().decode(KnockNowSnapshot.self, from: data)
        else { return nil }
        return snapshot
    }

    static func advance(
        candidateID: String,
        action: String,
        outcome: String? = nil,
        at date: Date = .now
    ) {
        if var snapshot = loadSnapshot() {
            snapshot.candidates.removeAll { $0.id == candidateID }
            if let data = try? JSONEncoder().encode(snapshot) {
                defaults?.set(data, forKey: KnockNowConstants.snapshotKey)
            }
        }

        if action == "log" {
            var pending = loadPendingActions()
            pending.append(
                KnockNowPendingAction(
                    id: UUID(),
                    candidateID: candidateID,
                    kind: action,
                    outcome: outcome,
                    timestamp: date
                )
            )
            if let data = try? JSONEncoder().encode(pending) {
                defaults?.set(data, forKey: KnockNowConstants.pendingActionsKey)
            }
        }

        record(event: action, candidateID: candidateID, at: date)
        WidgetCenter.shared.reloadTimelines(ofKind: KnockNowConstants.kind)
    }

    static func record(event: String, candidateID: String?, at date: Date = .now) {
        var events = loadAnalytics()
        let previousDoor = events.last(where: { $0.name == "log" })?.timestamp
        events.append(
            KnockNowAnalyticsEvent(
                id: UUID(),
                name: event,
                candidateID: candidateID,
                timestamp: date,
                secondsSinceLastDoor: event == "log" ? previousDoor.map { date.timeIntervalSince($0) } : nil
            )
        )
        if events.count > 500 {
            events.removeFirst(events.count - 500)
        }
        if let data = try? JSONEncoder().encode(events) {
            defaults?.set(data, forKey: KnockNowConstants.analyticsKey)
        }
    }

    private static func loadPendingActions() -> [KnockNowPendingAction] {
        guard
            let data = defaults?.data(forKey: KnockNowConstants.pendingActionsKey),
            let actions = try? JSONDecoder().decode([KnockNowPendingAction].self, from: data)
        else { return [] }
        return actions
    }

    private static func loadAnalytics() -> [KnockNowAnalyticsEvent] {
        guard
            let data = defaults?.data(forKey: KnockNowConstants.analyticsKey),
            let events = try? JSONDecoder().decode([KnockNowAnalyticsEvent].self, from: data)
        else { return [] }
        return events
    }
}

private struct KnockNowEntry: TimelineEntry {
    let date: Date
    let snapshotDate: Date?
    let candidate: KnockNowCandidate?

    var isStale: Bool {
        guard let snapshotDate else { return false }
        return date.timeIntervalSince(snapshotDate) > KnockNowConstants.staleInterval
    }
}

private struct KnockNowProvider: TimelineProvider {
    func placeholder(in context: Context) -> KnockNowEntry {
        KnockNowEntry(
            date: .now,
            snapshotDate: .now,
            candidate: KnockNowCandidate(
                id: "preview",
                name: "Next door",
                address: "123 Main Street",
                latitude: nil,
                longitude: nil,
                etaMinutes: 4,
                priorityDate: .now,
                reason: "dueLead"
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (KnockNowEntry) -> Void) {
        completion(entry(at: .now, preview: context.isPreview))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KnockNowEntry>) -> Void) {
        let now = Date()
        let entry = entry(at: now, preview: false)
        if let candidate = entry.candidate {
            KnockNowStore.record(event: "impression", candidateID: candidate.id, at: now)
        }
        completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(15 * 60))))
    }

    private func entry(at date: Date, preview: Bool) -> KnockNowEntry {
        if preview {
            return KnockNowEntry(
                date: date,
                snapshotDate: date,
                candidate: KnockNowCandidate(
                    id: "preview",
                    name: "Next door",
                    address: "123 Main Street",
                    latitude: nil,
                    longitude: nil,
                    etaMinutes: 4,
                    priorityDate: date,
                    reason: "dueLead"
                )
            )
        }
        let snapshot = KnockNowStore.loadSnapshot()
        return KnockNowEntry(
            date: date,
            snapshotDate: snapshot?.generatedAt,
            candidate: snapshot?.candidates.first
        )
    }
}

struct KnockNowRouteIntent: AppIntent {
    static let title: LocalizedStringResource = "Route to next door"
    static let description = IntentDescription("Opens turn-by-turn directions to the recommended door.")

    @Parameter(title: "Door ID")
    var candidateID: String

    @Parameter(title: "Address")
    var address: String

    init() {}

    init(candidateID: String, address: String) {
        self.candidateID = candidateID
        self.address = address
    }

    func perform() async throws -> some IntentResult & OpensIntent {
        KnockNowStore.record(event: "route", candidateID: candidateID)
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
        let url = URL(string: "https://maps.apple.com/?daddr=\(encoded)&dirflg=d")!
        return .result(opensIntent: OpenURLIntent(url))
    }
}

struct KnockNowSkipIntent: AppIntent {
    static let title: LocalizedStringResource = "Skip door"
    static let description = IntentDescription("Skips this recommendation and shows the next best door.")

    @Parameter(title: "Door ID")
    var candidateID: String

    init() {}

    init(candidateID: String) {
        self.candidateID = candidateID
    }

    func perform() async throws -> some IntentResult {
        KnockNowStore.advance(candidateID: candidateID, action: "skip")
        return .result()
    }
}

enum KnockNowOutcome: String, AppEnum {
    case notHome
    case interested

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Knock outcome")
    static let caseDisplayRepresentations: [KnockNowOutcome: DisplayRepresentation] = [
        .notHome: "Not Home",
        .interested: "Interested"
    ]
}

struct KnockNowLogIntent: AppIntent {
    static let title: LocalizedStringResource = "Log knock"
    static let description = IntentDescription("Logs a quick knock outcome and shows the next best door.")

    @Parameter(title: "Door ID")
    var candidateID: String

    @Parameter(title: "Outcome")
    var outcome: KnockNowOutcome

    init() {}

    init(candidateID: String, outcome: KnockNowOutcome) {
        self.candidateID = candidateID
        self.outcome = outcome
    }

    func perform() async throws -> some IntentResult {
        KnockNowStore.advance(
            candidateID: candidateID,
            action: "log",
            outcome: outcome.rawValue
        )
        return .result()
    }
}

private struct KnockNowWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: KnockNowEntry

    var body: some View {
        if let candidate = entry.candidate {
            switch family {
            case .accessoryRectangular:
                accessoryContent(candidate)
            case .systemMedium:
                mediumContent(candidate)
            default:
                smallContent(candidate)
            }
        } else {
            emptyContent
        }
    }

    private func smallContent(_ candidate: KnockNowCandidate) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            header(candidate)
            Text(candidate.address)
                .font(.subheadline)
                .lineLimit(2)
                .privacySensitive()
            Spacer(minLength: 0)
            Button(intent: KnockNowRouteIntent(candidateID: candidate.id, address: candidate.address)) {
                Label("Route", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint("Opens driving directions in Apple Maps")
        }
    }

    private func mediumContent(_ candidate: KnockNowCandidate) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 7) {
                header(candidate)
                Text(candidate.address)
                    .font(.subheadline)
                    .lineLimit(2)
                    .privacySensitive()
                Spacer(minLength: 0)
                Button(intent: KnockNowRouteIntent(candidateID: candidate.id, address: candidate.address)) {
                    Label("Route", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Opens driving directions in Apple Maps")
            }

            VStack(spacing: 7) {
                Button(intent: KnockNowSkipIntent(candidateID: candidate.id)) {
                    Label("Skip", systemImage: "forward.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(intent: KnockNowLogIntent(candidateID: candidate.id, outcome: .notHome)) {
                    Label("Not Home", systemImage: "house.slash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(intent: KnockNowLogIntent(candidateID: candidate.id, outcome: .interested)) {
                    Label("Interested", systemImage: "hand.thumbsup.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.green)
            }
            .font(.caption.weight(.semibold))
            .frame(width: 118)
        }
    }

    private func accessoryContent(_ candidate: KnockNowCandidate) -> some View {
        Button(intent: KnockNowRouteIntent(candidateID: candidate.id, address: candidate.address)) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Knock Now")
                        .font(.headline)
                    Text(candidate.address)
                        .font(.caption)
                        .lineLimit(1)
                        .privacySensitive()
                }
                Spacer(minLength: 4)
                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Route to \(candidate.address)")
    }

    private func header(_ candidate: KnockNowCandidate) -> some View {
        HStack(spacing: 5) {
            Text("Knock Now")
                .font(.headline)
            if entry.isStale {
                Text("STALE")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.18), in: Capsule())
                    .accessibilityLabel("Offline data may be out of date")
            }
            Spacer(minLength: 0)
            if candidate.etaMinutes > 0 {
                Text("\(candidate.etaMinutes) min")
                    .font(.caption.weight(.semibold))
                    .accessibilityLabel("Estimated drive time, \(candidate.etaMinutes) minutes")
            }
        }
    }

    private var emptyContent: some View {
        ContentUnavailableView {
            Label("No Door Due", systemImage: "checkmark.circle")
        } description: {
            Text("Open D2D Studio to refresh.")
        }
    }
}

struct d2d_widget_service: Widget {
    let kind = KnockNowConstants.kind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KnockNowProvider()) { entry in
            KnockNowWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .invalidatableContent()
        }
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
        .configurationDisplayName("Knock Now")
        .description("See and route to your next best door, then log the outcome.")
    }
}
