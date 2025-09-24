//
//  CustomerManagementView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/23/25.
//

import SwiftUI
import SwiftData

struct CustomerManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var searchText: String
    @Binding var selectedList: String
    var onSave: () -> Void

    @State private var showingAddCustomer = false
    @Query private var customers: [Customer]

    private var totalCustomers: Int {
        customers.count
    }

    var body: some View {
        VStack(spacing: 16) {
            CustomerHeaderView(totalCustomers: totalCustomers)

            // Toggle chips under header (shared binding)
            ToggleChipsView(selectedList: $selectedList)

            ContactsContainerView(
                selectedList: $selectedList,
                searchText: $searchText
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .overlay(
            AddCustomerOverlay(
                isPresented: $showingAddCustomer,
                searchText: $searchText,
                onSave: onSave
            )
        )
    }
}

