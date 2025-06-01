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
            
            Section(header: Text("Prospect Details")) {
                TextField("Full Name", text: $prospect.fullName)
                TextField("Address", text: $prospect.address)
            }
            

            Picker("Current List", selection: $prospect.list) {
                ForEach(allLists, id: \.self) { listName in
                    Text(listName)
                }
            }
            .pickerStyle(MenuPickerStyle())


            Section(header: Text("Knock History")) {
                if prospect.knockHistory.isEmpty {
                    Text("No knocks recorded yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(prospect.knockHistory.enumerated()), id: \.offset) { index, record in
                        Text("\(index + 1). \(record.status) – \(record.date.formatted(date: .abbreviated, time: .shortened))")
                    }
                }
            }
        }
        .navigationTitle("Edit Prospect")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    DatabaseController.shared.updateProspect(prospect)
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
