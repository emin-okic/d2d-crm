//
//  AddressGroup.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/10/26.
//

struct AddressGroup {
    let base: String
    var units: [String?: [UnitContact]]   // nil = no unit
}
