//
//  MonthlySalesChartView.swift
//  d2d-studio
//
//  Created by Codex on 8/2/26.
//

import SwiftUI

struct MonthlySalesChartView: View {
    var body: some View {
        MapAnalyticsChartView(definition: MapScorecardDefinition(metric: .sales, period: .monthly))
    }
}
