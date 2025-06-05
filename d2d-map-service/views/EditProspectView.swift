//
//  EditProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import SwiftData

struct EditProspectView: View {
    @Bindable var prospect: Prospect
    @Environment(\.presentationMode) var presentationMode

    let allLists = ["Prospects", "Customers"]

    var body: some View {
        Form {
            Section(header: Text("Prospect Details")) {
                TextField("Full Name", text: $prospect.fullName)
                TextField("Address", text: $prospect.address)
            }

            Picker("Current List", selection: $prospect.list) {
                ForEach(allLists, id: \.self) { listName in
                    Text(listName)
                }
            }
            .pickerStyle(.menu)

            KnockingHistoryView(prospect: prospect)
            
        }
        .navigationTitle("Edit Prospect")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
