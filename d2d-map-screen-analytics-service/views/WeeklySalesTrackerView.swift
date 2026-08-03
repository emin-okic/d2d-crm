//
//  WeeklySalesTrackerView.swift
//  d2d-studio
//
//  Created by Codex on 8/2/26.
//

import SwiftUI

struct WeeklySalesTrackerView: View {
    var isExpanded: Bool = false
    var isCustomizationActive: Bool = false

    var body: some View {
        MapAnalyticsTrackerView(
            definition: MapScorecardDefinition(metric: .sales, period: .weekly),
            isExpanded: isExpanded,
            isCustomizationActive: isCustomizationActive
        )
    }
}
