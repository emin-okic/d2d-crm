//
//  KnockContext.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/21/25.
//

import SwiftData

struct KnockContext: Equatable {
    var address: String
    var isCustomer: Bool
    var prospect: Prospect?
}
