//
//  ProspectActionsToolbar.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/21/25.
//


import SwiftUI
import MessageUI

struct ProspectActionsToolbar: View {
    @Bindable var prospect: Prospect
    @Environment(\.modelContext) private var modelContext

    @State private var showAddPhoneSheet = false
    @State private var newPhone = ""
    @State private var showingMoreActions = false
    @State private var showCallConfirmation = false

    var body: some View {
        HStack(spacing: 24) {
            // Phone Button
            iconButton(systemName: "phone.fill") {
                if prospect.contactPhone.isEmpty {
                    showAddPhoneSheet = true
                } else {
                    showCallConfirmation = true
                }
            }

            // Email Button
            iconButton(systemName: "envelope.fill") {
                if let email = prospect.contactEmail.nilIfEmpty,
                   let url = URL(string: "mailto:\(email)"),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }

            // More Button
            iconButton(systemName: "ellipsis.circle") {
                showingMoreActions = true
            }
        }
        .padding(.vertical, 8)
        .confirmationDialog(
            "Call \(formattedPhone(prospect.contactPhone))?",
            isPresented: $showCallConfirmation,
            titleVisibility: .visible
        ) {
            Button("Call") {
                if let url = URL(string: "tel://\(prospect.contactPhone.filter(\.isNumber))") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showAddPhoneSheet) {
            NavigationView {
                VStack(spacing: 16) {
                    Text("Add Phone Number")
                        .font(.headline)

                    TextField("Enter phone number", text: $newPhone)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)

                    Button("Save & Call") {
                        prospect.contactPhone = newPhone
                        try? modelContext.save()

                        if let url = URL(string: "tel://\(newPhone.filter(\.isNumber))") {
                            UIApplication.shared.open(url)
                        }

                        showAddPhoneSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Spacer()
                }
                .padding()
                .navigationTitle("Phone Number")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showAddPhoneSheet = false
                        }
                    }
                }
            }
        }
        .actionSheet(isPresented: $showingMoreActions) {
            ActionSheet(
                title: Text("More Actions"),
                buttons: [
                    .default(Text("Edit Contact")) {
                        // TODO: handle edit
                    },
                    .destructive(Text("Delete Prospect")) {
                        // TODO: handle deletion
                    },
                    .cancel()
                ]
            )
        }
    }

    private func iconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 44, height: 44)
                .background(Color.clear)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func formattedPhone(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber)
        guard digits.count == 10 else { return raw }
        return "(\(digits.prefix(3))) \(digits.dropFirst(3).prefix(3))-\(digits.suffix(4))"
    }
}
