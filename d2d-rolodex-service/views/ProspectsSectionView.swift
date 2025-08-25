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
        // how tall the table area should be, ~3 rows
        let tableAreaHeight = rowHeight * 3

        VStack(alignment: .leading, spacing: 12) {
            // Header (static)
            VStack(spacing: 5) {
                Text("Contacts")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8) // small, fixed padding (doesn't change)

            // Toggle chips (static)
            HStack(spacing: 8) {
                toggleChip("Prospects", isOn: selectedList == "Prospects") { selectedList = "Prospects" }
                toggleChip("Customers", isOn: selectedList == "Customers") { selectedList = "Customers" }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)

            // 🔒 STATIC HEIGHT TABLE AREA — never changes size
            ZStack {
                // Scrollable list when we have rows
                if !filtered.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filtered) { p in
                                Button { selectedProspect = p } label: {
                                    ProspectRowCompact(prospect: p)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 12)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                Divider()
                                    .padding(.leading, 12)
                            }
                        }
                        // No insert/remove animations when switching lists
                        .transaction { $0.disablesAnimations = true }
                        .contentTransition(.identity)
                    }
                    .scrollIndicators(.automatic)
                }

                // Centered empty state, rendered IN the same fixed area
                if filtered.isEmpty {
                    VStack(spacing: 8) {
                        Text("No \(selectedList)")
                            .font(.title3).fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text("Add a contact to get started.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .multilineTextAlignment(.center)
                    .allowsHitTesting(false) // so the area still feels static
                }
            }
            .frame(height: tableAreaHeight) // <-- the magic: fixed height
        }
        // Details sheet
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
