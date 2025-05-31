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

    var body: some View {
        Form {
            TextField("Full Name", text: $prospect.fullName)
            TextField("Address", text: $prospect.address)
        }
        .navigationTitle("Edit Prospect")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    DatabaseController.shared.updateProspect(
                        uuid: prospect.id,
                        newName: prospect.fullName,
                        newAddress: prospect.address
                    )
                    // Refresh in-memory store
                    ProspectsStore.shared.loadProspects()
                    presentationMode.wrappedValue.dismiss()
                }

            }
        }
    }
}
