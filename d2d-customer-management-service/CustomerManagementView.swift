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
    @Binding var selectedSearchField: ContactSearchField
    @Binding var activeSearchFilter: ContactSearchFilter?
    
    @Binding var selectedList: String
    
    var onSave: () -> Void

    @Binding var showingAddCustomer: Bool   // 👈 comes from parent now
    @Query private var customers: [Customer]

    private var totalCustomers: Int {
        customers.count
    }
    
    @Binding var selectedCustomer: Customer?
    
    @FocusState<Bool>.Binding var isSearchFocused: Bool
    
    @Binding var isDeleting: Bool
    @Binding var selectedCustomers: Set<Customer>
    var onClearSearchFilter: () -> Void
    var onContactAdded: () -> Void = {}

    private var filteredCustomerCount: Int {
        guard let filter = activeSearchFilter, !filter.isEmpty else { return customers.count }
        return customers.filter { $0.matches(filter) }.count
    }

    var body: some View {
        VStack(spacing: 16) {
            
            // 🔍 NEW — centered filter pill
            CustomerFilterRow(
                searchText: $searchText,
                selectedField: $selectedSearchField,
                isSearchFocused: $isSearchFocused,
                onSubmit: applySearchFilter,
                onClear: onClearSearchFilter
            )

            if let filter = activeSearchFilter, !filter.isEmpty {
                ContactFilterBanner(
                    filter: filter,
                    resultCount: filteredCustomerCount,
                    listName: selectedList,
                    onClear: onClearSearchFilter
                )
                .padding(.horizontal, 20)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // ✅ Header + chips stay
            CustomerHeaderView(totalCustomers: totalCustomers)
            ToggleChipsView(selectedList: $selectedList)

            // ✅ Section now wrapped in container for consistent style
            CustomerContainerView(
                activeSearchFilter: $activeSearchFilter,
                selectedCustomer: $selectedCustomer,
                isDeleting: $isDeleting,
                selectedCustomers: $selectedCustomers
            )
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
        }
        // ✅ Stepper sheet for creating customers
        .sheet(isPresented: $showingAddCustomer) {
            CustomerCreateStepperView { newCustomer in
                modelContext.insert(newCustomer)
                try? modelContext.save()

                onClearSearchFilter()
                showingAddCustomer = false
                onSave()
                onContactAdded()
            } onCancel: {
                showingAddCustomer = false
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func applySearchFilter() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onClearSearchFilter()
            return
        }

        activeSearchFilter = ContactSearchFilter(field: selectedSearchField, query: trimmed)
        searchText = ""
        isSearchFocused = false
    }
}
