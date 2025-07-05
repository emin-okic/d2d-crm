//
//  OnboardingFlowView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 7/4/25.
//
import SwiftUI

struct OnboardingFlowView: View {
  @Binding var isPresented: Bool
  @State private var currentPage = 0

  var body: some View {
    VStack {
      TabView(selection: $currentPage) {
        ForEach(Array(onboardingPages.enumerated()), id: \.element.id) { idx, page in
          OnboardingPageView(page: page)
           .tag(idx)
        }
      }
      .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
      .edgesIgnoringSafeArea(.all)

      Button(action: {
        if currentPage < onboardingPages.count - 1 {
          currentPage += 1
        } else {
          isPresented = false
        }
      }) {
        Text(currentPage < onboardingPages.count - 1 ? "Next" : "Get Started")
          .bold()
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(10)
          .padding()
      }
    }
  }
}
