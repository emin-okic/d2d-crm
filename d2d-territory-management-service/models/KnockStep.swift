//
//  KnockStep.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/21/25.
//

enum KnockStep: Equatable {
    case outcome                               // required
    case objection                             // required (only for follow-up)
    case scheduleFollowUp                      // required (only for follow-up)
    case convertToCustomer                     // required (only for conversion)
    case note                                  // optional
    case trip                                  // optional
    case done
}
