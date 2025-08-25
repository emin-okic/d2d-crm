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

    let containerHeight: CGFloat

    private var filtered: [Prospect] {
        allProspects
            .filter { $0.list == selectedList }
            .sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
    }

    private let rowHeight: CGFloat = 88

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
                    // ✅ remove top padding when we have contacts
                    .padding(.top, 0)
                    .transaction { $0.disablesAnimations = true }
                    .contentTransition(.identity)
                }
                .scrollIndicators(.automatic)
            } else {
                // ✅ keep "no records" padded down for clarity
                Text("No \(selectedList)")
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
    }
}
