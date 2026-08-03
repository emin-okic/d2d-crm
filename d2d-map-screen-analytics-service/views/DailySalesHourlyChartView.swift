//
//  DailySalesHourlyChartView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//

import SwiftUI

struct DailySalesHourlyChartView: View {
    var body: some View {
        MapAnalyticsChartView(definition: MapScorecardDefinition(metric: .sales, period: .daily))
    }
}
