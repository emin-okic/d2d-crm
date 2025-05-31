//
//  NewProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI

struct NewProspectView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var prospects: [Prospect]

    @State private var fullName: String = ""
    @State private var address: String = ""

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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newProspect = Prospect(id: UUID(), fullName: fullName, address: address)
                        prospects.append(newProspect)
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
