//
//  MonthlyKnocksChartView.swift
//  d2d-studio
//
//  Created by Codex on 8/2/26.
//

import SwiftUI

struct MonthlyKnocksChartView: View {
    var body: some View {
        MapAnalyticsChartView(definition: MapScorecardDefinition(metric: .knocks, period: .monthly))
    }
}
