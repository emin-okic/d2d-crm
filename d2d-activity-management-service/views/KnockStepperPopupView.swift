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
    
    @Environment(\.modelContext) private var modelContext
    
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
    var onClose: (_ completed: Bool) -> Void

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
    @State private var suppressNextFollowUpDateFeedback = false

    // Note state
    @State private var noteText: String = ""

    // Trip state
    @State private var startAddress: String = ""
    @State private var endAddress: String = ""
    @State private var tripDate: Date = .now

    @StateObject private var tripSearchVM = SearchCompleterViewModel()
    @FocusState private var tripFocusedField: TripField?
    
    @Query(sort: \Trip.date, order: .forward) private var trips: [Trip]
    
    private var currentStep: KnockStep? {
        stepSequence.indices.contains(stepIndex) ? stepSequence[stepIndex] : nil
    }

    private var popupHeight: CGFloat {
        switch currentStep {
        case .objection:
            374
        case .scheduleFollowUp:
            340
        case .trip:
            380
        default:
            304
        }
    }

    private var contentHeight: CGFloat {
        switch currentStep {
        case .objection:
            244
        case .scheduleFollowUp:
            210
        case .trip:
            250
        default:
            154
        }
    }

    var body: some View {
      VStack(spacing: 8) {                     // was 14
        // Header
        HStack(spacing: 8) {
          Text(shortAddress(context.address))
            .font(.subheadline)               // slightly smaller than .headline
            .lineLimit(1)
            
            Spacer()

            Button {
              KnockingFormHapticsController.shared.lightTap()
              KnockingFormSoundController.shared.playConfirmationSound()
              onClose(false)
            } label: {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(.secondary)
            }
            
        }

        // Step indicator
        DotStepBar(total: stepSequence.count, index: min(stepIndex, max(0, stepSequence.count - 1)))
          .padding(.bottom, 2)                // was 4

        // Content
        Group { contentForCurrentStep() }
          .frame(maxWidth: .infinity)
          .frame(height: contentHeight)
          .clipped()

          // Nav buttons
          HStack {
            let canShowSkip = currentStep.map(canSkip) ?? false
              Button("Skip") {
                  
                  KnockingFormHapticsController.shared.mediumTap()
                  KnockingFormSoundController.shared.playConfirmationSound()
                  
                  goSkip()
                  
              }
              .buttonStyle(.bordered)
              .opacity(canShowSkip ? 1 : 0)

            Spacer()

            if currentStep != .done {
              if isCurrentStepSatisfied(currentStep) {
                  Button("Next") {
                      if currentStep == .scheduleFollowUp {
                          goNext()
                      } else {
                          KnockingFormHapticsController.shared.mediumTap()
                          KnockingFormSoundController.shared.playConfirmationSound()
                          goNext()
                      }
                  }
                  .buttonStyle(.borderedProminent)
              } else {
                Button("Next") {}.buttonStyle(.borderedProminent).disabled(true)
              }
            }
          }
      }
      .padding(.horizontal, 18)
      .padding(.top, 12)
      .padding(.bottom, 14)
      .frame(maxWidth: .infinity)
      .frame(height: popupHeight, alignment: .top)
      .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
      .overlay(
          RoundedRectangle(cornerRadius: 18, style: .continuous)
              .stroke(Color.primary.opacity(0.10), lineWidth: 1)
      )
      .onAppear { configureSteps() }
      .onAppear {
        chosenOutcome = initialOutcome
        injectRequiredSteps(for: initialOutcome)
        endAddress = context.address
      }
      .sheet(isPresented: $showAddObjection) { AddObjectionView() }
    }
    
    private func goSkip() {
      guard let step = currentStep else { return }

      if step == .trip {
        _ = committedWorkingProspect()
        closeAfterCompletion()
        return
      }

      if stepIndex + 1 < stepSequence.count { stepIndex += 1 }
    }
    
    private func closeAfterCompletion() {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        onClose(true)
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
                }
                if !context.isCustomer {
                    quickButton("checkmark.seal.fill", "Sale") {
                        chosenOutcome = .convertedToSale
                    }
                }
                quickButton("calendar.badge.clock", "Follow-Up") {
                    chosenOutcome = .followUpLater
                }
            }
        }
    }

    private var objectionStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepHeader(
                icon: "questionmark.bubble.fill",
                color: .orange,
                title: "Log Objection",
                subtitle: "Choose the reason that best matches this follow-up."
            )

            if objectionOptions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text("No objections saved")
                        .font(.subheadline.weight(.semibold))

                    Button {
                        KnockingFormHapticsController.shared.lightTap()
                        KnockingFormSoundController.shared.playConfirmationSound()
                        showAddObjection = true
                    } label: {
                        Label("Add Objection", systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.white)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(objectionOptions) { obj in
                            objectionRow(obj)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)

                Button {
                    KnockingFormHapticsController.shared.lightTap()
                    KnockingFormSoundController.shared.playConfirmationSound()
                    showAddObjection = true
                } label: {
                    Label("Add new objection", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
                .background(Color.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private func stepHeader(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
    }

    private func objectionRow(_ objection: Objection) -> some View {
        let isSelected = selectedObjection == objection

        return Button {
            KnockingFormHapticsController.shared.lightTap()
            KnockingFormSoundController.shared.playConfirmationSound()
            selectedObjection = objection
            incrementObjection(objection)
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
                isSelected ? Color.blue.opacity(0.10) : Color(.secondarySystemGroupedBackground).opacity(0.86),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color.blue.opacity(0.55) : Color.primary.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var followUpStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 38, height: 38)
                    .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Schedule Follow-Up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    Text(shortAddress(context.address))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Spacer(minLength: 0)

                Text(followUpDate.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.10), in: Capsule())
            }

            Divider()

            HStack(spacing: 10) {
                Image(systemName: "clock")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.indigo)
                    .frame(width: 32, height: 32)
                    .background(Color.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                DatePicker("Follow-up date", selection: $followUpDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .onChange(of: followUpDate) { _, _ in
                        if suppressNextFollowUpDateFeedback {
                            suppressNextFollowUpDateFeedback = false
                            return
                        }

                        KnockingFormHapticsController.shared.lightTap()
                        KnockingFormSoundController.shared.playConfirmationSound()
                    }
            }

            HStack(spacing: 8) {
                quickDateChip("Tomorrow", days: 1)
                quickDateChip("Next Week", days: 7)
                quickDateChip("30 Days", days: 30)
            }

            Text("Next books the follow-up and prepares a note.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 2)
    }

    @ViewBuilder
    private func quickDateChip(_ title: String, days: Int) -> some View {
        Button {
            KnockingFormHapticsController.shared.lightTap()
            KnockingFormSoundController.shared.playConfirmationSound()
            suppressNextFollowUpDateFeedback = true
            setFollowUpQuickDate(days: days)
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

    private func setFollowUpQuickDate(days: Int) {
        guard let target = Calendar.current.date(byAdding: .day, value: days, to: Date()) else { return }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: followUpDate)
        followUpDate = Calendar.current.date(
            bySettingHour: comps.hour ?? 9,
            minute: comps.minute ?? 0,
            second: 0,
            of: target
        ) ?? target
    }

    private var convertStep: some View {
        VStack(spacing: 8) {
            Text("Convert to Customer").font(.subheadline).foregroundColor(.secondary)
            Button("Open Conversion Form") {
                KnockingFormHapticsController.shared.mediumTap()
                KnockingFormSoundController.shared.playConfirmationSound()
                if let p = committedWorkingProspect() { convertToCustomer(p) { /* no-op */ } }
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
        VStack(alignment: .leading, spacing: 14) {
            stepHeader(
                icon: "point.topleft.down.curvedto.point.bottomright.up.fill",
                color: .purple,
                title: "Log Trip",
                subtitle: "Optional mileage tracking for this route. Skip leaves trip history unchanged."
            )

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                tripAddressRow(
                    icon: "circle.fill",
                    iconColor: .blue,
                    placeholder: "Start address",
                    text: $startAddress,
                    field: .start
                )

                tripAddressRow(
                    icon: "mappin.circle.fill",
                    iconColor: .red,
                    placeholder: "End address",
                    text: $endAddress,
                    field: .end
                )

                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.indigo)
                        .frame(width: 32, height: 32)
                        .background(Color.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    DatePicker("Trip date", selection: $tripDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .onChange(of: tripDate) { _, _ in
                            KnockingFormHapticsController.shared.lightTap()
                            KnockingFormSoundController.shared.playConfirmationSound()
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground).opacity(0.86), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private func tripAddressRow(
        icon: String,
        iconColor: Color,
        placeholder: String,
        text: Binding<String>,
        field: TripField
    ) -> some View {
        HStack(spacing: 10) {
            TripAddressAutofillField(
                icon: icon,
                iconColor: iconColor,
                placeholder: placeholder,
                text: text,
                focusedField: $tripFocusedField,
                field: field,
                searchVM: tripSearchVM
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground).opacity(0.86), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
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

        if step == .scheduleFollowUp, let p = committedWorkingProspect() {
            KnockingFormHapticsController.shared.successFeedbackConfirmation()
            KnockingFormSoundController.shared.playConfirmationSound()
            saveFollowUp(p, followUpDate)
            didScheduleFollowUp = true

            noteText = SuggestedFollowUpNoteGenerator.generate(
                prospect: p,
                objection: selectedObjection,
                followUpDate: followUpDate
            )
        }
        
        if step == .note, let p = committedWorkingProspect(),
           !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addNote(p, noteText)
        }
        
        if step == .trip {
          _ = committedWorkingProspect()
          let end = endAddress.isEmpty ? context.address : endAddress

            // Calculate miles before logging
            Task {
                let miles = await TripDistanceHelper.calculateMiles(from: startAddress, to: end)
                logTripWithMiles(start: startAddress, end: end, miles: miles)
            }


          closeAfterCompletion()
          return
        }

        if stepIndex + 1 < stepSequence.count { stepIndex += 1 }
    }

    private func committedWorkingProspect() -> Prospect? {
        if let workingProspect { return workingProspect }
        guard let chosenOutcome else { return nil }

        let prospect = saveKnock(chosenOutcome)
        workingProspect = prospect
        return prospect
    }

    private func configureSteps() {
        // Base sequence already set: [.outcome, .note, .trip]
        // After choosing outcome, we'll splice required steps in place.
    }
    
    private func logTripWithMiles(start: String, end: String, miles: Double) {
        logTrip(start, end, tripDate)  // pass the tripDate here, as logTrip expects start, end, date
        // override the trip miles after CoreData insertion
        Task { @MainActor in
            if let lastTrip = trips.last {
                lastTrip.miles = miles
                try? modelContext.save()
            }
        }
    }

    private func quickButton(_ system: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: {
            KnockingFormHapticsController.shared.lightTap()
            KnockingFormSoundController.shared.playConfirmationSound()
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
            stepSequence += [.note, .trip]
            
        case .convertedToSale:
            stepSequence += [.convertToCustomer, .note, .trip]
            
        case .followUpLater:
            stepSequence += [.objection, .scheduleFollowUp, .note, .trip]
            
        case .unqualified:
            stepSequence += [.note, .trip]
            
        }
    }
    
    private func injectRequiredSteps(for outcome: KnockOutcome) {
        
        switch outcome {
            
        case .wasntHome:
            stepSequence = [.note, .trip]
            
        case .convertedToSale:
            stepSequence = [.convertToCustomer, .note, .trip]
            
        case .followUpLater:
            stepSequence = [.objection, .scheduleFollowUp, .note, .trip]
            
        case .unqualified:
            stepSequence = [.note, .trip]
            
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

enum TripField: Hashable {
    case start
    case end
}
