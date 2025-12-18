//
//  CustomerKnockStepperPopupView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/18/25.
//

import SwiftUI
import MapKit

struct CustomerKnockStepperPopupView: View {
    // Inputs
    let customer: Customer
    let initialOutcome: KnockOutcome = .followUpLater
    
    // Dependencies
    let objections: [Objection]
    let saveKnock: (_ outcome: KnockOutcome) -> Customer
    let incrementObjection: (_ obj: Objection) -> Void
    let saveFollowUp: (_ customer: Customer, _ date: Date) -> Void
    let addNote: (_ customer: Customer, _ text: String) -> Void
    let logTrip: (_ start: String, _ end: String, _ date: Date) -> Void

    // Control
    var onClose: () -> Void

    // State
    @State private var stepSequence: [KnockStep] = []
    @State private var stepIndex: Int = 0
    @State private var chosenOutcome: KnockOutcome? = nil
    @State private var workingCustomer: Customer? = nil

    // Objection state
    @State private var selectedObjection: Objection? = nil
    @State private var showAddObjection: Bool = false

    // Follow-up state
    @State private var followUpDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now
    @State private var didScheduleFollowUp = false

    // Note state
    @State private var noteText: String = ""

    // Trip state
    @State private var startAddress: String = ""
    @State private var endAddress: String = ""
    @State private var tripDate: Date = .now
    @StateObject private var tripSearchVM = SearchCompleterViewModel()
    @FocusState private var tripFocusedField: Field?

    private var currentStep: KnockStep? {
        stepSequence.indices.contains(stepIndex) ? stepSequence[stepIndex] : nil
    }

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text(shortAddress(customer.address))
                    .font(.subheadline)
                    .lineLimit(1)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }

            // Step indicator
            DotStepBar(total: stepSequence.count, index: min(stepIndex, max(0, stepSequence.count - 1)))
                .padding(.bottom, 2)

            // Step content
            Group { contentForCurrentStep() }
                .frame(width: 256, height: 160)
                .clipped()

            // Navigation
            HStack {
                let canShowSkip = currentStep.map(canSkip) ?? false
                Button("Skip") { goSkip() }
                    .buttonStyle(.bordered)
                    .opacity(canShowSkip ? 1 : 0)

                Spacer()

                if currentStep != .done {
                    if isCurrentStepSatisfied(currentStep) {
                        Button("Next") { goNext() }.buttonStyle(.borderedProminent)
                    } else {
                        Button("Next") {}.buttonStyle(.borderedProminent).disabled(true)
                    }
                }
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .shadow(radius: 6)
        .frame(width: 280, height: 280)
        .onAppear {
            chosenOutcome = initialOutcome
            workingCustomer = saveKnock(initialOutcome)
            injectRequiredSteps(for: initialOutcome)
            endAddress = customer.address
        }
        .sheet(isPresented: $showAddObjection) { AddObjectionView() }
    }

    @ViewBuilder
    private func contentForCurrentStep() -> some View {
        switch currentStep {
        case .some(.objection): objectionStep
        case .some(.scheduleFollowUp): followUpStep
        case .some(.note): noteStep
        case .some(.trip): tripStep
        case .some(.done): doneStep
        default: EmptyView()
        }
    }

    private var objectionStep: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Add an Objection")
                .font(.footnote).foregroundColor(.secondary)
            Text("Pick what they said. Add a new one if it’s not listed.")
                .font(.caption2).foregroundColor(.secondary)

            if objectionOptions.isEmpty {
                VStack(spacing: 6) {
                    Text("No objections yet").font(.subheadline)
                    Button { showAddObjection = true } label: { Label("Add New Objection", systemImage: "plus") }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(objectionOptions) { obj in
                            Button {
                                selectedObjection = obj
                                incrementObjection(obj)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: selectedObjection == obj ? "largecircle.fill.circle" : "circle")
                                    Text(obj.text).font(.caption).lineLimit(2)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        Button {
                            showAddObjection = true
                        } label: {
                            Label("Add New Objection", systemImage: "plus").font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
    }

    private var followUpStep: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Schedule Follow-Up").font(.footnote).foregroundColor(.secondary)
            Text("Choose when to return. **Next** will create the appointment.")
                .font(.caption2).foregroundColor(.secondary)

            HStack(spacing: 6) {
                quickDateChip("+1d", days: 1)
                quickDateChip("+7d", days: 7)
                quickDateChip("+30d", days: 30)
            }

            HStack(spacing: 6) {
                Image(systemName: "calendar").foregroundColor(.blue)
                DatePicker("", selection: $followUpDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
            }
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
        VStack(alignment: .leading, spacing: 6) {
            Text("Log Your Trip (optional)").font(.footnote).foregroundColor(.secondary)

            TripAddressFieldView(
                iconName: "circle",
                placeholder: "Start address (optional)",
                iconColor: .blue,
                addressText: $startAddress,
                focusedField: $tripFocusedField,
                fieldType: .start,
                searchVM: tripSearchVM
            )

            TripAddressFieldView(
                iconName: "mappin.circle.fill",
                placeholder: "End address (defaults to this home)",
                iconColor: .red,
                addressText: $endAddress,
                focusedField: $tripFocusedField,
                fieldType: .end,
                searchVM: tripSearchVM
            )

            HStack(spacing: 6) {
                Image(systemName: "calendar").foregroundColor(.blue)
                DatePicker("", selection: $tripDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
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

    private func quickDateChip(_ title: String, days: Int) -> some View {
        Button(title) {
            if let target = Calendar.current.date(byAdding: .day, value: days, to: Date()) {
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

    private func goSkip() {
        if stepIndex + 1 < stepSequence.count { stepIndex += 1 }
    }

    private func goNext() {
        guard let step = currentStep, let c = workingCustomer else { return }

        if step == .scheduleFollowUp {
            saveFollowUp(c, followUpDate)
            didScheduleFollowUp = true
        }

        if step == .note, !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addNote(c, noteText)
        }

        if step == .trip {
            let end = endAddress.isEmpty ? customer.address : endAddress
            logTrip(startAddress, end, tripDate)

            stepSequence = [.done]
            stepIndex = 0

            DispatchQueue.main.asyncAfter(deadline: .now() + (didScheduleFollowUp ? 1.2 : 0.5)) {
                onClose()
            }
            return
        }

        if stepIndex + 1 < stepSequence.count { stepIndex += 1 }
    }

    private func injectRequiredSteps(for outcome: KnockOutcome) {
        switch outcome {
        case .wasntHome:
            stepSequence = [.note, .trip, .done]
        case .convertedToSale:
            stepSequence = [.note, .trip, .done] // customers never convert
        case .followUpLater:
            stepSequence = [.objection, .scheduleFollowUp, .note, .trip, .done]
        }
        stepIndex = 0
    }

    private func isCurrentStepSatisfied(_ step: KnockStep?) -> Bool {
        guard let step = step else { return false }
        switch step {
        case .objection: return selectedObjection != nil
        case .scheduleFollowUp, .note, .trip, .done: return true
        default: return true
        }
    }

    private func canSkip(_ step: KnockStep) -> Bool {
        return step == .note || step == .trip
    }

    private var objectionOptions: [Objection] {
        objections.sorted { $0.timesHeard > $1.timesHeard }
    }

    private func shortAddress(_ full: String) -> String {
        let parts = full.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        if parts.count >= 2 { return parts[0] + ", " + parts[1] }
        return full
    }
}
