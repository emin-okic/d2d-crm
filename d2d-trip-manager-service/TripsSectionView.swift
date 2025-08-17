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

    @Query private var allTrips: [Trip]
    @State private var filter: TripFilter = .week
    @State private var selectedTrip: Trip?
    @State private var showingAddTrip = false

    // NEW: multi-delete state (mirrors RecordingsView)
    @State private var isEditing = false
    @State private var selectedTrips: Set<Trip> = []
    @State private var showDeleteConfirm = false
    @State private var trashPulse = false

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

    var body: some View {
        ZStack {
            // CONTENT pinned to top-left
            VStack(alignment: .leading, spacing: 12) {

                // Filter chips (Day / Week / Month / Year)
                HStack(spacing: 8) {
                    ForEach(TripFilter.allCases) { option in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { filter = option }
                        } label: {
                            Text(option.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(filter == option ? Color.blue : Color(.secondarySystemBackground))
                                )
                                .foregroundColor(filter == option ? .white : .primary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(filter == option ? Color.blue.opacity(0.9) : Color.gray.opacity(0.25), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)

                if filteredTrips.isEmpty {
                    Text("No trips logged yet.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                } else {
                    // NEW: custom rows so we can toggle selection like RecordingsView
                    List {
                        ForEach(filteredTrips) { trip in
                            HStack(alignment: .top, spacing: 10) {
                                if isEditing {
                                    Image(systemName: selectedTrips.contains(trip) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(.blue)
                                        .padding(.top, 2)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(trip.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.gray)

                                    VStack(alignment: .leading, spacing: 6) {
                                        Label(trip.startAddress, systemImage: "circle.fill")
                                        Label(trip.endAddress, systemImage: "mappin.circle.fill")
                                        HStack {
                                            Image(systemName: "car.fill")
                                            Text("\(trip.miles, specifier: "%.1f") miles")
                                        }
                                    }
                                    .font(.subheadline)
                                }
                            }
                            .padding(.vertical, 6)
                            .background(
                                (isEditing && selectedTrips.contains(trip))
                                ? Color.red.opacity(0.06)
                                : Color.clear
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isEditing {
                                    toggleSelection(for: trip)
                                } else {
                                    selectedTrip = trip
                                }
                            }
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
        // Add Trip
        .sheet(isPresented: $showingAddTrip) {
            NewTripView { showingAddTrip = false }
        }
        // Trip details (single)
        .sheet(item: $selectedTrip) { trip in
            TripDetailsView(trip: trip)
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
