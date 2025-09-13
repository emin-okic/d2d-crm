//
//  AchievementProgress.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/13/25.
//
import SwiftUI
import SwiftData

@Model
class Achievements {
    var id: String
    var goalCount: Int
    var currentCount: Int
    var isCompleted: Bool

    init(id: String, goalCount: Int, currentCount: Int = 0, isCompleted: Bool = false) {
        self.id = id
        self.goalCount = goalCount
        self.currentCount = currentCount
        self.isCompleted = isCompleted
    }
}
