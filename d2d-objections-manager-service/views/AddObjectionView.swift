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
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add a Sales Objection")
                            .font(.title2.bold())

                        Text("Enter what prospects say when they don’t buy. Tracking objections helps you spot patterns, sharpen your pitch, and learn how to overcome them.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal)

                    // MARK: - Objection Input
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What did they say?")
                            .font(.headline)

                        TextField("e.g. Not interested, Too expensive…", text: $text)
                            .padding(12)
                            .background(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )
                            .cornerRadius(10)

                        // MARK: - Suggested Objections
                        if !suggestions.isEmpty {
                            Text("Suggested Objections")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(suggestions, id: \.self) { item in
                                        Button {
                                            
                                            ObjectionManagerHapticsController.shared.screenTap()
                                            ObjectionManagerSoundController.shared.playActionSound()
                                            
                                            text = item
                                            
                                        } label: {
                                            Text(item)
                                                .font(.caption.bold())
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 12)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.blue.opacity(0.1))
                                                )
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal)

                    Spacer(minLength: 30)
                }
                .padding(.top)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        
                        ObjectionManagerHapticsController.shared.successAction()
                        ObjectionManagerSoundController.shared.playActionSound()
                        
                        let new = Objection(text: text)
                        context.insert(new)

                        Task {
                            new.response = await ResponseGenerator.shared.generate(for: text)
                            try? context.save()
                        }

                        dismiss()
                        
                    } label: {
                        Label("Save", systemImage: "checkmark")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(text.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button() {
                        
                        ObjectionManagerHapticsController.shared.screenTap()
                        ObjectionManagerSoundController.shared.playActionSound()
                        
                        dismiss()
                        
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                    }
                    .buttonStyle(.plain)
                }
            }
            .onAppear {
                suggestions = CommonObjections.all.shuffled().prefix(5).map { $0 }
            }
        }
    }
}
