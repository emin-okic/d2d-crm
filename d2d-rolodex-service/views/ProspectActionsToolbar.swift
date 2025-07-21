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
    @State private var showCallConfirmation = false

    @State private var showAddEmailSheet = false
    @State private var newEmail = ""
    @State private var showEmailConfirmation = false

    @State private var showingMoreActions = false

    var body: some View {
        HStack(spacing: 24) {
            // Phone
            iconButton(systemName: "phone.fill") {
                if prospect.contactPhone.isEmpty {
                    showAddPhoneSheet = true
                } else {
                    showCallConfirmation = true
                }
            }

            // Email
            iconButton(systemName: "envelope.fill") {
                if prospect.contactEmail.nilIfEmpty == nil {
                    showAddEmailSheet = true
                } else {
                    showEmailConfirmation = true
                }
            }

            // More
            iconButton(systemName: "ellipsis.circle") {
                showingMoreActions = true
            }
        }
        .padding(.vertical, 8)

        // Phone confirmation
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

        // Email confirmation
        .confirmationDialog(
            "Send email to \(prospect.contactEmail)?",
            isPresented: $showEmailConfirmation,
            titleVisibility: .visible
        ) {
            Button("Compose Email") {
                if let url = URL(string: "mailto:\(prospect.contactEmail)") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        }

        // Add phone sheet
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

        // Add email sheet
        .sheet(isPresented: $showAddEmailSheet) {
            NavigationView {
                VStack(spacing: 16) {
                    Text("Add Email Address")
                        .font(.headline)

                    TextField("Enter email", text: $newEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)

                    Button("Save & Compose") {
                        prospect.contactEmail = newEmail
                        try? modelContext.save()

                        if let url = URL(string: "mailto:\(newEmail)") {
                            UIApplication.shared.open(url)
                        }

                        showAddEmailSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Spacer()
                }
                .padding()
                .navigationTitle("Email Address")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showAddEmailSheet = false
                        }
                    }
                }
            }
        }

        // More Actions
        .actionSheet(isPresented: $showingMoreActions) {
            ActionSheet(
                title: Text("More Actions"),
                buttons: [
                    .default(Text("Edit Contact")) {
                        // TODO
                    },
                    .destructive(Text("Delete Prospect")) {
                        // TODO
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
