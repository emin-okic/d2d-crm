//
//  HourlyKnockBucket.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//
import Foundation
import SwiftData

struct HourlyKnockBucket: Identifiable {
    let id = UUID()
    let hour: Int
    let count: Int
}
