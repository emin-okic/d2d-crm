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
            demographicHomeownership
        ]
        .compactMap { value in
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? nil : trimmed
        }
        .joined(separator: " - ")
    }

    var demographicsSearchText: String {
        ([demographicsSummary, demographicNotes ?? ""])
            .joined(separator: " ")
    }

    func applyDemographics(_ data: DemographicsFormData) {
        demographicAgeRange = data.ageRange.nilIfBlank
        demographicGender = data.gender.nilIfBlank
        demographicRaceEthnicity = data.raceEthnicity.nilIfBlank
        demographicPrimaryLanguage = data.primaryLanguage.nilIfBlank
        demographicHouseholdType = data.householdType.nilIfBlank
        demographicHomeownership = data.homeownership.nilIfBlank
        demographicNotes = data.notes.nilIfBlank
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
