//
//  ProspectRankingController.swift
//  d2d-studio
//
//  Created by Codex on 8/29/26.
//

import Foundation

struct ProspectRankingController {
    private struct DemographicSignal {
        let customerKeyPath: KeyPath<Customer, String?>
        let prospectKeyPath: KeyPath<Prospect, String?>
        let weight: Double
    }

    private let valueScoresByField: [[String: Double]]

    private static var signals: [DemographicSignal] {
        [
            DemographicSignal(customerKeyPath: \Customer.demographicHomeownership, prospectKeyPath: \Prospect.demographicHomeownership, weight: 4.0),
            DemographicSignal(customerKeyPath: \Customer.demographicHouseholdType, prospectKeyPath: \Prospect.demographicHouseholdType, weight: 3.0),
            DemographicSignal(customerKeyPath: \Customer.demographicIndustry, prospectKeyPath: \Prospect.demographicIndustry, weight: 3.0),
            DemographicSignal(customerKeyPath: \Customer.demographicAgeRange, prospectKeyPath: \Prospect.demographicAgeRange, weight: 2.0),
            DemographicSignal(customerKeyPath: \Customer.demographicPrimaryLanguage, prospectKeyPath: \Prospect.demographicPrimaryLanguage, weight: 2.0),
            DemographicSignal(customerKeyPath: \Customer.demographicGender, prospectKeyPath: \Prospect.demographicGender, weight: 1.5),
            DemographicSignal(customerKeyPath: \Customer.demographicRaceEthnicity, prospectKeyPath: \Prospect.demographicRaceEthnicity, weight: 1.5),
            DemographicSignal(customerKeyPath: \Customer.demographicJobTitle, prospectKeyPath: \Prospect.demographicJobTitle, weight: 1.0),
            DemographicSignal(customerKeyPath: \Customer.demographicCompanyName, prospectKeyPath: \Prospect.demographicCompanyName, weight: 1.0)
        ]
    }

    init(customers: [Customer]) {
        valueScoresByField = Self.signals.map { signal in
            let values = customers.compactMap { Self.normalizedValue($0[keyPath: signal.customerKeyPath]) }
            guard !values.isEmpty else { return [:] }

            let counts = Dictionary(values.map { ($0, 1) }, uniquingKeysWith: +)
            let total = Double(values.count)

            return counts.mapValues { count in
                signal.weight * (Double(count) / total)
            }
        }
    }

    var hasCustomerSignals: Bool {
        valueScoresByField.contains { !$0.isEmpty }
    }

    func score(for prospect: Prospect) -> Double {
        Self.signals.enumerated().reduce(0) { partialScore, indexedSignal in
            let (index, signal) = indexedSignal
            guard let value = Self.normalizedValue(prospect[keyPath: signal.prospectKeyPath]) else {
                return partialScore
            }

            return partialScore + (valueScoresByField[index][value] ?? 0)
        }
    }

    func rankedProspects(_ prospects: [Prospect]) -> [Prospect] {
        prospects.sorted { lhs, rhs in
            let lhsScore = score(for: lhs)
            let rhsScore = score(for: rhs)

            if lhsScore != rhsScore {
                return lhsScore > rhsScore
            }

            if lhs.orderIndex != rhs.orderIndex {
                return lhs.orderIndex < rhs.orderIndex
            }

            return lhs.fullName.localizedCaseInsensitiveCompare(rhs.fullName) == .orderedAscending
        }
    }

    private static func normalizedValue(_ rawValue: String?) -> String? {
        let trimmed = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return nil }

        let normalized = trimmed.lowercased()
        let ignoredValues = ["unknown", "other", "prefer not to say"]
        guard !ignoredValues.contains(normalized) else { return nil }

        return normalized
    }
}
