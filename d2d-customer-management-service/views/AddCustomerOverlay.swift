//
//  AddCustomerOverlay.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/24/25.
//


/// TODO: Remove since unused

import SwiftUI
import SwiftData

struct AddCustomerOverlay: View {
    @Environment(\.modelContext) private var modelContext

    @Binding var isPresented: Bool
    @Binding var searchText: String
    var onSave: () -> Void

    var body: some View {
        if isPresented {
            ZStack {
                // Dim background
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture { isPresented = false }

                // Customer creation flow
                CustomerCreateStepperView { newCustomer in
                    modelContext.insert(newCustomer)
                    try? modelContext.save()

                    searchText = ""
                    isPresented = false
                    onSave()
                } onCancel: {
                    isPresented = false
                }
                .frame(width: 300, height: 300)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(radius: 8)
                .transition(.scale.combined(with: .opacity))
                .zIndex(2000)
            }
        }
    }
}
