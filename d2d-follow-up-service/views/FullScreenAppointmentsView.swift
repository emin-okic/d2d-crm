//
//  FullScreenAppointmentsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/28/25.
//

import SwiftUI
import SwiftData

struct FullScreenAppointmentsView: View {
    
    @Binding var isPresented: Bool
    // @Binding var selectedProspect: Prospect?
    var prospects: [Prospect]

    @State private var showProspectPicker = false
    
    @State private var showScheduleAppointment = false
    @State private var prospectToSchedule: Prospect?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomLeading) {
                AppointmentsSectionView(maxScrollHeight: UIScreen.main.bounds.height * 0.50)
                    .navigationTitle("Appointments")
                    .navigationBarTitleDisplayMode(.inline)

                // Add Appointment button on left
                Button {
                    showProspectPicker = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.blue))
                        .shadow(radius: 4)
                }
                .padding(.leading, 20)
                .padding(.bottom, 30)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isPresented = false }
                }
            }
            // Prospect Picker sheet
            .sheet(isPresented: $showProspectPicker) {
                NavigationStack {
                    List(prospects) { prospect in
                        Button {
                            prospectToSchedule = prospect
                            showProspectPicker = false
                            showScheduleAppointment = true
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(prospect.fullName)
                                Text(prospect.address)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 10)
                        }
                    }
                    .navigationTitle("Pick Prospect")
                    .listStyle(.plain)
                }
            }
            // Schedule Appointment sheet
            .sheet(isPresented: $showScheduleAppointment, onDismiss: {
                prospectToSchedule = nil
            }) {
                if let prospect = prospectToSchedule {
                    ScheduleAppointmentView(prospect: prospect)
                }
            }
        }
    }
}
