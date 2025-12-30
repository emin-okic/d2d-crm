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
    
    @Binding var isSearchExpanded: Bool
    @FocusState<Bool>.Binding var isSearchFocused: Bool
    
    var onSave: () -> Void

    @Binding var showingAddCustomer: Bool   // 👈 comes from parent now
    @Query private var customers: [Customer]

    private var totalCustomers: Int {
        customers.count
    }
    
    @Binding var selectedCustomer: Customer?

    var body: some View {
        VStack(spacing: 16) {
            // ✅ Header + chips stay
            CustomerHeaderView(totalCustomers: totalCustomers)
            ToggleChipsView(selectedList: $selectedList)

            // ✅ Section now wrapped in container for consistent style
            CustomerContainerView(
                searchText: $searchText,
                isSearchExpanded: $isSearchExpanded,
                isSearchFocused: $isSearchFocused,
                selectedCustomer: $selectedCustomer
            )
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
        }
        // ✅ Stepper sheet for creating customers
        .sheet(isPresented: $showingAddCustomer) {
            CustomerCreateStepperView { newCustomer in
                modelContext.insert(newCustomer)
                try? modelContext.save()

                searchText = ""
                showingAddCustomer = false
                onSave()
            } onCancel: {
                showingAddCustomer = false
            }
            .presentationDetents([.medium, .large])
        }
    }
}
