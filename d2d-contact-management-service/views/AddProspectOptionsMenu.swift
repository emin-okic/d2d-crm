//
//  AddProspectOptionsMenu.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/23/25.
//
import SwiftUI

struct AddProspectOptionsMenu: View {
    let onAddManually: () -> Void
    let onImportFromContacts: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                onAddManually()
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Add Manually")
                }
                .padding()
            }
            .buttonStyle(.borderedProminent)

            Button {
                onImportFromContacts()
            } label: {
                HStack {
                    Image(systemName: "person.icloud") // icon for import
                    Text("Import From iPhone")
                }
                .padding()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 6)
        // position it near the + button
        .frame(maxWidth: 200)
    }
}
