//
//  KnockStepperPopupView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/11/25.
//

import SwiftUI
import SwiftData
import MapKit

struct KnockStepperPopupView: View {
    // Inputs
    let context: KnockContext
    
    let initialOutcome: KnockOutcome = .followUpLater

    // Dependencies
    let objections: [Objection]
    let saveKnock: (_ outcome: KnockOutcome) -> Prospect
    let incrementObjection: (_ obj: Objection) -> Void
    let saveFollowUp: (_ prospect: Prospect, _ date: Date) -> Void
    let convertToCustomer: (_ prospect: Prospect, _ onDone: @escaping () -> Void) -> Void
    let addNote: (_ prospect: Prospect, _ text: String) -> Void
    let logTrip: (_ start: String, _ end: String, _ date: Date) -> Void

    // Control
    var onClose: () -> Void

    // State
    @State private var stepSequence: [KnockStep] = []
    @State private var stepIndex: Int = 0

    @State private var chosenOutcome: KnockOutcome? = nil
    @State private var workingProspect: Prospect? = nil

    // Objection state
    @State private var selectedObjection: Objection? = nil
    @State private var showAddObjection: Bool = false

    // Follow-up state
    @State private var followUpDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now
    @State private var didScheduleFollowUp = false
    @State private var showConfetti = false

    // Note state
    @State private var noteText: String = ""

    // Trip state
    @State private var startAddress: String = ""
    @State private var endAddress: String = ""
    @State private var tripDate: Date = .now

    @StateObject private var tripSearchVM = SearchCompleterViewModel()
    @FocusState private var tripFocusedField: Field?   // uses the same Field enum as your popup
    
    private var currentStep: KnockStep? {
        stepSequence.indices.contains(stepIndex) ? stepSequence[stepIndex] : nil
    }

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                Text(shortAddress(context.address))
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }

            // Step indicator (optional: clamp index)
            DotStepBar(total: stepSequence.count, index: min(stepIndex, max(0, stepSequence.count - 1)))
                .padding(.bottom, 4)

            // Content for current step
            Group {
                contentForCurrentStep()
            }
            .frame(width: 300, height: 260)
            .clipped()

            // Nav buttons
            HStack {
                let canShowSkip = currentStep.map(canSkip) ?? false
                Button("Skip") { goNext() }
                    .buttonStyle(.bordered)
                    .opacity(canShowSkip ? 1 : 0)   // <- keeps row height identical

                Spacer()

                if currentStep == .done {
                    Button("Finish") { onClose() }.buttonStyle(.borderedProminent)
                } else if isCurrentStepSatisfied(currentStep) {
                    Button("Next") { goNext() }.buttonStyle(.borderedProminent)
                } else {
                    Button("Next") {}.buttonStyle(.borderedProminent).disabled(true)
                }
            }
            .overlay(
                Group { if showConfetti { ConfettiBurstView() } }    // <- add
            )
            
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(radius: 10)
        .frame(width: 340)
        .onAppear { configureSteps() }
        .onAppear {
            chosenOutcome = initialOutcome
            workingProspect = saveKnock(initialOutcome)
            injectRequiredSteps(for: initialOutcome)
            endAddress = context.address                  // <- prefill end
        }
        .sheet(isPresented: $showAddObjection) {
            AddObjectionView()
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private func contentForCurrentStep() -> some View {
        switch currentStep {
        case .some(.outcome):
            EmptyView()
        case .some(.objection):
            objectionStep
        case .some(.scheduleFollowUp):
            followUpStep
        case .some(.convertToCustomer):
            convertStep
        case .some(.note):
            noteStep
        case .some(.trip):
            tripStep
        case .some(.done):
            doneStep
        case .none:
            EmptyView()
        }
    }

    private var outcomeStep: some View {
        VStack(spacing: 10) {
            Text("Select Outcome").font(.subheadline).foregroundColor(.secondary)
            HStack(spacing: 12) {
                quickButton("house.slash.fill", "Not Home") {
                    chosenOutcome = .wasntHome
                    workingProspect = saveKnock(.wasntHome)
                    // proceed immediately
                }
                if !context.isCustomer {
                    quickButton("checkmark.seal.fill", "Sale") {
                        chosenOutcome = .convertedToSale
                        workingProspect = saveKnock(.convertedToSale)
                        // step sequence will inject convert step
                    }
                }
                quickButton("calendar.badge.clock", "Follow-Up") {
                    chosenOutcome = .followUpLater
                    workingProspect = saveKnock(.followUpLater)
                    // step sequence will inject objection + schedule steps
                }
            }
        }
    }

    private var objectionStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title + guidance
            VStack(alignment: .leading, spacing: 4) {
                Text("Add an Objection")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Pick what they said so we can track patterns. You can also add a new one if it’s not listed.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if objectionOptions.isEmpty {
                // Compact empty-state inside the stepper
                VStack(spacing: 8) {
                    Text("No objections yet")
                        .font(.headline)
                    Text("Tap **Add New Objection** to create one, then select it to continue.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button {
                        showAddObjection = true
                    } label: {
                        Label("Add New Objection", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                // Scrollable list stays within fixed height
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(objectionOptions) { obj in
                            Button {
                                selectedObjection = obj
                                incrementObjection(obj)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: selectedObjection == obj ? "largecircle.fill.circle" : "circle")
                                    Text(obj.text)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }

                        Divider().padding(.vertical, 4)

                        Button {
                            showAddObjection = true
                        } label: {
                            Label("Add New Objection", systemImage: "plus")
                                .font(.footnote)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.trailing, 2)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }

    private var followUpStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title + guidance
            VStack(alignment: .leading, spacing: 4) {
                Text("Schedule Follow-Up")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Choose when to return. Tapping **Next** will create the appointment.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            // Quick chips
            HStack(spacing: 8) {
                quickDateChip("Tomorrow", days: 1)
                quickDateChip("+3d", days: 3)
                quickDateChip("+7d", days: 7)
                quickDateChip("Next Month", days: 30)
            }

            // Date/time picker
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                DatePicker(
                    "Follow-up date & time",
                    selection: $followUpDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
            }

            Text("We’ll attach the address and notes automatically.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 2)

            Spacer(minLength: 0)
        }
    }
    
    @ViewBuilder
    private func quickDateChip(_ title: String, days: Int) -> some View {
        Button(title) {
            if let target = Calendar.current.date(byAdding: .day, value: days, to: Date()) {
                // Keep existing time-of-day from current followUpDate
                let comps = Calendar.current.dateComponents([.hour, .minute], from: followUpDate)
                followUpDate = Calendar.current.date(
                    bySettingHour: comps.hour ?? 9,
                    minute: comps.minute ?? 0,
                    second: 0,
                    of: target
                ) ?? target
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private var convertStep: some View {
        VStack(spacing: 8) {
            Text("Convert to Customer").font(.subheadline).foregroundColor(.secondary)
            Button("Open Conversion Form") {
                if let p = workingProspect { convertToCustomer(p) { /* no-op */ } }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var noteStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add Note (optional)").font(.subheadline).foregroundColor(.secondary)
            TextEditor(text: $noteText)
                .frame(minHeight: 100, maxHeight: .infinity)
        }
    }

    private var tripStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title + brief guidance
            VStack(alignment: .leading, spacing: 4) {
                Text("Log Your Trip (optional)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("If you tap **Next**, we’ll save this trip with the details below. Tap **Skip** to continue without saving a trip.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Start address
            TripAddressFieldView(
                iconName: "circle",
                placeholder: "Start address (optional)",
                iconColor: .blue,
                addressText: $startAddress,
                focusedField: $tripFocusedField,
                fieldType: .start,
                searchVM: tripSearchVM
            )

            // End address (pre-filled to the tapped address)
            TripAddressFieldView(
                iconName: "mappin.circle.fill",
                placeholder: "End address (defaults to this home)",
                iconColor: .red,
                addressText: $endAddress,
                focusedField: $tripFocusedField,
                fieldType: .end,
                searchVM: tripSearchVM
            )

            // Date/time
            HStack {
                Image(systemName: "calendar").foregroundColor(.blue)
                DatePicker(
                    "Trip date & time",
                    selection: $tripDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
            }

            // Inline hint so users know what happens
            Text("Press **Next** to save this trip now. **Skip** won’t save a trip.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 2)
        }
    }

    private var doneStep: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 36))
            Text("Knock logged").font(.headline)
        }
    }

    // MARK: - Helpers

    private func canSkip(_ step: KnockStep) -> Bool {
        return step == .note || step == .trip
    }

    private func isCurrentStepSatisfied(_ step: KnockStep?) -> Bool {
        guard let step = step else { return false }
        switch step {
        case .outcome: return true
        case .objection: return selectedObjection != nil
        case .scheduleFollowUp: return true
        case .convertToCustomer: return true
        case .note, .trip, .done: return true
        }
    }

    private func goNext() {
        guard let step = currentStep else { return }

        if step == .scheduleFollowUp, let p = workingProspect {
            saveFollowUp(p, followUpDate)
            didScheduleFollowUp = true                    // <- add
        }
        if step == .note, let p = workingProspect,
           !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addNote(p, noteText)
        }
        if step == .trip {                                // <- add
            // Assume Next means "save the trip"
            let end = endAddress.isEmpty ? context.address : endAddress
            logTrip(startAddress, end, tripDate)

            // Jump to final step and celebrate if a follow-up was scheduled
            stepSequence = [.done]
            stepIndex = 0
            if didScheduleFollowUp {
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    showConfetti = false
                    onClose()                              // auto-close so you can knock the next home
                }
            } else {
                // No follow-up scheduled; still allow manual Finish
            }
            return
        }

        if stepIndex + 1 < stepSequence.count { stepIndex += 1 }
    }

    private func configureSteps() {
        // Base sequence already set: [.outcome, .note, .trip, .done]
        // After choosing outcome, we'll splice required steps in place.
    }

    private func quickButton(_ system: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            injectRequiredStepsIfNeeded()
        }) {
            VStack(spacing: 4) {
                Image(systemName: system).resizable().scaledToFit().frame(width: 26, height: 26)
                Text(label).font(.caption2)
            }
            .frame(width: 74, height: 64)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func injectRequiredStepsIfNeeded() {
        guard let outcome = chosenOutcome else { return }
        // Reset to base tail (keep anything after outcome untouched if user re-clicks)
        stepSequence = [.outcome]

        switch outcome {
        case .wasntHome:
            stepSequence += [.note, .trip, .done]
        case .convertedToSale:
            stepSequence += [.convertToCustomer, .note, .trip, .done]
        case .followUpLater:
            stepSequence += [.objection, .scheduleFollowUp, .note, .trip, .done]
        }
    }
    
    private func injectRequiredSteps(for outcome: KnockOutcome) {
        switch outcome {
        case .wasntHome:
            stepSequence = [.note, .trip, .done]
        case .convertedToSale:
            stepSequence = [.convertToCustomer, .note, .trip, .done]
        case .followUpLater:
            stepSequence = [.objection, .scheduleFollowUp, .note, .trip, .done]
        }
        stepIndex = 0
    }

    private var objectionOptions: [Objection] {
        objections.filter { $0.text != "Converted To Sale" }
                  .sorted { $0.timesHeard > $1.timesHeard }
    }

    private func shortAddress(_ full: String) -> String {
        let parts = full.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        if parts.count >= 2 { return parts[0] + ", " + parts[1] }
        return full
    }
}
