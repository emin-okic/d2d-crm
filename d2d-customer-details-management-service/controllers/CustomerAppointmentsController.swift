//
//  CustomerAppointmentsController.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/4/26.
//
import SwiftData
import Foundation

@available(iOS 18.0, *)
final class CustomerAppointmentsController: ObservableObject {
    @Published var showAppointmentSheet: Bool = false
    @Published var selectedAppointment: Appointment?
}
