//
//  ScorecardBar.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/18/25.
//
import SwiftUI

struct ScorecardBar: View {

    var body: some View {
        HStack(spacing: 12) {
            
            DailyKnocksTrackerView()
            
            DailySalesTrackerView()

        }
        .cornerRadius(16)
        .shadow(radius: 4)
        .padding(.top, 10)
        .frame(maxWidth: .infinity, alignment: .center)
        .zIndex(1)
    }
}
