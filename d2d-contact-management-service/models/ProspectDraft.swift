//
//  ProspectDraft.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//
import Foundation

struct ProspectDraft: Identifiable {
    let id = UUID()
    var fullName: String
    var phone: String
    var email: String
    var address: String
}
