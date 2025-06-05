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

            Section(header: Text("Knock History")) {
                if prospect.knockHistory.isEmpty {
                    Text("No knocks recorded yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(prospect.knockHistory) { knock in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(knock.status).fontWeight(.semibold)
                                Spacer()
                                Text(knock.date.formatted(date: .abbreviated, time: .shortened))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("Lat: \(String(format: "%.4f", knock.latitude)), Lon: \(String(format: "%.4f", knock.longitude))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
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
