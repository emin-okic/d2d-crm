//
//  CreateSaleView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/21/25.
//
import SwiftUI
import MessageUI
import Contacts
import PhoneNumberKit

struct CreateSaleView: View {
    @Binding var fullName: String
    @Binding var address: String
    @Binding var contactPhone: String
    @Binding var contactEmail: String
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Confirm Customer Info")) {
                    TextField("Full Name", text: $fullName)
                    TextField("Address", text: $address)
                    TextField("Phone", text: $contactPhone)
                    TextField("Email", text: $contactEmail)
                }

                Section {
                    Button("Confirm Sale") {
                        onConfirm()
                    }
                    .disabled(fullName.isEmpty || address.isEmpty)
                }
            }
            .navigationTitle("Create Sale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}
