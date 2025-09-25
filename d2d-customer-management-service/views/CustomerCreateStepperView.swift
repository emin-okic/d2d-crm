//
//  CustomerCreateStepperView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/17/25.
//

import SwiftUI
import SwiftData
import MapKit
import PhoneNumberKit

struct CustomerCreateStepperView: View {
    var onComplete: (Customer) -> Void
    var onCancel: () -> Void

    @StateObject private var controller: CustomerCreationController
    @FocusState private var isAddressFocused: Bool

    init(
        initialName: String? = nil,
        initialAddress: String? = nil,
        initialPhone: String? = nil,
        initialEmail: String? = nil,
        onComplete: @escaping (Customer) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onComplete = onComplete
        self.onCancel = onCancel
        _controller = StateObject(
            wrappedValue: CustomerCreationController(
                initialName: initialName,
                initialAddress: initialAddress,
                initialPhone: initialPhone,
                initialEmail: initialEmail
            )
        )
    }

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("New Customer").font(.headline)
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }

            DotStepBar(total: controller.totalStepCount, index: controller.stepIndex)

            // Content
            Group {
                if controller.stepIndex == 0 { stepOne }
                else { stepTwo }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Navigation buttons
            HStack {
                if controller.stepIndex > 0 {
                    Button("Back") { controller.backStep() }
                }
                Spacer()
                if controller.stepIndex == 0 {
                    Button("Next") { controller.nextStep() }
                        .disabled(!controller.canProceedStepOne)
                } else {
                    Button("Finish") {
                        guard controller.validatePhoneNumber() else { return }
                        let customer = controller.buildCustomer()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                            onComplete(customer)
                        }
                    }
                    .disabled(!controller.canProceedStepTwo)
                }
            }
        }
        .padding(12)
    }

    // Step One
    private var stepOne: some View {
        Form {
            Section(header: Text("Step 1 • Name & Address")) {
                TextField("Full Name", text: $controller.fullName)
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Address", text: $controller.address)
                        .focused($isAddressFocused)   // 👈 use FocusState here
                        .onChange(of: controller.address) { controller.searchVM.updateQuery($0) }

                    if isAddressFocused && !controller.searchVM.results.isEmpty { // 👈 check focus from view
                        ForEach(controller.searchVM.results.prefix(4), id: \.self) { result in
                            Button { controller.handleAddressSelection(result) } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.title).bold()
                                    Text(result.subtitle).font(.caption).foregroundColor(.secondary)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                }
            }
        }
    }

    // Step Two
    private var stepTwo: some View {
        Form {
            Section(header: Text("Step 2 • Contact Details")) {
                TextField("Phone (Optional)", text: $controller.contactPhone)
                    .keyboardType(.phonePad)
                    .onChange(of: controller.contactPhone) { _ in _ = controller.validatePhoneNumber() }

                if let phoneError = controller.phoneError {
                    Text(phoneError).foregroundColor(.red).font(.caption)
                }

                TextField("Email (Optional)", text: $controller.contactEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }
        }
    }
}
