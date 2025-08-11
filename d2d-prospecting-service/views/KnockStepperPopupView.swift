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
    @State private var stepSequence: [KnockStep] = [.outcome, .note, .trip, .done]
    @State private var stepIndex: Int = 0

    @State private var chosenOutcome: KnockOutcome? = nil
    @State private var workingProspect: Prospect? = nil

    // Objection state
    @State private var selectedObjection: Objection? = nil
    @State private var showAddObjection: Bool = false

    // Follow-up state
    @State private var followUpDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now

    // Note state
    @State private var noteText: String = ""

    // Trip state
    @State private var startAddress: String = ""

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

            // Step indicator
            DotStepBar(total: stepSequence.count, index: stepIndex)
                .padding(.bottom, 4)

            // Content for current step
            Group { contentForCurrentStep() }
                .frame(maxWidth: 300)

            // Nav buttons
            HStack {
                if canSkip(stepSequence[stepIndex]) {
                    Button("Skip") { goNext() }
                        .buttonStyle(.bordered)
                }

                Spacer()

                if stepSequence[stepIndex] == .done {
                    Button("Finish") { onClose() }
                        .buttonStyle(.borderedProminent)
                } else if isCurrentStepSatisfied() {
                    Button("Next") { goNext() }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("Next") {}
                        .buttonStyle(.borderedProminent)
                        .disabled(true)
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(radius: 10)
        .onAppear { configureSteps() }
        .sheet(isPresented: $showAddObjection) {
            AddObjectionView()
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private func contentForCurrentStep() -> some View {
        switch stepSequence[stepIndex] {
        case .outcome:
            outcomeStep
        case .objection:
            objectionStep
        case .scheduleFollowUp:
            followUpStep
        case .convertToCustomer:
            convertStep
        case .note:
            noteStep
        case .trip:
            tripStep
        case .done:
            doneStep
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
            Text("Why not interested?").font(.subheadline).foregroundColor(.secondary)
            if objectionOptions.isEmpty {
                VStack(spacing: 8) {
                    Text("No objections yet.")
                    Button("Add Objection") { showAddObjection = true }
                }
            } else {
                ScrollView { LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(objectionOptions) { obj in
                        Button {
                            selectedObjection = obj
                            incrementObjection(obj)
                        } label: {
                            HStack {
                                Image(systemName: selectedObjection == obj ? "largecircle.fill.circle" : "circle")
                                Text(obj.text)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }}
            }
        }
    }

    private var followUpStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schedule Follow-Up").font(.subheadline).foregroundColor(.secondary)
            DatePicker("Date", selection: $followUpDate, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
        }
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
            TextEditor(text: $noteText).frame(minHeight: 80)
            HStack { Spacer()
                Button("Save Note") {
                    if let p = workingProspect, !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        addNote(p, noteText)
                        noteText = ""
                    }
                }.buttonStyle(.bordered)
            }
        }
    }

    private var tripStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Log Trip (optional)").font(.subheadline).foregroundColor(.secondary)
            TextField("Start Address", text: $startAddress)
                .textFieldStyle(.roundedBorder)
            HStack { Spacer()
                Button("Save Trip") {
                    if let p = workingProspect {
                        logTrip(startAddress, context.address, .now)
                        startAddress = ""
                    }
                }.buttonStyle(.bordered)
            }
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

    private func isCurrentStepSatisfied() -> Bool {
        switch stepSequence[stepIndex] {
        case .outcome:
            return chosenOutcome != nil
        case .objection:
            return selectedObjection != nil
        case .scheduleFollowUp:
            return true
        case .convertToCustomer:
            // We don't know when the form is completed; allow Next to keep moving
            return true
        case .note, .trip, .done:
            return true
        }
    }

    private func goNext() {
        let current = stepSequence[stepIndex]
        if current == .scheduleFollowUp, let p = workingProspect {
            saveFollowUp(p, followUpDate)
        }
        if stepIndex + 1 < stepSequence.count {
            stepIndex += 1
        }
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
