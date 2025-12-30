//
//  ProspectSearchResultsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/30/25.
//
import SwiftUI
import SwiftData

struct ProspectSearchResultsView: View {
    let searchText: String
    @Binding var selectedProspect: Prospect?

    @Query private var prospects: [Prospect]

    private var results: [Prospect] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        return prospects.filter {
            $0.fullName.localizedCaseInsensitiveContains(q) ||
            $0.address.localizedCaseInsensitiveContains(q) ||
            $0.contactPhone.localizedCaseInsensitiveContains(q) ||
            $0.contactEmail.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        List(results) { prospect in
            ProspectRowView(prospect: prospect)
                .onTapGesture {
                    selectedProspect = prospect
                }
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
}
