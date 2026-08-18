//
//  DemographicsEditorView.swift
//  d2d-studio
//
//  Created by Codex on 8/14/26.
//

import Foundation
import SwiftUI

struct DemographicsFormData: Equatable {
    var ageRange: String
    var gender: String
    var raceEthnicity: String
    var primaryLanguage: String
    var householdType: String
    var homeownership: String
    var companyName: String
    var jobTitle: String
    var industry: String
    var companyDomain: String
    var companyLogoURL: String
    var companyPrimaryColorHex: String
    var companySecondaryColorHex: String
    var notes: String
}

struct DemographicsEditorView: View {
    let title: String
    let initialData: DemographicsFormData
    let onSave: (DemographicsFormData) -> Void
    let onCancel: () -> Void
    var onExpandedContentChange: (Bool) -> Void = { _ in }

    @State private var stepIndex = 0
    @State private var ageRange: String
    @State private var gender: String
    @State private var raceEthnicity: String
    @State private var primaryLanguage: String
    @State private var householdType: String
    @State private var homeownership: String
    @State private var companyName: String
    @State private var jobTitle: String
    @State private var industry: String
    @State private var companyDomain: String
    @State private var companyLogoURL: String
    @State private var companyPrimaryColorHex: String
    @State private var companySecondaryColorHex: String
    @State private var isIndustryExpanded = false
    @State private var companyLookupTask: Task<Void, Never>?
    @State private var completedCompanyFields: Set<CompanyField> = []
    @State private var isApplyingCompanySuggestion = false
    @State private var selectedCompanyName: String
    @StateObject private var companySuggestionService = LogoDevCompanySuggestionService()

    private let totalSteps = 3
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
        onCancel: @escaping () -> Void,
        onExpandedContentChange: @escaping (Bool) -> Void = { _ in }
    ) {
        self.title = title
        self.initialData = initialData
        self.onSave = onSave
        self.onCancel = onCancel
        self.onExpandedContentChange = onExpandedContentChange

        _ageRange = State(initialValue: initialData.ageRange)
        _gender = State(initialValue: initialData.gender)
        _raceEthnicity = State(initialValue: initialData.raceEthnicity)
        _primaryLanguage = State(initialValue: initialData.primaryLanguage)
        _householdType = State(initialValue: initialData.householdType)
        _homeownership = State(initialValue: initialData.homeownership)
        _companyName = State(initialValue: initialData.companyName)
        _jobTitle = State(initialValue: initialData.jobTitle)
        _industry = State(initialValue: initialData.industry)
        _companyDomain = State(initialValue: initialData.companyDomain)
        _companyLogoURL = State(initialValue: initialData.companyLogoURL)
        _companyPrimaryColorHex = State(initialValue: initialData.companyPrimaryColorHex)
        _companySecondaryColorHex = State(initialValue: initialData.companySecondaryColorHex)
        _selectedCompanyName = State(initialValue: initialData.companyLogoURL.isEmpty ? "" : initialData.companyName)
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
            .background(companyStepBackground)
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: stepIndex)
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: isIndustryExpanded)

            Divider()

            footerActions
                .padding()
                .background(.ultraThinMaterial)
        }
        .onChange(of: companyName) { _, newValue in
            if newValue.trimmingCharacters(in: .whitespacesAndNewlines) == selectedCompanyName {
                return
            }

            clearCompanyMetadataIfNeeded(for: newValue)
            scheduleCompanyLookup(for: newValue)
        }
        .onChange(of: stepIndex) { _, newValue in
            if newValue != 2 {
                companySuggestionService.clearSuggestions()
                onExpandedContentChange(false)
            }
        }
        .onDisappear {
            companyLookupTask?.cancel()
            onExpandedContentChange(false)
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
        case 1:
            optionCard(title: "Household") {
                optionPicker("Primary Language", selection: $primaryLanguage, options: languageOptions)
                optionPicker("Household Type", selection: $householdType, options: householdOptions)
                optionPicker("Homeownership", selection: $homeownership, options: homeownershipOptions)
            }
        default:
            optionCard(title: "Company Info") {
                companyBrandHeader
                companyField
                jobTitleField
                industryDropdown
            }
        }
    }

    private var companyBrandHeader: some View {
        VStack(spacing: 10) {
            if let logoURL = URL(string: companyLogoURL), !companyLogoURL.isEmpty {
                AsyncImage(url: logoURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    default:
                        Image(systemName: "building.2.crop.circle")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(brandPrimaryColor)
                    }
                }
                .frame(width: 82, height: 82)
                .padding(12)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: brandPrimaryColor.opacity(0.18), radius: 10, y: 5)
                .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "building.2.crop.circle")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(brandPrimaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }

            if !companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(companyName)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var companyField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Company")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("Company name", text: $companyName)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .onSubmit {
                    markCompleted(.company, value: companyName, force: true)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))

            companySuggestions
        }
    }

    @ViewBuilder
    private var companySuggestions: some View {
        let trimmedCompany = companyName.trimmingCharacters(in: .whitespacesAndNewlines)

        if companySuggestionService.isLoading {
            Label("Looking up companies", systemImage: "sparkle.magnifyingglass")
                .font(.caption)
                .foregroundStyle(.secondary)
                .transition(.opacity)
        } else if !companySuggestionService.suggestions.isEmpty {
            VStack(spacing: 8) {
                ForEach(companySuggestionService.suggestions) { suggestion in
                    Button {
                        applyCompanySuggestion(suggestion)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "building.2")
                                .foregroundStyle(brandPrimaryColor)
                            .frame(width: 28, height: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(suggestion.domain)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(10)
                        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        } else if let message = companySuggestionService.statusMessage, trimmedCompany.count >= 2 {
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 2)
                .transition(.opacity)
        }
    }

    private var jobTitleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Job Title")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("Job title", text: $jobTitle)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .onSubmit {
                    markCompleted(.jobTitle, value: jobTitle, force: true)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))

            if !suggestedJobTitles.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestedJobTitles, id: \.self) { title in
                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                    jobTitle = title
                                }
                                markCompleted(.jobTitle, value: title, force: true)
                            } label: {
                                Text(title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(brandPrimaryColor)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(brandPrimaryColor.opacity(0.12), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .transition(.opacity)
            }
        }
    }

    private var industryDropdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Industry")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                    isIndustryExpanded.toggle()
                    onExpandedContentChange(isIndustryExpanded)
                }
                ContactScreenHapticsController.shared.lightTap()
                ContactScreenSoundController.shared.playSound1()
            } label: {
                HStack {
                    Text(industry.isEmpty ? "Select industry" : industry)
                        .font(.subheadline)
                        .foregroundStyle(industry.isEmpty ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .rotationEffect(.degrees(isIndustryExpanded ? 180 : 0))
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
            }
            .buttonStyle(.plain)

            if isIndustryExpanded {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 8)], spacing: 8) {
                    ForEach(Self.commonIndustries, id: \.self) { option in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                industry = option
                                isIndustryExpanded = false
                                onExpandedContentChange(false)
                            }
                            markCompleted(.industry, value: option, force: true)
                        } label: {
                            Text(option)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(option == industry ? .white : brandPrimaryColor)
                                .lineLimit(2)
                                .minimumScaleFactor(0.82)
                                .frame(maxWidth: .infinity, minHeight: 34)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 9)
                                        .fill(option == industry ? brandPrimaryColor : brandPrimaryColor.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 2)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var footerActions: some View {
        HStack {
            if stepIndex > 0 {
                Button("Back") {
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    closeExpandedContent()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        stepIndex -= 1
                    }
                }
            }

            Spacer()

            if stepIndex < totalSteps - 1 {
                Button("Next") {
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    closeExpandedContent()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        stepIndex += 1
                    }
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
            companyName: companyName,
            jobTitle: jobTitle,
            industry: industry,
            companyDomain: companyDomain,
            companyLogoURL: companyLogoURL,
            companyPrimaryColorHex: companyPrimaryColorHex,
            companySecondaryColorHex: companySecondaryColorHex,
            notes: initialData.notes
        )
    }

    private var stepTitle: String {
        switch stepIndex {
        case 0: "Step 1 of 3"
        case 1: "Step 2 of 3"
        default: "Step 3 of 3"
        }
    }

    private var suggestedJobTitles: [String] {
        let query = jobTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches: [String]

        if query.isEmpty {
            matches = Array(Self.commonJobTitles.prefix(12))
        } else {
            matches = Self.commonJobTitles.filter {
                $0.localizedCaseInsensitiveContains(query)
            }
        }

        return Array(matches.prefix(12))
    }

    private var brandPrimaryColor: Color {
        Color(hex: companyPrimaryColorHex) ?? deterministicBrandColor
    }

    private var brandSecondaryColor: Color {
        Color(hex: companySecondaryColorHex) ?? brandPrimaryColor.opacity(0.18)
    }

    @ViewBuilder
    private var companyStepBackground: some View {
        if stepIndex == 2 {
            LinearGradient(
                colors: [
                    brandSecondaryColor.opacity(0.34),
                    brandPrimaryColor.opacity(0.08),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.clear
        }
    }

    private var deterministicBrandColor: Color {
        let colors: [Color] = [.blue, .teal, .green, .orange, .red, .indigo, .cyan]
        let source = companyName.isEmpty ? "D2D" : companyName
        let index = abs(source.hashValue) % colors.count
        return colors[index]
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

    private func applyCompanySuggestion(_ suggestion: LogoDevCompanySuggestion) {
        isApplyingCompanySuggestion = true
        companyLookupTask?.cancel()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            selectedCompanyName = suggestion.name
            companyName = suggestion.name
            companyDomain = suggestion.domain
            companyLogoURL = suggestion.logoURL
            companyPrimaryColorHex = suggestion.primaryColorHex ?? ""
            companySecondaryColorHex = suggestion.secondaryColorHex ?? ""
            companySuggestionService.clearSuggestions()
        }
        isApplyingCompanySuggestion = false
        onExpandedContentChange(false)
        markCompleted(.company, value: suggestion.name, force: true)
    }

    private func scheduleCompanyLookup(for value: String) {
        companyLookupTask?.cancel()
        let query = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard query.count >= 2 else {
            companySuggestionService.clearSuggestions()
            onExpandedContentChange(false)
            return
        }

        if stepIndex == 2 {
            onExpandedContentChange(true)
        }

        companyLookupTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await companySuggestionService.searchCompanies(matching: query)
        }
    }

    private func clearCompanyMetadataIfNeeded(for value: String) {
        guard !isApplyingCompanySuggestion else { return }
        selectedCompanyName = ""
        companyDomain = ""
        companyLogoURL = ""
        companyPrimaryColorHex = ""
        companySecondaryColorHex = ""
    }

    private func closeExpandedContent() {
        if isIndustryExpanded {
            isIndustryExpanded = false
            onExpandedContentChange(false)
        }
    }

    private func markCompleted(_ field: CompanyField, value: String, force: Bool = false) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard force || !completedCompanyFields.contains(field) else { return }

        completedCompanyFields.insert(field)
        ContactScreenHapticsController.shared.successConfirmationTap()
        ContactScreenSoundController.shared.playSound1()
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
                    Text(summary.isEmpty ? "Add age, gender, culture, language, household, and company info" : summary)
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

private enum CompanyField: Hashable {
    case company
    case jobTitle
    case industry
}

private struct LogoDevCompanySuggestion: Identifiable, Decodable, Equatable {
    let name: String
    let domain: String
    let logoURL: String
    let primaryColorHex: String?
    let secondaryColorHex: String?

    var id: String { domain }

    private enum CodingKeys: String, CodingKey {
        case name
        case domain
        case logoURL = "logo_url"
        case primaryColorHex = "primary_color"
        case secondaryColorHex = "secondary_color"
    }
}

@MainActor
private final class LogoDevCompanySuggestionService: ObservableObject {
    @Published private(set) var suggestions: [LogoDevCompanySuggestion] = []
    @Published private(set) var isLoading = false
    @Published private(set) var statusMessage: String?

    private static let publishableKey = "pk_e2tx2LTbSmS5_hieLIi5Qw"

    func searchCompanies(matching query: String) async {
        guard let request = makeSearchRequest(query: query) else {
            suggestions = []
            statusMessage = "Cannot suggest companies right now. Type the company manually."
            return
        }

        isLoading = true
        statusMessage = nil

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            isLoading = false

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 402 || httpResponse.statusCode == 429 {
                suggestions = []
                statusMessage = "Cannot suggest companies right now. Type the company manually."
                return
            }

            let decoded = try JSONDecoder().decode([LogoDevCompanySuggestion].self, from: data)
            suggestions = Array(decoded.prefix(5))
            statusMessage = suggestions.isEmpty ? "No company suggestions found. Type the company manually." : nil
        } catch {
            isLoading = false
            suggestions = []
            statusMessage = "Cannot suggest companies right now. Type the company manually."
        }
    }

    func clearSuggestions() {
        suggestions = []
        statusMessage = nil
    }

    static func logoURL(forCompanyName name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let encodedName = trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? trimmed
        return "https://img.logo.dev/name/\(encodedName)?token=\(publishableKey)&size=160&retina=true"
    }

    private func makeSearchRequest(query: String) -> URLRequest? {
        if let proxyURL = configuredValue(for: "LogoDevSearchProxyURL"), !proxyURL.isEmpty {
            var components = URLComponents(string: proxyURL)
            components?.queryItems = [URLQueryItem(name: "q", value: query)]
            guard let url = components?.url else { return nil }
            return URLRequest(url: url)
        }

        guard let secretKey = configuredValue(for: "LogoDevSecretKey"), !secretKey.isEmpty else {
            return nil
        }

        var components = URLComponents(string: "https://api.logo.dev/search")
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(secretKey)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func configuredValue(for key: String) -> String? {
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension Color {
    init?(hex: String) {
        let sanitized = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard sanitized.count == 6, let value = Int(sanitized, radix: 16) else {
            return nil
        }

        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}

private extension DemographicsEditorView {
    static let commonIndustries = [
        "Accounting", "Advertising", "Aerospace", "Agriculture", "Architecture", "Automotive",
        "Banking", "Biotechnology", "Construction", "Consulting", "Consumer Goods", "Education",
        "Energy", "Engineering", "Entertainment", "Financial Services", "Food & Beverage",
        "Government", "Healthcare", "Hospitality", "Human Resources", "Insurance", "Legal",
        "Logistics", "Manufacturing", "Marketing", "Media", "Nonprofit", "Pharmaceuticals",
        "Real Estate", "Retail", "Sales", "Software", "Telecommunications", "Transportation",
        "Travel", "Utilities", "Wholesale"
    ]

    static let commonJobTitles = [
        "Account Manager", "Account Executive", "Accountant", "Administrative Assistant",
        "Architect", "Area Manager", "Attorney", "Bank Teller", "Bookkeeper",
        "Branch Manager", "Brand Manager", "Business Analyst", "Business Development Manager",
        "Buyer", "Cashier", "Chief Executive Officer", "Chief Financial Officer",
        "Chief Marketing Officer", "Chief Operating Officer", "Civil Engineer", "Claims Adjuster",
        "Client Success Manager", "Consultant", "Content Manager", "Controller",
        "Customer Service Representative", "Data Analyst", "Data Scientist", "Dental Hygienist",
        "Dentist", "Director of Operations", "Driver", "Electrician", "Engineer",
        "Executive Assistant", "Facilities Manager", "Field Service Technician",
        "Finance Manager", "Financial Advisor", "General Manager", "Graphic Designer",
        "Human Resources Manager", "Insurance Agent", "IT Manager", "Legal Assistant",
        "Loan Officer", "Logistics Coordinator", "Maintenance Technician", "Marketing Coordinator",
        "Marketing Manager", "Mechanic", "Medical Assistant", "Nurse", "Office Manager",
        "Operations Manager", "Paralegal", "Pharmacist", "Physician", "Plumber",
        "Product Manager", "Program Manager", "Project Coordinator", "Project Manager",
        "Property Manager", "Real Estate Agent", "Receptionist", "Recruiter",
        "Registered Nurse", "Restaurant Manager", "Retail Associate", "Sales Associate",
        "Sales Consultant", "Sales Development Representative", "Sales Director",
        "Sales Manager", "Sales Representative", "School Administrator", "Software Developer",
        "Software Engineer", "Store Manager", "Supervisor", "Teacher", "Technician",
        "Truck Driver", "Underwriter", "Warehouse Associate", "Web Developer",
        "Welder", "Writer", "Analyst", "Assistant Manager", "Broker", "Caregiver",
        "Case Manager", "Coordinator", "Designer", "Director", "Estimator", "Installer",
        "Manager", "Owner", "Partner", "President", "Principal", "Producer",
        "Specialist", "Vice President"
    ]
}
