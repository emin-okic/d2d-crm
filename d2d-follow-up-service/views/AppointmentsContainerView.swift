//
//  AppointmentsContainerView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/19/25.
//


import SwiftUI

struct AppointmentsContainerView: View {
    
    @State private var isEditing = false
    @State private var selectedAppointments: Set<Appointment> = []
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

            AppointmentsSectionView(
                isEditing: $isEditing,
                selectedAppointments: $selectedAppointments,
                maxScrollHeight: UIScreen.main.bounds.height * 0.5
            )
                .padding()
        }
        .frame(height: 400) // 3 rows + padding
    }
}
