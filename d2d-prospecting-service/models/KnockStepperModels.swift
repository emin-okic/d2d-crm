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

// In MapSearchView: add these properties

// Replace places where you previously showed alerts (map tap or marker tap) with:
// self.stepperState = .init(ctx: .init(address: tappedAddress, isCustomer: isTappedAddressCustomer, prospect: nil))

// Then add this overlay to MapSearchView's body ZStack:
/*
.overlay(
    Group {
        if let s = stepperState {
            KnockStepperPopupView(
                context: s.ctx,
                objections: objections,
                saveKnock: { outcome in
                    let status = outcome.rawValue
                    let p = knockController!.saveKnockOnly(address: s.ctx.address, status: status, prospects: prospects) {
                        updateMarkers()
                    }
                    return p
                },
                incrementObjection: { obj in
                    obj.timesHeard += 1
                    try? modelContext.save()
                },
                saveFollowUp: { prospect, date in
                    let appt = Appointment(
                        title: "Follow-Up",
                        location: prospect.address,
                        clientName: prospect.fullName,
                        date: date,
                        type: "Follow-Up",
                        notes: prospect.notes.map { $0.content },
                        prospect: prospect
                    )
                    modelContext.insert(appt)
                    try? modelContext.save()
                },
                convertToCustomer: { prospect, done in
                    // Reuse your existing conversion sheet for the heavy lifting
                    self.prospectToConvert = prospect
                    self.showConversionSheet = true
                    done()
                },
                addNote: { prospect, text in
                    prospect.notes.append(Note(content: text))
                    try? modelContext.save()
                },
                logTrip: { start, end, date in
                    guard !end.isEmpty else { return }
                    let trip = Trip(startAddress: start, endAddress: end, miles: 0, date: date)
                    modelContext.insert(trip)
                    try? modelContext.save()
                },
                onClose: { self.stepperState = nil }
            )
            .frame(maxWidth: 340)
            .position(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.height * 0.42)
            .transition(.scale.combined(with: .opacity))
            .zIndex(1000)
        }
    }
)
*/

// And ensure your existing .sheet for showConversionSheet stays in MapSearchView.
