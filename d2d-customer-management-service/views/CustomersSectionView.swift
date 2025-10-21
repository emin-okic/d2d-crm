//
//  CustomersSectionView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/27/25.
//

import SwiftUI
import SwiftData

struct CustomersSectionView: View {
    @Query private var allCustomers: [Customer]
    @Binding var searchText: String

    @State private var selectedCustomer: Customer?

    private let rowHeight: CGFloat = 88

    private var filtered: [Customer] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            return allCustomers.sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
        }

        return allCustomers.filter { c in
            c.fullName.localizedCaseInsensitiveContains(q) ||
            c.address.localizedCaseInsensitiveContains(q) ||
            c.contactPhone.localizedCaseInsensitiveContains(q) ||
            c.contactEmail.localizedCaseInsensitiveContains(q)
        }
        .sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
    }

    var body: some View {
        ZStack(alignment: .top) {
            if !filtered.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { c in
                            Button { selectedCustomer = c } label: {
                                CustomerRowView(customer: c)
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
                    .padding(.top, 0)
                    .transaction { $0.disablesAnimations = true }
                    .contentTransition(.identity)
                }
                .scrollIndicators(.automatic)
            } else {
                Text(searchText.isEmpty ? "No Customers" : "No matches")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)
                    .allowsHitTesting(false)
            }
        }
        .sheet(item: $selectedCustomer) { c in
            NavigationStack {
                CustomerDetailsView(customer: c)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
