//
//  DailyKnockHourlyChartView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//

import SwiftUI

struct DailyKnockHourlyChartView: View {
    var body: some View {
        MapAnalyticsChartView(definition: MapScorecardDefinition(metric: .knocks, period: .daily))
    }
}
