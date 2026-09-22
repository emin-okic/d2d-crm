import Foundation

enum SalesforceEnvironment: String, CaseIterable, Identifiable, Codable {
    case production
    case sandbox
    case developer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .production: "Production"
        case .sandbox: "Sandbox"
        case .developer: "Developer Edition / My Domain"
        }
    }

    func loginURL(customDomain: String) throws -> URL {
        switch self {
        case .production:
            return URL(string: "https://login.salesforce.com")!
        case .sandbox:
            return URL(string: "https://test.salesforce.com")!
        case .developer:
            let trimmed = customDomain.trimmingCharacters(in: .whitespacesAndNewlines)
            let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
            guard let components = URLComponents(string: candidate),
                  components.scheme?.lowercased() == "https",
                  components.user == nil,
                  components.password == nil,
                  let host = components.host?.lowercased(),
                  host == "salesforce.com" || host.hasSuffix(".salesforce.com") else {
                throw SalesforceClientError.invalidLoginDomain
            }
            var normalized = URLComponents()
            normalized.scheme = "https"
            normalized.host = host
            guard let url = normalized.url else { throw SalesforceClientError.invalidLoginDomain }
            return url
        }
    }
}

enum SalesforceObjectType: String, CaseIterable, Identifiable, Codable {
    case lead = "Lead"
    case contact = "Contact"

    var id: String { rawValue }
}

enum SalesforceSourceField: String, CaseIterable, Identifiable, Codable {
    case fullName
    case firstName
    case lastName
    case address
    case email
    case phone
    case knockCount
    case latitude
    case longitude
    case company
    case jobTitle
    case industry
    case notes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fullName: "Full name"
        case .firstName: "First name"
        case .lastName: "Last name"
        case .address: "Address"
        case .email: "Email"
        case .phone: "Phone"
        case .knockCount: "Knock count"
        case .latitude: "Latitude"
        case .longitude: "Longitude"
        case .company: "Company"
        case .jobTitle: "Job title"
        case .industry: "Industry"
        case .notes: "Demographic notes"
        }
    }
}

struct SalesforceExportRecord: Identifiable, Sendable {
    let id: UUID
    let values: [SalesforceSourceField: String]

    func value(for field: SalesforceSourceField) -> String? {
        let value = values[field]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }
}

struct SalesforceField: Identifiable, Hashable, Codable, Sendable {
    let name: String
    let label: String
    let type: String
    let isRequired: Bool

    var id: String { name }
}

struct SalesforceFieldMapping: Identifiable, Hashable, Codable {
    var source: SalesforceSourceField
    var destinationName: String?

    var id: SalesforceSourceField { source }
}

struct SalesforceExportResult: Sendable {
    let succeeded: Int
    let failedMessages: [String]
}

enum SalesforceExportModelFactory {
    static func prospects(_ prospects: [Prospect]) -> [SalesforceExportRecord] {
        prospects.map {
            record(
                id: $0.uuid,
                fullName: $0.fullName,
                address: $0.address,
                email: $0.contactEmail,
                phone: $0.contactPhone,
                knockCount: $0.knockCount,
                latitude: $0.latitude,
                longitude: $0.longitude,
                company: $0.demographicCompanyName,
                jobTitle: $0.demographicJobTitle,
                industry: $0.demographicIndustry,
                notes: $0.demographicNotes
            )
        }
    }

    static func customers(_ customers: [Customer]) -> [SalesforceExportRecord] {
        customers.map {
            record(
                id: $0.uuid,
                fullName: $0.fullName,
                address: $0.address,
                email: $0.contactEmail,
                phone: $0.contactPhone,
                knockCount: $0.knockCount,
                latitude: $0.latitude,
                longitude: $0.longitude,
                company: $0.demographicCompanyName,
                jobTitle: $0.demographicJobTitle,
                industry: $0.demographicIndustry,
                notes: $0.demographicNotes
            )
        }
    }

    private static func record(
        id: UUID,
        fullName: String,
        address: String,
        email: String,
        phone: String,
        knockCount: Int,
        latitude: Double?,
        longitude: Double?,
        company: String?,
        jobTitle: String?,
        industry: String?,
        notes: String?
    ) -> SalesforceExportRecord {
        let name = split(fullName)
        var values: [SalesforceSourceField: String] = [
            .fullName: fullName,
            .firstName: name.first,
            .lastName: name.last,
            .address: address,
            .email: email,
            .phone: phone,
            .knockCount: String(knockCount)
        ]
        values[.latitude] = latitude.map { String($0) }
        values[.longitude] = longitude.map { String($0) }
        values[.company] = company
        values[.jobTitle] = jobTitle
        values[.industry] = industry
        values[.notes] = notes
        return SalesforceExportRecord(id: id, values: values)
    }

    private static func split(_ fullName: String) -> (first: String, last: String) {
        let parts = fullName.split(whereSeparator: \.isWhitespace).map(String.init)
        guard let first = parts.first else { return ("", "Unknown") }
        guard parts.count > 1 else { return ("", first) }
        return (first, parts.dropFirst().joined(separator: " "))
    }
}
