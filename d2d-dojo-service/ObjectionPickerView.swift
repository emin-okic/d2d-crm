//
//  ObjectionPickerView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//
import SwiftUI

struct ObjectionPickerView: View {
    var objections: [Objection]
    var onSelect: (Objection) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List(objections) { objection in
                Button(objection.text) {
                    dismiss()  // Dismiss first
                    DispatchQueue.main.async {
                        onSelect(objection)  // Then call startRecording
                    }
                }
            }
            .navigationTitle("Select Objection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
