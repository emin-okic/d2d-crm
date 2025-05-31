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
            Stepper(value: $prospect.count, in: 0...999) {
                Text("Count: \(prospect.count)")
            }
        }
        .navigationTitle("Edit Prospect")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    // You can call a DB update here
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
