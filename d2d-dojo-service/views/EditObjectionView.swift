//
//  EditObjectionView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//
import SwiftUI

struct EditObjectionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var objection: Objection

    private let manager = ObjectionManager()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    Section(header: Text("Objection")) {
                        TextField("Objection text", text: $objection.text)
                    }
                    Section(header: Text("Expected Response")) {
                        TextEditor(text: $objection.response)
                            .frame(minHeight: 120)
                            .padding(.vertical, 4)
                    }
                    Section(header: Text("Times Heard")) {
                        Stepper("\(objection.timesHeard)", value: $objection.timesHeard, in: 0...1000)
                    }
                    Section {
                        Button("Regenerate Response") {
                            Task {
                                objection.response = await ResponseGenerator.shared.generate(for: objection.text)
                                try? modelContext.save()
                            }
                        }
                    }
                }

                Button(role: .destructive) {
                    manager.delete(objection, from: modelContext)
                    dismiss()
                } label: {
                    Label("Delete Objection", systemImage: "trash")
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding()
            }
            .navigationTitle("Edit Objection")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
