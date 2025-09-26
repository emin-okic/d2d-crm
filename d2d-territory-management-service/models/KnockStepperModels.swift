//
//  KnockStepperModels.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/11/25.
//

import SwiftUI
import SwiftData
import MapKit

struct KnockContext: Equatable {
    var address: String
    var isCustomer: Bool
    var prospect: Prospect?
}

enum KnockOutcome: String, CaseIterable {
    case wasntHome = "Wasn't Home"
    case convertedToSale = "Converted To Sale"
    case followUpLater = "Follow Up Later"
}

enum KnockStep: Equatable {
    case outcome                               // required
    case objection                             // required (only for follow-up)
    case scheduleFollowUp                      // required (only for follow-up)
    case convertToCustomer                     // required (only for conversion)
    case note                                  // optional
    case trip                                  // optional
    case done
}
