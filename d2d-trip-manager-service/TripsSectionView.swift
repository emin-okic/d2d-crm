//
//  TripsSectionView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//

import SwiftUI
import SwiftData

struct TripsSectionView: View {
    @Environment(\.modelContext) private var context
    
    @Environment(\.dismiss) private var dismiss

    @Query private var allTrips: [Trip]
    
    @State private var filter: TripFilter = .day
    @State private var selectedTrip: Trip?
    @State private var showingAddTrip = false

    // NEW: multi-delete state (mirrors RecordingsView)
    @State private var isEditing = false
    @State private var selectedTrips: Set<Trip> = []
    @State private var showDeleteConfirm = false
    @State private var trashPulse = false
    
    @State private var csvURL: IdentifiableURL?

    private var filteredTrips: [Trip] {
        let calendar = Calendar.current
        let now = Date()

        return allTrips.filter { trip in
            switch filter {
            case .day:
                return calendar.isDate(trip.date, inSameDayAs: now)
            case .week:
                guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return false }
                return trip.date >= weekAgo
            case .month:
                guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) else { return false }
                return trip.date >= monthAgo
            case .year:
                guard let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) else { return false }
                return trip.date >= yearAgo
            }
        }
        .sorted(by: { $0.date > $1.date })
    }
    
    private var chartView: some View {
        switch filter {
        case .day:
            let segments = filteredTrips.dailyMilesSegments()
            return AnyView(DailyMilesChartView(segments: segments)
                .frame(maxWidth: .infinity)
                .transition(.opacity.combined(with: .slide)))
        case .week:
            let segments = filteredTrips.weeklyMilesSegments()
            return AnyView(WeeklyMilesChartView(segments: segments)
                .frame(maxWidth: .infinity)
                .transition(.opacity.combined(with: .slide)))
        case .month:
            let segments = filteredTrips.monthlyMilesSegments()
            return AnyView(MonthlyMilesChartView(segments: segments)
                .frame(maxWidth: .infinity)
                .transition(.opacity.combined(with: .slide)))
        case .year:
            let segments = filteredTrips.yearlyMilesSegments()
            return AnyView(YearlyMilesChartView(segments: segments)
                .frame(maxWidth: .infinity)
                .transition(.opacity.combined(with: .slide)))
        default:
            return AnyView(EmptyView())
        }
    }

    var body: some View {
        ZStack {
            // CONTENT pinned to top-left
            VStack(alignment: .leading, spacing: 12) {

                // Filter chips (Day / Week / Month / Year)
                TripFilterChips(selectedFilter: $filter)

                if filteredTrips.isEmpty {
                    Text("No trips logged yet.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                } else {
                    
                    if !filteredTrips.isEmpty {
                        chartView
                    }
                    
                    // NEW: custom rows so we can toggle selection like RecordingsView
                    List {
                        ForEach(filteredTrips) { trip in
                            TripRowView(
                                trip: trip,
                                isEditing: isEditing,
                                isSelected: selectedTrips.contains(trip),
                                toggleSelection: toggleSelection(for:),
                                openDetails: { selectedTrip = $0 }
                            )
                        }
                    }
                    .listStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Floating FABs: + and Trash (matches other screens)
            VStack(spacing: 12) {
                Button {
                    showingAddTrip = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color.blue))
                        .shadow(radius: 4)
                }

                // NEW: trash button copied from RecordingsView
                Button {
                    if isEditing {
                        if selectedTrips.isEmpty {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                isEditing = false
                                trashPulse = false
                            }
                        } else {
                            showDeleteConfirm = true
                        }
                    } else {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                            isEditing = true
                            trashPulse = true
                        }
                    }
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(isEditing ? Color.red : Color.blue)
                            )
                            .scaleEffect(isEditing ? (trashPulse ? 1.06 : 1.0) : 1.0)
                            .rotationEffect(.degrees(isEditing ? (trashPulse ? 2 : -2) : 0))
                            .shadow(color: (isEditing ? Color.red.opacity(0.45) : Color.black.opacity(0.25)),
                                    radius: 6, x: 0, y: 2)
                            .animation(
                                isEditing
                                ? .easeInOut(duration: 0.75).repeatForever(autoreverses: true)
                                : .default,
                                value: trashPulse
                            )

                        if isEditing && !selectedTrips.isEmpty {
                            Text("\(selectedTrips.count)")
                                .font(.caption2).bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.black.opacity(0.7)))
                                .offset(x: 10, y: -10)
                        }
                    }
                }
                .accessibilityLabel(isEditing ? "Delete selected trips" : "Enter delete mode")
            }
            .padding(.bottom, 30)
            .padding(.leading, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .zIndex(999)
        }
        .toolbar {
            // Back button on the left
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    
                    // Haptics + sound for back navigation
                    TripManagerHapticsController.shared.lightTap()
                    TripManagerSoundController.shared.playSound1()
                    
                    dismiss()
                    
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                    }
                }
            }

            // Export CSV button on the right
            ToolbarItem(placement: .navigationBarTrailing) {
                if !filteredTrips.isEmpty {
                    ShareLink(item: csvFileURL()) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(filteredTrips.isEmpty)
                }
            }
        }
        // Add Trip
        .sheet(isPresented: $showingAddTrip) {
            NewTripView { showingAddTrip = false }
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedTrip) { trip in
            TripDetailsView(trip: trip)
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
        }
        // NEW: bulk delete confirmation
        .alert("Delete selected trips?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                deleteSelected()
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    isEditing = false
                    trashPulse = false
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action can’t be undone.")
        }
    }
    
    private func csvFileURL() -> URL {
        let fileName = "TripsExport.csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        var csvString = "Date,Start Address,End Address,Miles\n"
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"

        for trip in filteredTrips {
            let dateString = formatter.string(from: trip.date)
            let start = trip.startAddress.replacingOccurrences(of: ",", with: " ")
            let end = trip.endAddress.replacingOccurrences(of: ",", with: " ")
            let miles = String(format: "%.2f", trip.miles)
            csvString += "\(dateString),\(start),\(end),\(miles)\n"
        }

        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error exporting CSV: \(error)")
        }

        return tempURL
    }
    
    
    private func exportCSV() {
        let fileName = "TripsExport.csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        var csvString = "Date,Start Address,End Address,Miles\n"
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"

        for trip in filteredTrips {
            let dateString = formatter.string(from: trip.date)
            let start = trip.startAddress.replacingOccurrences(of: ",", with: " ")
            let end = trip.endAddress.replacingOccurrences(of: ",", with: " ")
            let miles = String(format: "%.2f", trip.miles)
            csvString += "\(dateString),\(start),\(end),\(miles)\n"
        }

        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            csvURL = IdentifiableURL(url: tempURL)
        } catch {
            print("Error exporting CSV: \(error)")
        }
    }

    // MARK: - Helpers

    private func toggleSelection(for trip: Trip) {
        if selectedTrips.contains(trip) { selectedTrips.remove(trip) }
        else { selectedTrips.insert(trip) }
    }

    private func deleteSelected() {
        for trip in selectedTrips {
            context.delete(trip)
        }
        try? context.save()
        selectedTrips.removeAll()
    }
}

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}
