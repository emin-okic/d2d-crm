//
//  OpenInAppleMapsButton.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/29/25.
//

import SwiftUI
import SwiftData

struct OpenInAppleMapsButton: View {
    let appointments: [Appointment]
    @Environment(\.modelContext) private var modelContext

    private var isEnabled: Bool {
        !appointments.isEmpty
    }

    var body: some View {
        Button {
            Task {
                await RoutePlannerController.planAndOpenRoute(
                    appointments: appointments,
                    modelContext: modelContext
                )
            }
        } label: {
            Image(systemName: "car.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(isEnabled ? .blue : .secondary)
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.regularMaterial)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemBackground).opacity(0.58))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.45), lineWidth: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                        )
                )
                .shadow(color: Color.black.opacity(0.24), radius: 16, x: 0, y: 8)
                .shadow(color: Color.blue.opacity(isEnabled ? 0.08 : 0), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .accessibilityLabel("Open route in Apple Maps")
    }
}
