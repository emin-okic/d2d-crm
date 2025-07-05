//
//  OnboardingPage.swift
//  d2d-map-service
//
//  Created by Emin Okic on 7/4/25.
//
import SwiftUI

struct OnboardingPage: Identifiable {
  let id = UUID()
  let imageName: String
  let title: String
  let description: String
}

let onboardingPages = [
  OnboardingPage(imageName: "map.fill", title: "Track Locations", description: "Search and log knocks right from the map."),
  OnboardingPage(imageName: "person.3.fill", title: "Manage Prospects", description: "View and update prospect info all in one place."),
  OnboardingPage(imageName: "waveform", title: "Record Objections", description: "Record, score, and review objection handlers.")
]
