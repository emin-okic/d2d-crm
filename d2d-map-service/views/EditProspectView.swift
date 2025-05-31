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
            .pickerStyle(SegmentedPickerStyle()) // Or use DefaultPickerStyle() or MenuPickerStyle()

            Stepper(value: $prospect.count, in: 0...999) {
                Text("Count: \(prospect.count)")
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

