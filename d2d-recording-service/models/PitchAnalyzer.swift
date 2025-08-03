//
//  PitchAnalyzer.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/1/25.
//
import Foundation
import SwiftData

class PitchAnalyzer {
    func score(user: String, expected: String) -> Int {
        let userWords = Set(user.lowercased().split(separator: " "))
        let expectedWords = Set(expected.lowercased().split(separator: " "))
        let intersection = userWords.intersection(expectedWords)

        let similarity = Double(intersection.count) / Double(expectedWords.count)

        switch similarity {
        case ..<0.2: return 1
        case ..<0.4: return 2
        case ..<0.6: return 3
        case ..<0.8: return 4
        default: return 5
        }
    }
}
