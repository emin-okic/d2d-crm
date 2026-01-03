//
//  ProspectPickerView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/3/26.
//

import SwiftUI
import SwiftData

struct ContactPickerView: View {
    let contacts: [any ContactProtocol]   // now supports both Prospect & Customer
    @Binding var selectedProspect: Prospect?
    @Environment(\.dismiss) private var dismiss
    var title: String = "Pick Contact"

    @State private var searchText: String = ""

    var filteredContacts: [any ContactProtocol] {
        if searchText.isEmpty { return contacts }
        return contacts.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Drag handle
                RoundedRectangle(cornerRadius: 3)
                    .frame(width: 40, height: 5)
                    .foregroundColor(Color(.systemGray4))
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                
                // Search bar
                TextField("Search Contacts", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredContacts, id: \.fullName) { contact in
                            Button {
                                if let prospect = contact as? Prospect {
                                    selectedProspect = prospect
                                } else if let customer = contact as? Customer {
                                    // Convert customer to Prospect if needed or handle differently
                                    let tempProspect = Prospect(
                                        fullName: customer.fullName,
                                        address: customer.address,
                                        count: customer.knockCount
                                    )
                                    selectedProspect = tempProspect
                                }
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(contact.fullName)
                                            .font(.headline)
                                        Text(contact.address)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    
                                    // Show a star for customers
                                    if contact is Customer {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.fraction(0.5)])
        .presentationDragIndicator(.visible)
    }
}
