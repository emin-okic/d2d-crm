//
//  AddObjectionView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//
import SwiftUI
import SwiftData

struct AddObjectionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var text: String = ""
    @State private var response: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Objection")) {
                    TextField("e.g. 'Not interested'", text: $text)
                }

                Section(header: Text("Suggested Response")) {
                    TextField("e.g. 'Sure, but can I ask why?'", text: $response)
                }
            }
            .navigationTitle("New Objection")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let new = Objection(text: text, response: response)
                        context.insert(new)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
