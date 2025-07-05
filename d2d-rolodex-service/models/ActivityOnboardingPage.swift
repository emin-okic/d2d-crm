//
//  ActivityOnboardingPage.swift
//  d2d-map-service
//
//  Created by Emin Okic on 7/5/25.
//
import SwiftUI
import SwiftData

struct ActivityOnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let chartView: AnyView
}
