//
//  NewProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI

/// A form-based view for adding a new prospect to the app.
///
/// This view collects a prospect's name and address, assigns them to a selected list,
/// and associates them with the current user. When the user taps "Save", the new
/// `Prospect` is added to the SwiftData context and passed to the parent via a callback.
struct NewProspectView: View {
    /// The SwiftData model context used to persist new prospects.
    @Environment(\.modelContext) private var modelContext

    /// The currently selected list ("Prospects", "Customers", etc.).
    @Binding var selectedList: String

    /// A closure that gets called when the view is dismissed (whether by saving or cancelling).
    var onSave: () -> Void

    /// The email of the current user, used to associate the new prospect.
    var userEmail: String

    /// The input field for the prospect’s name.
    @State private var fullName = ""

    /// The input field for the prospect’s address.
    @State private var address = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("New Prospect Info")) {
                    TextField("Full Name", text: $fullName)
                    TextField("Address", text: $address)
                }
            }
            .navigationTitle("Add Prospect")
            .toolbar {
                // Save button
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Create and insert new prospect
                        let newProspect = Prospect(
                            fullName: fullName,
                            address: address,
                            count: 0,
                            list: selectedList,
                            userEmail: userEmail
                        )
                        modelContext.insert(newProspect)
                        onSave()
                    }
                }

                // Cancel button
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onSave()
                    }
                }
            }
        }
    }
}
