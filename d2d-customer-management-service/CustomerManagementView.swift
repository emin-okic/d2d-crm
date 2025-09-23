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
    var onSave: () -> Void

    @State private var showingAddCustomer = false
    @Query private var customers: [Customer]

    private var totalCustomers: Int {
        customers.count
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 10) {
                Text("Contacts")
                    .font(.largeTitle).fontWeight(.bold)
                    .padding(.top, 10)

                Text("\(totalCustomers) Customers")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }

            // Customers table
            ContactsContainerView(
                selectedList: .constant("Customers"),
                searchText: $searchText
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .overlay(addCustomerOverlay)
    }

    // MARK: - Overlays
    @ViewBuilder
    private var addCustomerOverlay: some View {
        if showingAddCustomer {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture { showingAddCustomer = false }

            CustomerCreateStepperView { newCustomer in
                modelContext.insert(newCustomer)
                try? modelContext.save()

                searchText = ""
                showingAddCustomer = false
                onSave()
            } onCancel: {
                showingAddCustomer = false
            }
            .frame(width: 300, height: 300)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(radius: 8)
            .position(x: UIScreen.main.bounds.midX,
                      y: UIScreen.main.bounds.midY * 0.9)
            .transition(.scale.combined(with: .opacity))
            .zIndex(2000)
        }
    }
}

// MARK: - Preview
struct CustomerManagementView_Previews: PreviewProvider {
    @State static var searchText = ""

    static var previews: some View {
        CustomerManagementView(searchText: $searchText, onSave: {})
            .modelContainer(for: Customer.self, inMemory: true)
            .previewDisplayName("Customer Management")
    }
}
