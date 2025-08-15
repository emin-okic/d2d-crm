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
      VStack(spacing: 8) {                     // was 14
        // Header
        HStack(spacing: 8) {
          Text(shortAddress(context.address))
            .font(.subheadline)               // slightly smaller than .headline
            .lineLimit(1)
          Spacer()
          Button(action: onClose) {
            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
          }
        }

        // Step indicator
        DotStepBar(total: stepSequence.count, index: min(stepIndex, max(0, stepSequence.count - 1)))
          .padding(.bottom, 2)                // was 4

        // Content
        Group { contentForCurrentStep() }
          .frame(width: 256, height: 160)     // tight content box inside 280 card
          .clipped()

          // Nav buttons
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
          .overlay(Group { if showConfetti { ConfettiBurstView() } })
      }
      .padding(8)                              // was 14
      .background(.ultraThinMaterial)
      .cornerRadius(14)                        // slightly smaller
      .shadow(radius: 6)                       // lighter shadow
      .frame(width: 280, height: 280)          // ⬅️ hard clamp
      .onAppear { configureSteps() }
      .onAppear {
        chosenOutcome = initialOutcome
        workingProspect = saveKnock(initialOutcome)
        injectRequiredSteps(for: initialOutcome)
        endAddress = context.address
      }
      .sheet(isPresented: $showAddObjection) { AddObjectionView() }
    }
    
    private func goSkip() {
      guard let step = currentStep else { return }

      if step == .trip {
        // no trip save here
        stepSequence = [.done]
        stepIndex = 0

        if didScheduleFollowUp {
          showConfetti = true
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showConfetti = false
            onClose()
          }
        } else {
          closeAfterDone()
        }
        return
      }

      if stepIndex + 1 < stepSequence.count { stepIndex += 1 }
    }
    
    private func closeAfterDone() {
      // brief peek at the finished screen
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
        onClose()
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
      VStack(alignment: .leading, spacing: 6) {
        Text("Add an Objection")
          .font(.footnote).foregroundColor(.secondary)
        Text("Pick what they said. Add a new one if it’s not listed.")
          .font(.caption2).foregroundColor(.secondary)

        if objectionOptions.isEmpty {
          VStack(spacing: 6) {
            Text("No objections yet").font(.subheadline)
            Text("Tap **Add New Objection**, then select it to continue.")
              .font(.caption2).foregroundColor(.secondary).multilineTextAlignment(.center)
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
          } // ← no .frame(maxHeight: .infinity)
        }
      }
    }

    private var followUpStep: some View {
      VStack(alignment: .leading, spacing: 6) {
        Text("Schedule Follow-Up").font(.footnote).foregroundColor(.secondary)
              .padding(5)
        Text("Choose when to return. **Next** will create the appointment.")
          .font(.caption2).foregroundColor(.secondary)
          .padding(5)

        HStack(spacing: 6) {
          quickDateChip("+1d", days: 1)
          quickDateChip("+7d", days: 7)
          quickDateChip("+30d", days: 30)
        }
        .padding(5)

        HStack(spacing: 6) {
          Image(systemName: "calendar").foregroundColor(.blue)
          DatePicker("", selection: $followUpDate, displayedComponents: [.date, .hourAndMinute])
            .labelsHidden()
        }
        .padding(5)
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
      VStack(alignment: .leading, spacing: 6) {
        Text("Log Your Trip (optional)").font(.footnote).foregroundColor(.secondary)
        Text("**Next** saves this trip. **Skip** won’t save it.")
          .font(.caption2).foregroundColor(.secondary)

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
    
    private func buildDefaultFollowUpNote(for prospect: Prospect,
                                          objection: Objection?,
                                          followUpDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a 'on' EEEE MMMM d, yyyy"
        let dateString = formatter.string(from: followUpDate)

        let name = prospect.fullName.isEmpty ? "This prospect" : prospect.fullName
        let objText = objection?.text ?? "busy"

        return "\(name) was \(objText.lowercased()) right now. " +
               "There's a follow up set at \(dateString)."
    }

    private func goNext() {
        guard let step = currentStep else { return }

        if step == .scheduleFollowUp, let p = workingProspect {
            saveFollowUp(p, followUpDate)
            didScheduleFollowUp = true
            
            // ⬇️ Pre-fill note step
                if let obj = selectedObjection {
                    noteText = buildDefaultFollowUpNote(for: p,
                                                        objection: obj,
                                                        followUpDate: followUpDate)
                }
            
        }
        if step == .note, let p = workingProspect,
           !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addNote(p, noteText)
        }
        
        if step == .trip {
          let end = endAddress.isEmpty ? context.address : endAddress
          logTrip(startAddress, end, tripDate)   // only on Next

          stepSequence = [.done]
          stepIndex = 0

          if didScheduleFollowUp {
            showConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
              showConfetti = false
              onClose()                          // confetti path: close a bit later
            }
          } else {
            closeAfterDone()                     // quick close when no confetti
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
