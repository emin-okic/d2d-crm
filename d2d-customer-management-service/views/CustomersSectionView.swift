//
//  CustomersSectionView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/27/25.
//

import SwiftUI
import SwiftData

struct CustomersSectionView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query private var allCustomers: [Customer]
    
    @Binding var searchText: String

    @Binding var selectedCustomer: Customer?
    
    @State private var showDeleteConfirmation: Bool = false
    @State private var customerToDelete: Customer?

    private let rowHeight: CGFloat = 88

    private var filtered: [Customer] {
        
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard q.isEmpty else {
            return allCustomers.filter { c in
                c.fullName.localizedCaseInsensitiveContains(q) ||
                c.address.localizedCaseInsensitiveContains(q) ||
                c.contactPhone.localizedCaseInsensitiveContains(q) ||
                c.contactEmail.localizedCaseInsensitiveContains(q)
            }
            .sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
        }

        // ✅ Default list order
        return allCustomers.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    @State private var draggingCustomerID: PersistentIdentifier?
    
    @Binding var isDeleting: Bool
    @Binding var selectedCustomers: Set<Customer>

    var body: some View {
        ZStack(alignment: .top) {
            
            Color(.systemGray6)
                .edgesIgnoringSafeArea(.all)
            
            if !filtered.isEmpty {
                List {
                    ForEach(filtered) { c in
                        HStack(spacing: 12) {

                            if isDeleting {
                                Image(systemName: selectedCustomers.contains(c)
                                      ? "checkmark.circle.fill"
                                      : "circle")
                                    .foregroundColor(.red)
                            }

                            CustomerRowView(customer: c)
                        }
                        .padding(.leading, isDeleting ? 6 : 0)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isDeleting && selectedCustomers.contains(c)
                                      ? Color.red.opacity(0.06)
                                      : Color.clear)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isDeleting {
                                toggleSelection(c)
                            } else {
                                
                                // ✅ Haptics & Sound when opening a prospect/customer
                                ContactScreenHapticsController.shared.lightTap()
                                ContactScreenSoundController.shared.playSound1()
                                
                                selectedCustomer = c
                            }
                        }
                            .scaleEffect(draggingCustomerID == c.persistentModelID ? 1.03 : 1.0)
                            .shadow(
                                color: draggingCustomerID == c.persistentModelID
                                    ? Color.black.opacity(0.18)
                                    : Color.black.opacity(0.05),
                                radius: draggingCustomerID == c.persistentModelID ? 12 : 4,
                                x: 0,
                                y: draggingCustomerID == c.persistentModelID ? 6 : 2
                            )
                            .animation(.spring(response: 0.25, dampingFraction: 0.85),
                                       value: draggingCustomerID)

                            .onDrag {
                                draggingCustomerID = c.persistentModelID
                                return NSItemProvider(object: c.fullName as NSString)
                            } preview: {
                                CustomerRowView(customer: c)
                                    .background(Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .compositingGroup()
                                    .drawingGroup()
                            }

                            .onDrop(of: [.text], delegate: DragResetDelegate {
                                draggingCustomerID = nil
                            })
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    
                                    // ✅ Haptics & Sound when initiating delete
                                    ContactScreenHapticsController.shared.lightTap()
                                    ContactScreenSoundController.shared.playSound1()
                                    
                                    customerToDelete = c
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                            }
                            .listRowBackground(Color.clear)
                    }
                    .onMove(perform: moveCustomers)
                    .listRowInsets(EdgeInsets())
                }
                .listStyle(.plain)
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
        .alert("Delete Customer?", isPresented: $showDeleteConfirmation, presenting: customerToDelete) { customer in
            Button("Delete", role: .destructive) {
                
                // ✅ Haptics & Sound when initiating delete
                ContactScreenHapticsController.shared.lightTap()
                ContactScreenSoundController.shared.playSound1()
                
                deleteCustomer(customer)
            }
            Button("Cancel", role: .cancel) {
                
                // ✅ Haptics & Sound when initiating delete
                ContactScreenHapticsController.shared.lightTap()
                ContactScreenSoundController.shared.playSound1()
                
            }
        } message: { customer in
            Text("Are you sure you want to delete \(customer.fullName)? This action cannot be undone.")
        }
        .onChange(of: selectedCustomer) { newValue in
            guard newValue != nil else { return }
        }
    }
    
    private func toggleSelection(_ customer: Customer) {
        
        ContactScreenHapticsController.shared.lightTap()
        ContactScreenSoundController.shared.playSound1()
        
        if selectedCustomers.contains(customer) {
            
            selectedCustomers.remove(customer)
            
        } else {
            
            selectedCustomers.insert(customer)
            
        }
    }
    
    private func moveCustomers(from source: IndexSet, to destination: Int) {
        var reordered = filtered
        reordered.move(fromOffsets: source, toOffset: destination)

        for (index, customer) in reordered.enumerated() {
            customer.orderIndex = index
        }

        try? modelContext.save()
        draggingCustomerID = nil
    }
    
    private struct DragResetDelegate: DropDelegate {
        let onEnd: () -> Void

        func performDrop(info: DropInfo) -> Bool {
            onEnd()
            return true
        }

        func dropExited(info: DropInfo) {
            onEnd()
        }
    }
    
    private func deleteCustomer(_ customer: Customer) {
        for appointment in customer.appointments {
            modelContext.delete(appointment)
        }

        modelContext.delete(customer)
        try? modelContext.save()

        if selectedCustomer?.id == customer.id {
            selectedCustomer = nil
        }

        customerToDelete = nil
    }
    
}
