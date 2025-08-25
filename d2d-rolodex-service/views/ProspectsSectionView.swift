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

    // NEW: container height coming from the parent
    let containerHeight: CGFloat

    private var filtered: [Prospect] {
        allProspects
            .filter { $0.list == selectedList }
            .sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
    }

    private var subtitle: String {
        let count = filtered.count
        return selectedList == "Prospects" ? "\(count) Prospects" : "\(count) Customers"
    }

    // Row height matches the bigger row
    private let rowHeight: CGFloat = 88

    var body: some View {
        // Estimate how much vertical space header + chips consume
        // (title/subtitle ≈ 60, chips ≈ 44, paddings ≈ 36 → ~140 total)
        let headerAndChips: CGFloat = 140
        let tableAreaHeight = max(containerHeight - headerAndChips, rowHeight * 2)

        VStack(alignment: .leading, spacing: 14) {
            
            // Header (scaled up)
            VStack(spacing: 6) {
                Text(selectedList == "Prospects"
                     ? "Your Prospects"
                     : "Your Customers")
                    .font(.title)                  // strong, like a section header
                    .fontWeight(.bold)

                Text(subtitle)                     // e.g. "23 Prospects" / "5 Customers"
                    .font(.headline)               // bumped for emphasis
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)

            // Toggle chips (slightly larger)
            HStack(spacing: 10) {
                toggleChip("Prospects", isOn: selectedList == "Prospects") { selectedList = "Prospects" }
                toggleChip("Customers", isOn: selectedList == "Customers") { selectedList = "Customers" }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)

            // Fixed-height table area
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
                                    .padding(.leading, 12)   // aligns with row text
                            }
                        }
                        .transaction { $0.disablesAnimations = true }
                        .contentTransition(.identity)
                    }
                    .scrollIndicators(.automatic)
                }

                // Original-looking empty state (same place & style)
                if filtered.isEmpty {
                    Text("No \(selectedList)")
                        .font(.title3).fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 24)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: tableAreaHeight)
        }
        .sheet(item: $selectedProspect) { p in
            NavigationStack {
                ProspectDetailsView(prospect: p)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    @ViewBuilder
    private func toggleChip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.callout)                 // ↑ from .caption
                .fontWeight(.semibold)
                .padding(.vertical, 7)
                .padding(.horizontal, 14)
                .frame(minWidth: 110)           // a bit wider
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isOn ? Color.blue : Color(.secondarySystemBackground))
                )
                .foregroundColor(isOn ? .white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isOn ? Color.blue.opacity(0.9) : Color.gray.opacity(0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isOn)
    }
}
