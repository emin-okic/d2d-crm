//
//  SignUpPopupView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//
import SwiftUI
import SwiftData

import StoreKit


struct SignUpPopupView: View {
    @Bindable var prospect: Prospect
    @Binding var isPresented: Bool

    @State private var tempPhone: String
    @State private var tempEmail: String

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
                    TextField("Email", text: $tempEmail)
                }

                Section {
                    Button("Confirm Sign Up") {
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
}
