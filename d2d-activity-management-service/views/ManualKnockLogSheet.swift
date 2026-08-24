//
//  ManualKnockLogSheet.swift
//  d2d-studio
//

import SwiftUI
import SwiftData

struct ManualKnockOutcome: Identifiable, Equatable {
    let id: String
    let title: String
    let systemName: String
    let color: Color

    init(title: String, systemName: String, color: Color) {
        self.id = title
        self.title = title
        self.systemName = systemName
        self.color = color
    }
}

enum ManualKnockLogCompletionAction {
    case none
    case convertToSale
    case customerLost
}

struct ManualKnockLogResult {
    let outcome: ManualKnockOutcome
    let date: Date
    let note: String
    let followUpDate: Date?
    let objection: Objection?
    let tripStartAddress: String
    let tripEndAddress: String
    let tripDate: Date
    let completionAction: ManualKnockLogCompletionAction
}

struct ManualKnockLogSheet: View {
    private enum Step {
        case outcome
        case followUp
        case addObjection
        case trip
        case review
    }

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Objection.timesHeard, order: .reverse) private var objections: [Objection]

    let contactName: String
    let contactType: String
    let outcomes: [ManualKnockOutcome]
    let onLog: (ManualKnockLogResult) -> Void
    let onCancel: () -> Void

    @State private var selectedOutcomeID: String
    @State private var step: Step = .outcome
    @State private var knockDate: Date = .now
    @State private var followUpDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now
    @State private var selectedObjection: Objection?
    @State private var pendingObjections: [Objection] = []
    @State private var noteText = ""
    @State private var isAddingNote = false
    @State private var isEditingDate = false
    @State private var newObjectionText = ""
    @State private var objectionSuggestions: [String] = CommonObjections.all.shuffled().prefix(5).map { $0 }
    @State private var tripStartAddress = ""
    @State private var tripEndAddress = ""
    @State private var tripDate: Date = .now
    @StateObject private var tripSearchVM = SearchCompleterViewModel()
    @FocusState private var focusedField: ManualKnockLogField?
    @FocusState private var tripFocusedField: TripField?

    init(
        contactName: String,
        contactType: String,
        outcomes: [ManualKnockOutcome],
        onLog: @escaping (ManualKnockLogResult) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.contactName = contactName
        self.contactType = contactType
        self.outcomes = outcomes
        self.onLog = onLog
        self.onCancel = onCancel
        _selectedOutcomeID = State(initialValue: outcomes.first?.id ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                content

                Spacer(minLength: 12)

                Button(action: primaryAction) {
                    Text(primaryButtonTitle)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(Color.blue, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(step == .addObjection && newObjectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(step == .addObjection && newObjectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
                .padding(.horizontal, 24)
                .padding(.bottom, 14)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Log Knock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: closeOrBack) {
                        Image(systemName: step == .outcome ? "xmark" : "chevron.left")
                            .font(.title2.weight(.regular))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .outcome:
            outcomeStep
        case .followUp:
            followUpStep
        case .addObjection:
            addObjectionStep
        case .trip:
            tripStep
        case .review:
            reviewStep
        }
    }

    private var outcomeStep: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            VStack(spacing: 10) {
                Image(systemName: selectedOutcome.systemName)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(selectedOutcome.color)
                    .frame(width: 72, height: 72)
                    .background(selectedOutcome.color.opacity(0.12), in: Circle())

                Text(selectedOutcome.title)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(Color(.systemGray2))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 28)

            Picker("Knock Outcome", selection: $selectedOutcomeID) {
                ForEach(outcomes) { outcome in
                    Text(outcome.title).tag(outcome.id)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 172)
            .clipped()
            .padding(.horizontal, 24)
            .onChange(of: selectedOutcomeID) { _, _ in
                KnockingFormHapticsController.shared.lightTap()
            }

            Spacer(minLength: 18)

            if isEditingDate {
                DatePicker("Knock Date", selection: $knockDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 14)
            }

            if isAddingNote {
                TextEditor(text: $noteText)
                    .focused($focusedField, equals: .note)
                    .frame(minHeight: 104, maxHeight: 128)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 14)
            }

            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        isEditingDate.toggle()
                    }
                    focusedField = nil
                    playLightFeedback()
                } label: {
                    optionCard(title: "Date", value: dateLabel(knockDate), systemName: "pencil")
                }
                .buttonStyle(.plain)

                Button {
                    let shouldOpenNote = !isAddingNote
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        isAddingNote = shouldOpenNote
                    }
                    focusedField = shouldOpenNote ? .note : nil
                    playLightFeedback()
                } label: {
                    optionCard(
                        title: "Note",
                        value: noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Add" : "Added",
                        systemName: noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "note.text.badge.plus" : "note.text"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    private var followUpStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader(
                icon: "calendar.badge.clock",
                color: .orange,
                title: "Follow Up Later",
                subtitle: "Choose the objection and the return time before logging this knock."
            )

            DatePicker("Follow-up Date", selection: $followUpDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack(spacing: 8) {
                quickDateChip("Tomorrow", days: 1)
                quickDateChip("Next Week", days: 7)
                quickDateChip("30 Days", days: 30)
            }

            Text("Objection")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            if objectionOptions.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("No saved objections yet. Add one now or continue without an objection.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        step = .addObjection
                        playLightFeedback()
                    } label: {
                        Label("Add Objection", systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                Button {
                    step = .addObjection
                    playLightFeedback()
                } label: {
                    Label("Add Objection", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .background(Color.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(objectionOptions) { objection in
                            objectionRow(objection)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: 210)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
    }

    private var addObjectionStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add a Sales Objection")
                        .font(.title2.bold())

                    Text("Enter what prospects say when they don't buy. Tracking objections helps you spot patterns, sharpen your pitch, and learn how to overcome them.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    Text("What did they say?")
                        .font(.headline)

                    TextField("e.g. Not interested, Too expensive...", text: $newObjectionText)
                        .padding(12)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                        .focused($focusedField, equals: .objection)

                    if !objectionSuggestions.isEmpty {
                        Text("Suggested Objections")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(objectionSuggestions, id: \.self) { item in
                                    Button {
                                        newObjectionText = item
                                        playLightFeedback()
                                    } label: {
                                        Text(item)
                                            .font(.caption.bold())
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background(Color.blue.opacity(0.1), in: Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Button {
                    saveObjection(returnToFollowUp: false)
                } label: {
                    Label("Save & Add Another", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .background(Color.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .disabled(newObjectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
        }
        .onAppear {
            focusedField = .objection
        }
    }

    private var tripStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader(
                icon: "point.topleft.down.curvedto.point.bottomright.up.fill",
                color: .purple,
                title: "Log Trip",
                subtitle: "Optional mileage context for this manual knock. Leave blank to skip."
            )

            tripAddressRow(
                icon: "circle.fill",
                iconColor: .blue,
                placeholder: "Start address",
                text: $tripStartAddress,
                field: .start
            )

            tripAddressRow(
                icon: "mappin.circle.fill",
                iconColor: .red,
                placeholder: "End address",
                text: $tripEndAddress,
                field: .end
            )

            DatePicker("Trip Date", selection: $tripDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Button {
                tripStartAddress = ""
                tripEndAddress = ""
                tripFocusedField = nil
                step = .review
                playLightFeedback()
            } label: {
                Label("Skip Trip", systemImage: "arrow.right.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
            .background(Color.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepHeader(
                icon: selectedOutcome.systemName,
                color: selectedOutcome.color,
                title: selectedOutcome.title,
                subtitle: reviewSubtitle
            )

            reviewRow("Knock Date", value: knockDate.formatted(date: .abbreviated, time: .shortened), icon: "calendar")

            if let followUpDate = followUpDateForResult {
                reviewRow("Follow-Up", value: followUpDate.formatted(date: .abbreviated, time: .shortened), icon: "calendar.badge.clock")
            }

            if let objection = selectedObjection {
                reviewRow("Objection", value: objection.text, icon: "questionmark.bubble")
            }

            if !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                reviewRow("Note", value: noteText, icon: "note.text")
            }

            if !tripEndAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                reviewRow("Trip", value: tripLabel, icon: "point.topleft.down.curvedto.point.bottomright.up.fill")
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
    }

    private var selectedOutcome: ManualKnockOutcome {
        outcomes.first(where: { $0.id == selectedOutcomeID }) ?? outcomes[0]
    }

    private var selectedAction: ManualKnockLogCompletionAction {
        switch selectedOutcome.title {
        case "Converted To Sale":
            .convertToSale
        case "Customer Lost":
            .customerLost
        default:
            .none
        }
    }

    private var primaryButtonTitle: String {
        switch step {
        case .outcome:
            selectedOutcome.title == "Wasn't Home" || selectedOutcome.title == "Unqualified" || selectedOutcome.title == "Requalified" ? "Log Knock" : "Next"
        case .followUp:
            "Next"
        case .addObjection:
            "Save Objection"
        case .trip:
            "Review"
        case .review:
            selectedAction == .customerLost ? "Log Knock & Mark Lost" : selectedAction == .convertToSale ? "Log Knock & Convert" : "Log Knock"
        }
    }

    private var reviewSubtitle: String {
        switch selectedAction {
        case .convertToSale:
            "This will log the knock, then open the conversion form."
        case .customerLost:
            "This will log the knock, then move this customer back to prospects."
        case .none:
            "Review the manual knock before saving."
        }
    }

    private var tripLabel: String {
        let start = tripStartAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let end = tripEndAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        return start.isEmpty ? end : "\(start) to \(end)"
    }

    private var objectionOptions: [Objection] {
        (pendingObjections + objections)
            .filter { $0.text != "Converted To Sale" }
            .sorted { $0.timesHeard > $1.timesHeard }
    }

    private var followUpDateForResult: Date? {
        selectedOutcome.title == "Follow Up Later" ? followUpDate : nil
    }

    private func primaryAction() {
        playSuccessFeedback()

        switch step {
        case .outcome:
            if selectedOutcome.title == "Follow Up Later" {
                step = .followUp
            } else if selectedAction != .none {
                step = .review
            } else {
                finish()
            }
        case .followUp:
            selectedObjection?.timesHeard += 1
            if noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                noteText = defaultFollowUpNote()
            }
            step = .trip
        case .addObjection:
            saveObjection(returnToFollowUp: true)
        case .trip:
            step = .review
        case .review:
            finish()
        }
    }

    private func closeOrBack() {
        playLightFeedback()

        switch step {
        case .outcome:
            onCancel()
        case .followUp:
            step = .outcome
        case .addObjection:
            newObjectionText = ""
            focusedField = nil
            step = .followUp
        case .trip:
            step = selectedOutcome.title == "Follow Up Later" ? .followUp : .outcome
        case .review:
            if selectedOutcome.title == "Follow Up Later" {
                step = .trip
            } else {
                step = .outcome
            }
        }
    }

    private func finish() {
        persistPendingObjections()

        onLog(
            ManualKnockLogResult(
                outcome: selectedOutcome,
                date: knockDate,
                note: noteText.trimmingCharacters(in: .whitespacesAndNewlines),
                followUpDate: followUpDateForResult,
                objection: selectedObjection,
                tripStartAddress: tripStartAddress.trimmingCharacters(in: .whitespacesAndNewlines),
                tripEndAddress: tripEndAddress.trimmingCharacters(in: .whitespacesAndNewlines),
                tripDate: tripDate,
                completionAction: selectedAction
            )
        )
    }

    private func defaultFollowUpNote() -> String {
        let dateString = followUpDate.formatted(date: .abbreviated, time: .shortened)
        guard let objection = selectedObjection else {
            return "\(contactName) asked to follow up later. Follow-up set for \(dateString)."
        }

        return "\(contactName) asked to follow up later after raising this objection: \(objection.text). Follow-up set for \(dateString)."
    }

    private func quickDateChip(_ title: String, days: Int) -> some View {
        Button {
            guard let target = Calendar.current.date(byAdding: .day, value: days, to: .now) else { return }
            let components = Calendar.current.dateComponents([.hour, .minute], from: followUpDate)
            followUpDate = Calendar.current.date(
                bySettingHour: components.hour ?? 9,
                minute: components.minute ?? 0,
                second: 0,
                of: target
            ) ?? target
            playLightFeedback()
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(Color.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundColor(.blue)
    }

    private func persistPendingObjections() {
        guard !pendingObjections.isEmpty else { return }

        let objectionsToPersist = pendingObjections
        for objection in objectionsToPersist {
            modelContext.insert(objection)
        }
        pendingObjections.removeAll()
        try? modelContext.save()

        for objection in objectionsToPersist {
            let text = objection.text
            Task { @MainActor in
                objection.response = await ResponseGenerator.shared.generate(for: text)
                try? modelContext.save()
            }
        }
    }

    private func saveObjection(returnToFollowUp: Bool) {
        let trimmed = newObjectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let objection = Objection(text: trimmed)
        pendingObjections.insert(objection, at: 0)
        selectedObjection = objection
        newObjectionText = ""
        focusedField = returnToFollowUp ? nil : .objection
        playSuccessFeedback()

        if returnToFollowUp {
            step = .followUp
        } else {
            objectionSuggestions = CommonObjections.all.shuffled().prefix(5).map { $0 }
        }
    }

    private func tripAddressRow(
        icon: String,
        iconColor: Color,
        placeholder: String,
        text: Binding<String>,
        field: TripField
    ) -> some View {
        TripAddressAutofillField(
            icon: icon,
            iconColor: iconColor,
            placeholder: placeholder,
            text: text,
            focusedField: $tripFocusedField,
            field: field,
            searchVM: tripSearchVM
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }

    private func objectionRow(_ objection: Objection) -> some View {
        let isSelected = selectedObjection == objection

        return Button {
            selectedObjection = objection
            playLightFeedback()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(objection.text)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.84)

                    Text("Heard \(objection.timesHeard) times")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? Color.blue.opacity(0.10) : Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.blue.opacity(0.55) : Color.primary.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func stepHeader(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
    }

    private func reviewRow(_ title: String, value: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.blue)
                .frame(width: 30, height: 30)
                .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.86)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func optionCard(title: String, value: String, systemName: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                Text(value)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.blue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            Image(systemName: systemName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .frame(height: 74)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(.separator), lineWidth: 1)
        )
    }

    private func dateLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            "Today"
        } else {
            date.formatted(date: .abbreviated, time: .omitted)
        }
    }

    private func playLightFeedback() {
        KnockingFormHapticsController.shared.lightTap()
        KnockingFormSoundController.shared.playConfirmationSound()
    }

    private func playSuccessFeedback() {
        KnockingFormHapticsController.shared.successFeedbackConfirmation()
        KnockingFormSoundController.shared.playConfirmationSound()
    }
}

private enum ManualKnockLogField: Hashable {
    case note
    case objection
}
