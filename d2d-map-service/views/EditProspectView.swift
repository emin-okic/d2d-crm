//
//  EditProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI

struct EditProspectView: View {
    @Binding var prospect: Prospect
    @Environment(\.presentationMode) var presentationMode
    
    let allLists = ["Prospects", "Customers"]

    var body: some View {
        Form {
            TextField("Full Name", text: $prospect.fullName)
            TextField("Address", text: $prospect.address)
            
            Picker("List", selection: $prospect.list) {
                ForEach(allLists, id: \.self) { listName in
                    Text(listName)
                }
            }
            .pickerStyle(MenuPickerStyle()) // Use dropdown-style menu

            Stepper(value: $prospect.count, in: 0...999) {
                Text("Count: \(prospect.count)")
            }
            Section(header: Text("Knock History")) {
                if prospect.knockHistory.isEmpty {
                    Text("No knocks recorded yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(prospect.knockHistory.enumerated()), id: \.offset) { index, status in
                        Text("\(index + 1). \(status)")
                    }
                }
            }

        }
        .navigationTitle("Edit Prospect")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    // Update the prospect in the database
                    DatabaseController.shared.updateProspect(prospect)
                    
                    // Dismiss the edit view
                    presentationMode.wrappedValue.dismiss()
                }

            }
        }
    }
}

