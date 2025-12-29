//
//  Demographics.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/29/25.
//

import SwiftData
import Foundation

@Model
final class Demographics {
    @Attribute(.unique) var id: UUID = UUID()
    
    var age: Int?
    var gender: String? // "Male", "Female", anything else is a characteristic trait
    var incomeLevel: String? // "Low", "Medium", "High", or freeform
    var education: String? // e.g., "High School", "Bachelor's", "Master's"
    var occupation: String?
    
    // Link back to the prospect
    @Relationship var prospect: Prospect?
    
    init(
        age: Int? = nil,
        gender: String? = nil,
        incomeLevel: String? = nil,
        education: String? = nil,
        occupation: String? = nil
    ) {
        self.age = age
        self.gender = gender
        self.incomeLevel = incomeLevel
        self.education = education
        self.occupation = occupation
    }
}
