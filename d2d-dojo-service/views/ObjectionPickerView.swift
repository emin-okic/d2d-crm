//
//  ObjectionPickerView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/1/25.
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
