//
//  ProspectsSectionView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/25/25.
//

import SwiftUI
import SwiftData

struct ProspectsSectionView: View {
    @Query private var allProspects: [Prospect]

    @Binding var selectedList: String
    @State private var selectedProspect: Prospect?

    // From parent
    let containerHeight: CGFloat
    
    @Binding var searchText: String
    
    @Binding var isSearchExpanded: Bool
    @FocusState<Bool>.Binding var isSearchFocused: Bool

    private let rowHeight: CGFloat = 88

    private var filtered: [Prospect] {
        let base = allProspects
            .filter { $0.list == selectedList }

        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            return base.sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
        }

        // Match name, address, phone, email (case-insensitive)
        let matches: (Prospect) -> Bool = { p in
            p.fullName.localizedCaseInsensitiveContains(q) ||
            p.address.localizedCaseInsensitiveContains(q) ||
            p.contactPhone.localizedCaseInsensitiveContains(q) ||
            p.contactEmail.localizedCaseInsensitiveContains(q)
        }

        return base.filter(matches)
            .sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
    }

    var body: some View {
        let tableAreaHeight = max(containerHeight, rowHeight * 2)

        ZStack(alignment: .top) {
            if !filtered.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { p in
                            Button { selectedProspect = p } label: {
                                ProspectRowView(prospect: p)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .padding(.leading, 15)
                                .padding(.vertical, 10)
                        }
                    }
                    .padding(.top, 0)                        // flush to top when results exist
                    .transaction { $0.disablesAnimations = true }
                    .contentTransition(.identity)
                }
                .scrollIndicators(.automatic)
            } else {
                // Empty state — “No matches” if searching, otherwise “No Prospects/Customers”
                Text(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                     ? "No \(selectedList)"
                     : "No matches")
                    .font(.title3).fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: tableAreaHeight)
        .sheet(item: $selectedProspect) { p in
            NavigationStack {
                ProspectDetailsView(prospect: p)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onChange(of: selectedProspect) { newValue in
            guard newValue != nil else { return }

            DispatchQueue.main.async {
                withAnimation {
                    isSearchExpanded = false
                    isSearchFocused = false
                }

                // Clear after collapse so the sheet wins the tap
                searchText = ""
            }
        }
    }
}
