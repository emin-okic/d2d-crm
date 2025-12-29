//
//  OpenInAppleMapsButton.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/29/25.
//

import SwiftUI
import SwiftData

struct OpenInAppleMapsButton: View {
    var appointments: [Appointment]
    @Environment(\.modelContext) private var modelContext
    var buttonColor: Color = .blue
    var size: CGFloat = 50

    var body: some View {
        Button {
            Task {
                if appointments.isEmpty {
                    print("No appointments to navigate")
                    return
                }
                await RoutePlannerController.planAndOpenTodaysRoute(
                    appointments: appointments,
                    modelContext: modelContext
                )
            }
        } label: {
            Image(systemName: "car.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(RoundedRectangle(cornerRadius: 12).fill(buttonColor))
                .shadow(radius: 4)
        }
    }
}
