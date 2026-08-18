//
//  ContactSearchFilter.swift
//  d2d-studio
//

import Foundation

enum ContactSearchField: String, CaseIterable, Identifiable {
    case all
    case name
    case address
    case phone
    case email
    case ageRange
    case gender
    case raceEthnicity
    case primaryLanguage
    case householdType
    case homeownership
    case companyName
    case jobTitle
    case industry
    case notes

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All Fields"
        case .name: return "Name"
        case .address: return "Address"
        case .phone: return "Phone"
        case .email: return "Email"
        case .ageRange: return "Age Range"
        case .gender: return "Gender"
        case .raceEthnicity: return "Race/Ethnicity"
        case .primaryLanguage: return "Language"
        case .householdType: return "Household"
        case .homeownership: return "Homeownership"
        case .companyName: return "Company"
        case .jobTitle: return "Job Title"
        case .industry: return "Industry"
        case .notes: return "Notes"
        }
    }

    var systemImage: String {
        switch self {
        case .all: return "line.3.horizontal.decrease.circle"
        case .name: return "person.text.rectangle"
        case .address: return "mappin.and.ellipse"
        case .phone: return "phone"
        case .email: return "envelope"
        case .ageRange: return "calendar"
        case .gender: return "person.crop.circle"
        case .raceEthnicity: return "person.2"
        case .primaryLanguage: return "text.bubble"
        case .householdType: return "house"
        case .homeownership: return "key"
        case .companyName: return "building.2"
        case .jobTitle: return "person.crop.rectangle.badge.plus"
        case .industry: return "briefcase"
        case .notes: return "note.text"
        }
    }
}

struct ContactSearchFilter: Equatable {
    var field: ContactSearchField
    var query: String

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isEmpty: Bool {
        trimmedQuery.isEmpty
    }

    var displayText: String {
        "\(field.label): \(trimmedQuery)"
    }
}

extension ContactProtocol {
    func matches(_ filter: ContactSearchFilter) -> Bool {
        let query = filter.trimmedQuery
        guard !query.isEmpty else { return true }

        switch filter.field {
        case .all:
            return fullName.localizedCaseInsensitiveContains(query) ||
                address.localizedCaseInsensitiveContains(query) ||
                contactPhone.localizedCaseInsensitiveContains(query) ||
                contactEmail.localizedCaseInsensitiveContains(query) ||
                demographicsSearchText.localizedCaseInsensitiveContains(query)
        case .name:
            return fullName.localizedCaseInsensitiveContains(query)
        case .address:
            return address.localizedCaseInsensitiveContains(query)
        case .phone:
            return contactPhone.localizedCaseInsensitiveContains(query)
        case .email:
            return contactEmail.localizedCaseInsensitiveContains(query)
        case .ageRange:
            return (demographicAgeRange ?? "").localizedCaseInsensitiveContains(query)
        case .gender:
            return (demographicGender ?? "").localizedCaseInsensitiveContains(query)
        case .raceEthnicity:
            return (demographicRaceEthnicity ?? "").localizedCaseInsensitiveContains(query)
        case .primaryLanguage:
            return (demographicPrimaryLanguage ?? "").localizedCaseInsensitiveContains(query)
        case .householdType:
            return (demographicHouseholdType ?? "").localizedCaseInsensitiveContains(query)
        case .homeownership:
            return (demographicHomeownership ?? "").localizedCaseInsensitiveContains(query)
        case .companyName:
            return (demographicCompanyName ?? "").localizedCaseInsensitiveContains(query)
        case .jobTitle:
            return (demographicJobTitle ?? "").localizedCaseInsensitiveContains(query)
        case .industry:
            return (demographicIndustry ?? "").localizedCaseInsensitiveContains(query)
        case .notes:
            return (demographicNotes ?? "").localizedCaseInsensitiveContains(query)
        }
    }
}
