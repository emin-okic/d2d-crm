//
//  OnboardingPageView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 7/4/25.
//
import SwiftUI

struct OnboardingPageView: View {
  let page: OnboardingPage
  var body: some View {
    VStack(spacing: 24) {
      Image(systemName: page.imageName)
        .font(.system(size: 60))
        .padding()
      Text(page.title)
        .font(.title).bold()
      Text(page.description)
        .font(.body)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
  }
}
