//
//  DemographicsEditorView.swift
//  d2d-studio
//
//  Created by Codex on 8/14/26.
//

import SwiftUI

struct DemographicsFormData: Equatable {
    var ageRange: String
    var gender: String
    var raceEthnicity: String
    var primaryLanguage: String
    var householdType: String
    var homeownership: String
    var notes: String
}

struct DemographicsEditorView: View {
    let title: String
    let initialData: DemographicsFormData
    let onSave: (DemographicsFormData) -> Void
    let onCancel: () -> Void

    @State private var stepIndex = 0
    @State private var ageRange: String
    @State private var gender: String
    @State private var raceEthnicity: String
    @State private var primaryLanguage: String
    @State private var householdType: String
    @State private var homeownership: String

    private let totalSteps = 2
    private let ageOptions = ["", "18-24", "25-34", "35-44", "45-54", "55-64", "65+"]
    private let genderOptions = ["", "Female", "Male", "Nonbinary", "Prefer not to say"]
    private let ethnicityOptions = ["", "Asian", "Black", "Hispanic / Latino", "Middle Eastern", "Native American", "Pacific Islander", "White", "Multiracial", "Other", "Prefer not to say"]
    private let languageOptions = ["", "English", "Spanish", "Arabic", "Chinese", "French", "Hindi", "Korean", "Portuguese", "Vietnamese", "Other"]
    private let householdOptions = ["", "Single", "Couple", "Family with kids", "Multigenerational", "Roommates", "Other"]
    private let homeownershipOptions = ["", "Owner", "Renter", "Unknown"]

    init(
        title: String,
        initialData: DemographicsFormData,
        onSave: @escaping (DemographicsFormData) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.initialData = initialData
        self.onSave = onSave
        self.onCancel = onCancel

        _ageRange = State(initialValue: initialData.ageRange)
        _gender = State(initialValue: initialData.gender)
        _raceEthnicity = State(initialValue: initialData.raceEthnicity)
        _primaryLanguage = State(initialValue: initialData.primaryLanguage)
        _householdType = State(initialValue: initialData.householdType)
        _homeownership = State(initialValue: initialData.homeownership)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

            DotStepBar(total: totalSteps, index: stepIndex)
                .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    currentStep
                }
                .padding()
            }

            Divider()

            footerActions
                .padding()
                .background(.ultraThinMaterial)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(stepTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(8)
                    .background(Circle().fill(Color.secondary.opacity(0.15)))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var currentStep: some View {
        switch stepIndex {
        case 0:
            optionCard(title: "Identity") {
                optionPicker("Age Range", selection: $ageRange, options: ageOptions)
                optionPicker("Gender", selection: $gender, options: genderOptions)
                optionPicker("Race / Ethnicity", selection: $raceEthnicity, options: ethnicityOptions)
            }
        default:
            optionCard(title: "Household") {
                optionPicker("Primary Language", selection: $primaryLanguage, options: languageOptions)
                optionPicker("Household Type", selection: $householdType, options: householdOptions)
                optionPicker("Homeownership", selection: $homeownership, options: homeownershipOptions)
            }
        }
    }

    private var footerActions: some View {
        HStack {
            if stepIndex > 0 {
                Button("Back") {
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    stepIndex -= 1
                }
            }

            Spacer()

            if stepIndex < totalSteps - 1 {
                Button("Next") {
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    stepIndex += 1
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Save") {
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    onSave(currentData)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var currentData: DemographicsFormData {
        DemographicsFormData(
            ageRange: ageRange,
            gender: gender,
            raceEthnicity: raceEthnicity,
            primaryLanguage: primaryLanguage,
            householdType: householdType,
            homeownership: homeownership,
            notes: initialData.notes
        )
    }

    private var stepTitle: String {
        switch stepIndex {
        case 0: "Step 1 of 2"
        default: "Step 2 of 2"
        }
    }

    private func optionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        )
    }

    private func optionPicker(_ title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker(title, selection: selection) {
                Text("Not Set").tag("")
                ForEach(options.filter { !$0.isEmpty }, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
            )
        }
    }
}

struct DemographicsSummaryRow: View {
    let summary: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "person.text.rectangle.fill")
                    .font(.title3)
                    .foregroundStyle(.indigo)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Demographics")
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(summary.isEmpty ? "Add age, gender, culture, language, and household info" : summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
