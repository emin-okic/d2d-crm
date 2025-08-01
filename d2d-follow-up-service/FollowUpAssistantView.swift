//
//  ProfileView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/31/25.
//
import SwiftUI
import Charts
import SwiftData
import WidgetKit

struct FollowUpAssistantView: View {
    @Query private var prospects: [Prospect]
    @Query private var trips: [Trip]
    
    @State private var selectedObjection: Objection?
    @State private var showingAddObjection = false
    
    @Query private var appointments: [Appointment]
    
    @State private var showTripsSheet = false
    
    @State private var showTodaysAppointmentsSheet = false
    
    @State private var selectedTab: FollowUpTab = .appointments
    
    enum FollowUpTab: String, CaseIterable {
        case appointments = "Appointments"
        case recordings = "Recent Conversations"
    }
    
    private var appointmentsToday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return appointments.filter { calendar.isDate($0.date, inSameDayAs: today) }.count
    }

    private var appointmentsThisWeek: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!

        return appointments.filter { $0.date >= startOfWeek && $0.date < endOfWeek }.count
    }

    var body: some View {
        let totalKnocks = FollowUpAssistantController.totalKnocks(from: prospects)
        let answeredVsUnanswered = FollowUpAssistantController.knocksAnsweredVsUnanswered(from: prospects)

        let totalProspects = prospects.count
        let totalCustomers = prospects.filter { $0.list == "Customers" }.count
        
        let totalMiles = trips.reduce(0) { $0 + $1.miles }
        let totalTrips = trips.count
        
        let averageKnocksPerCustomer: Double = {
            let customerKnocks = prospects
                .filter { $0.list == "Customers" }
                .map { $0.knockHistory.count }
            guard !customerKnocks.isEmpty else { return 0 }
            return Double(customerKnocks.reduce(0, +)) / Double(customerKnocks.count)
        }()

        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: - Custom Header
                    HStack {
                        Text("The Follow-Up Assistant")
                            .font(.title)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // MARK: - Summary Cards
                    VStack(spacing: 12) {
                        // Appointments Scorecards
                        HStack(spacing: 12) {
                            Button {
                                showTodaysAppointmentsSheet = true
                            } label: {
                                LeaderboardCardView(title: "Appointments Today", count: appointmentsToday)
                            }
                            .buttonStyle(.plain)

                            Button {
                                showTripsSheet = true
                            } label: {
                                LeaderboardCardView(title: "Trips Made This Week", count: totalTrips)
                            }
                            .buttonStyle(.plain) // So it looks like a card, not a button
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    ObjectionsSectionView()
                    
                    // MARK: - Tab Selector
                    Picker("View", selection: $selectedTab) {
                        ForEach(FollowUpTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    // MARK: - Tab Content
                    Group {
                        switch selectedTab {
                        case .appointments:
                            AppointmentsSectionView()
                                .frame(minHeight: 300) // Enough to render content
                        case .recordings:
                            RecordingsView()
                        }
                    }
                    

                }
                .padding(.bottom, 20)
            }
            .onAppear {
                let defaults = UserDefaults(suiteName: "group.okic.d2dcrm")
                defaults?.set(appointmentsToday, forKey: "appointmentsToday")
                WidgetCenter.shared.reloadAllTimelines()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showTripsSheet) {
                NavigationView {
                    TripsSectionView()
                        .navigationTitle("Trips")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showTripsSheet = false
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showTodaysAppointmentsSheet) {
                NavigationStack {
                    TodaysAppointmentsView()
                        .navigationTitle("Today's Appointments")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showTodaysAppointmentsSheet = false
                                }
                            }
                        }
                }
            }
        }
    }

    private var milesByDay: [(date: Date, miles: Double)] {
        let calendar = Calendar.current
        let now = Date()

        let startOfToday = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: startOfToday)
        let daysFromMonday = (weekday + 5) % 7
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: startOfToday) else { return [] }

        var result: [Date: Double] = [:]
        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                result[calendar.startOfDay(for: day)] = 0
            }
        }

        let grouped = Dictionary(grouping: trips) { calendar.startOfDay(for: $0.date) }

        for (day, tripsOnDay) in grouped {
            if result[day] != nil {
                result[day]! += tripsOnDay.reduce(0) { $0 + $1.miles }
            }
        }

        return result.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
    }
}
