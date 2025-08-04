//
//  LogTripButtonView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/4/25.
//

import SwiftUI
import SwiftData

struct LogTripButtonView: View {
    let startAddress: String
    let endAddress: String
    let date: Date
    let onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Button("Log Trip") {
            Task {
                let miles = await TripDistanceHelper.calculateMiles(from: startAddress, to: endAddress)
                let trip = Trip(startAddress: startAddress, endAddress: endAddress, miles: miles, date: date)
                modelContext.insert(trip)
                try? modelContext.save()
                onComplete()
            }
        }
        .disabled(startAddress.isEmpty || endAddress.isEmpty)
    }
}
