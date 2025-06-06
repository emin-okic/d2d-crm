//
//  NewProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI

struct NewProspectView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedList: String
    var onSave: () -> Void
    var userEmail: String

    @State private var fullName = ""
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onSave()
                    }
                }
            }
        }
    }
}
