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
    @State private var suggestions: [String] = []

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Objection")) {
                    TextField("e.g. 'Not interested'", text: $text)

                    if !suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggested Objections")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(suggestions, id: \.self) { item in
                                        Button {
                                            text = item   // auto-fill
                                        } label: {
                                            Text(item)
                                                .font(.caption)
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 10)
                                                .background(Color(.secondarySystemBackground))
                                                .cornerRadius(10)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.top, 6)
                    }
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
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                suggestions = CommonObjections.all.shuffled().prefix(5).map { $0 }
            }
        }
    }
}
