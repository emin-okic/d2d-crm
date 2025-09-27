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

    private var filtered: [Customer] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            return allCustomers.sorted { $0.fullName < $1.fullName }
        }

        return allCustomers.filter { c in
            c.fullName.localizedCaseInsensitiveContains(q) ||
            c.address.localizedCaseInsensitiveContains(q) ||
            c.contactPhone.localizedCaseInsensitiveContains(q) ||
            c.contactEmail.localizedCaseInsensitiveContains(q)
        }
        .sorted { $0.fullName < $1.fullName }
    }

    var body: some View {
        ZStack {
            if !filtered.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        
                        ForEach(filtered) { c in
                            Button { selectedCustomer = c } label: {
                                CustomerRowView(customer: c)   // 👈 use dedicated row
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 15)
                        }
                        
                    }
                }
            } else {
                Text(searchText.isEmpty ? "No Customers" : "No matches")
                    .font(.title3).foregroundColor(.secondary)
                    .padding(.top, 24)
            }
        }
        .sheet(item: $selectedCustomer) { c in
            NavigationStack {
                // Temporary reuse ProspectDetailsView
                ProspectDetailsView(
                    prospect: Prospect(fullName: c.fullName, address: c.address)
                )
            }
        }
    }
}
