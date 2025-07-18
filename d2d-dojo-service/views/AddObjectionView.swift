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
            }
            .navigationTitle("New Objection")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let new = Objection(text: text)
                        context.insert(new)

                        Task {
                            new.response = await ResponseGenerator.shared.generate(for: text)
                            try? context.save()
                        }

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
