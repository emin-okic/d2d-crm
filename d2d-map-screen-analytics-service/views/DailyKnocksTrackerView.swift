//
//  DailyKnocksTrackerView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//

import SwiftUI

struct DailyKnocksTrackerView: View {
    var isExpanded: Bool = false
    var isCustomizationActive: Bool = false

    var body: some View {
        MapAnalyticsTrackerView(
            definition: MapScorecardDefinition(metric: .knocks, period: .daily),
            isExpanded: isExpanded,
            isCustomizationActive: isCustomizationActive
        )
    }
}
