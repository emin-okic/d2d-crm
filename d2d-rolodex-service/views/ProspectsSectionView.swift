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
    
    // Reuse your “Prospects” / “Customers” list names
    @Binding var selectedList: String
    @State private var selectedProspect: Prospect?
    
    private var filtered: [Prospect] {
        allProspects
            .filter { $0.list == selectedList }
            .sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
    }
    
    private var subtitle: String {
        let count = filtered.count
        return selectedList == "Prospects" ? "\(count) Prospects" : "\(count) Customers"
    }
    
    private let rowHeight: CGFloat = 74
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Centered header
            VStack(spacing: 5) {
                Text("Contacts")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top)

            // Toggle chips (Prospects / Customers)
            HStack(spacing: 8) {
                toggleChip("Prospects", isOn: selectedList == "Prospects") { selectedList = "Prospects" }
                toggleChip("Customers", isOn: selectedList == "Customers") { selectedList = "Customers" }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)

            if filtered.isEmpty {
                Text("No \(selectedList)")
                    .font(.title3).fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                // Scrollable table area (≈ 3 rows)
                ScrollView {
                    // ⛔️ No row animations when the list switches
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { p in
                            Button {
                                selectedProspect = p
                            } label: {
                                ProspectRowCompact(prospect: p)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)          // uniform left/right
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .padding(.leading, 12)                // align with row text
                        }
                    }
                    // Kill implicit insert/remove animations on toggle
                    .transaction { t in t.disablesAnimations = true }
                    .contentTransition(.identity)                      // iOS 17+: no fancy transitions
                }
                .frame(maxHeight: rowHeight * 3)                       // clamp to ~3 rows
                // Do NOT attach .animation to this ScrollView/VStack
            }
        }
        // Detail sheet
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
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .frame(minWidth: 96)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isOn ? Color.blue : Color(.secondarySystemBackground))
                )
                .foregroundColor(isOn ? .white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isOn ? Color.blue.opacity(0.9) : Color.gray.opacity(0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        // ✅ Only the chip animates, not the list
        .animation(.easeInOut(duration: 0.15), value: isOn)
    }
    
}
