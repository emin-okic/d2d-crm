//
//  CustomerActionsToolbar.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/17/25.
//

import SwiftUI
import Contacts

struct CustomerActionsToolbar: View {
    @Bindable var customer: Customer
    @Environment(\.modelContext) private var modelContext
    
    @State private var showDeleteConfirmation = false
    @State private var showExportPrompt = false
    @State private var showExportSuccessBanner = false
    @State private var exportSuccessMessage = ""
    
    var body: some View {
        ZStack {
            HStack {
                Spacer()
                
                HStack(spacing: 32) {
                    // Phone
                    iconButton(systemName: "phone.fill") {
                        if let url = URL(string: "tel://\(customer.contactPhone.filter(\.isNumber))") {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    // Email
                    iconButton(systemName: "envelope.fill") {
                        if let url = URL(string: "mailto:\(customer.contactEmail)") {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    // Export Contact
                    iconButton(systemName: "person.crop.circle.badge.plus") {
                        showExportPrompt = true
                    }
                    
                    // Delete
                    iconButton(systemName: "trash.fill", color: .red) {
                        showDeleteConfirmation = true
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            
            // Floating banner
            if showExportSuccessBanner {
                VStack {
                    Spacer().frame(height: 60)
                    Text(exportSuccessMessage)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.95))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .zIndex(999)
            }
        }
        .alert("Export to Contacts", isPresented: $showExportPrompt) {
            Button("Yes") { exportToContacts() }
            Button("No", role: .cancel) { }
        } message: {
            Text("Would you like to save this contact to your iOS Contacts app?")
        }
        .confirmationDialog("Delete this customer?",
                            isPresented: $showDeleteConfirmation,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteCustomer() }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private func iconButton(systemName: String, color: Color = .accentColor, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }
    
    private func exportToContacts() {
        showExportFeedback("Contact saved to Contacts.")
    }
    
    private func showExportFeedback(_ message: String) {
        exportSuccessMessage = message
        withAnimation { showExportSuccessBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showExportSuccessBanner = false }
        }
    }
    
    private func deleteCustomer() {
        modelContext.delete(customer)
        try? modelContext.save()
    }
}
