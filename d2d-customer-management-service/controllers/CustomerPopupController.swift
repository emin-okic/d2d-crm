//
//  CustomerPopupController.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/25/25.
//

import Foundation
import SwiftUI

@MainActor
class CustomerPopupController: ObservableObject {
    static let shared = CustomerPopupController()

    @Published var popupCustomer: Customer?
    @Published var popupKey: UUID = UUID()
    @Published var popupKeyVersion: Int = 0
    @Published var popupScreenPosition: CGPoint?

    func open(for customer: Customer) {
        popupCustomer = customer
        popupKey = UUID()
        popupKeyVersion += 1
        popupScreenPosition = nil   // or calculate based on list tap, if needed
    }

    func close() {
        popupCustomer = nil
    }
}
