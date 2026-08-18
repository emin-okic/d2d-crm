//
//  ContactProtocol.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/23/25.
//

import Foundation

protocol ContactProtocol: AnyObject {
    var fullName: String { get set }
    var address: String { get set }
    var knockCount: Int { get set }
    var contactEmail: String { get set }
    var contactPhone: String { get set }

    var demographicAgeRange: String? { get set }
    var demographicGender: String? { get set }
    var demographicRaceEthnicity: String? { get set }
    var demographicPrimaryLanguage: String? { get set }
    var demographicHouseholdType: String? { get set }
    var demographicHomeownership: String? { get set }
    var demographicNotes: String? { get set }
    var demographicCompanyName: String? { get set }
    var demographicJobTitle: String? { get set }
    var demographicIndustry: String? { get set }
    var demographicCompanyDomain: String? { get set }
    var demographicCompanyLogoURL: String? { get set }
    var demographicCompanyPrimaryColorHex: String? { get set }
    var demographicCompanySecondaryColorHex: String? { get set }
    
    var notes: [Note] { get set }
    var appointments: [Appointment] { get set }
    var knockHistory: [Knock] { get set }
    var phoneCalls: [PhoneCall] { get set }
}

extension ContactProtocol {
    var sortedKnocks: [Knock] {
        knockHistory.sorted(by: { $0.date > $1.date })
    }
}

extension ContactProtocol {

    var phoneCallCount: Int {
        phoneCalls.count
    }

    var lastPhoneCallDate: Date? {
        phoneCalls
            .sorted(by: { $0.date > $1.date })
            .first?
            .date
    }
}

extension ContactProtocol {
    var demographicsFormData: DemographicsFormData {
        DemographicsFormData(
            ageRange: demographicAgeRange ?? "",
            gender: demographicGender ?? "",
            raceEthnicity: demographicRaceEthnicity ?? "",
            primaryLanguage: demographicPrimaryLanguage ?? "",
            householdType: demographicHouseholdType ?? "",
            homeownership: demographicHomeownership ?? "",
            companyName: demographicCompanyName ?? "",
            jobTitle: demographicJobTitle ?? "",
            industry: demographicIndustry ?? "",
            companyDomain: demographicCompanyDomain ?? "",
            companyLogoURL: demographicCompanyLogoURL ?? "",
            companyPrimaryColorHex: demographicCompanyPrimaryColorHex ?? "",
            companySecondaryColorHex: demographicCompanySecondaryColorHex ?? "",
            notes: demographicNotes ?? ""
        )
    }

    var demographicsSummary: String {
        [
            demographicAgeRange,
            demographicGender,
            demographicRaceEthnicity,
            demographicPrimaryLanguage,
            demographicHouseholdType,
            demographicHomeownership,
            demographicCompanyName,
            demographicJobTitle,
            demographicIndustry
        ]
        .compactMap { value in
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? nil : trimmed
        }
        .joined(separator: " - ")
    }

    var demographicsSearchText: String {
        ([demographicsSummary, demographicCompanyDomain ?? "", demographicNotes ?? ""])
            .joined(separator: " ")
    }

    func applyDemographics(_ data: DemographicsFormData) {
        demographicAgeRange = data.ageRange.nilIfBlank
        demographicGender = data.gender.nilIfBlank
        demographicRaceEthnicity = data.raceEthnicity.nilIfBlank
        demographicPrimaryLanguage = data.primaryLanguage.nilIfBlank
        demographicHouseholdType = data.householdType.nilIfBlank
        demographicHomeownership = data.homeownership.nilIfBlank
        demographicCompanyName = data.companyName.nilIfBlank
        demographicJobTitle = data.jobTitle.nilIfBlank
        demographicIndustry = data.industry.nilIfBlank
        demographicCompanyDomain = data.companyDomain.nilIfBlank
        demographicCompanyLogoURL = data.companyLogoURL.nilIfBlank
        demographicCompanyPrimaryColorHex = data.companyPrimaryColorHex.nilIfBlank
        demographicCompanySecondaryColorHex = data.companySecondaryColorHex.nilIfBlank
        demographicNotes = data.notes.nilIfBlank
    }

    func companyInfoChangeNote(from oldData: DemographicsFormData, to newData: DemographicsFormData) -> String? {
        let changes = [
            companyInfoChange(label: "Company", oldValue: oldData.companyName, newValue: newData.companyName),
            companyInfoChange(label: "Job title", oldValue: oldData.jobTitle, newValue: newData.jobTitle),
            companyInfoChange(label: "Industry", oldValue: oldData.industry, newValue: newData.industry)
        ].compactMap { $0 }

        guard !changes.isEmpty else { return nil }
        return "Updated company info: \(changes.joined(separator: "; "))."
    }

    private func companyInfoChange(label: String, oldValue: String, newValue: String) -> String? {
        let oldTrimmed = oldValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let newTrimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard oldTrimmed != newTrimmed else { return nil }

        if oldTrimmed.isEmpty {
            return "\(label) set to \(newTrimmed)"
        }

        if newTrimmed.isEmpty {
            return "\(label) cleared from \(oldTrimmed)"
        }

        return "\(label) changed from \(oldTrimmed) to \(newTrimmed)"
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
