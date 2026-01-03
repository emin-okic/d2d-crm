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
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(isEnabled ? Color.blue : Color.gray.opacity(0.45))
                )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .accessibilityLabel("Open route in Apple Maps")
    }
}
