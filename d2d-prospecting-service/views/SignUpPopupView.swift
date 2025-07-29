//
//  SignUpPopupView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//
import SwiftUI
import SwiftData
import StoreKit
import PhoneNumberKit


struct SignUpPopupView: View {
    @Bindable var prospect: Prospect
    @Binding var isPresented: Bool

    @State private var tempPhone: String
    @State private var tempEmail: String
    
    @State private var phoneError: String?

    @Environment(\.modelContext) private var modelContext

    init(prospect: Prospect, isPresented: Binding<Bool>) {
        _prospect = Bindable(wrappedValue: prospect)
        _isPresented = isPresented
        _tempPhone = State(initialValue: prospect.contactPhone)
        _tempEmail = State(initialValue: prospect.contactEmail)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Confirm Customer Info")) {
                    TextField("Full Name", text: $prospect.fullName)
                    TextField("Address", text: $prospect.address)
                    TextField("Phone", text: $tempPhone)
                        .keyboardType(.phonePad)
                        .onChange(of: tempPhone) { _ in
                            _ = validatePhoneNumber()
                        }

                    if let error = phoneError {
                        Text(error).foregroundColor(.red)
                    }
                    TextField("Email", text: $tempEmail)
                }

                Section {
                    Button("Confirm Sign Up") {
                        if validatePhoneNumber() {
                            prospect.list = "Customers"
                            prospect.contactPhone = tempPhone
                            prospect.contactEmail = tempEmail
                            try? modelContext.save()
                            isPresented = false

                            // Ask for review only if not already done
                            if !UserDefaults.standard.hasLeftReview {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                        SKStoreReviewController.requestReview(in: scene)
                                        UserDefaults.standard.hasLeftReview = true
                                    }
                                }
                            }
                        }
                    }
                    .disabled(prospect.fullName.isEmpty || prospect.address.isEmpty)
                }
            }
            .navigationTitle("Convert to Customer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func validatePhoneNumber() -> Bool {
        let raw = tempPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            phoneError = nil
            return true
        }

        let utility = PhoneNumberUtility()

        do {
            _ = try utility.parse(raw)
            phoneError = nil
            return true
        } catch {
            phoneError = "Invalid phone number."
            return false
        }
    }
}
