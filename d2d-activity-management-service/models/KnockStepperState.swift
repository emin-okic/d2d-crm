//
//  KnockStepperState.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/20/26.
//

import Foundation

struct KnockStepperState: Identifiable, Equatable {
    let id: UUID
    var ctx: KnockContext

    init(id: UUID = UUID(), ctx: KnockContext) {
        self.id = id
        self.ctx = ctx
    }
}
