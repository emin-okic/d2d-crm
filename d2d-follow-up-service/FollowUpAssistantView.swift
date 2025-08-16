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
    
    @AppStorage("recordingModeEnabled") private var recordingModeEnabled: Bool = true
    @AppStorage("studioUnlocked") private var studioUnlocked: Bool = false
    private var recordingFeaturesActive: Bool { studioUnlocked && recordingModeEnabled }
    
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
    
    // 1) Add these to FollowUpAssistantView
    @State private var showTopObjectionsSheet = false
    @Query private var objections: [Objection]
    
    // 2) Compute the top objection (exclude "Converted To Sale")
    private var topObjectionText: String {
        objections
            .filter { $0.text != "Converted To Sale" }
            .sorted { $0.timesHeard > $1.timesHeard }
            .first?.text ?? "—"
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
                                LeaderboardCardView(title: "Trips Made", count: totalTrips)
                            }
                            .buttonStyle(.plain) // So it looks like a card, not a button
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 3) Insert this right BELOW your HStack of two scorecards
                    Button {
                        showTopObjectionsSheet = true
                    } label: {
                        LeaderboardTextCardView(title: "Top Objection", text: topObjectionText)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    
                    // MARK: - Tab Selector
                    // Show the segmented control only when recording features are active
                    if recordingFeaturesActive {
                        Picker("View", selection: $selectedTab) {
                            ForEach(FollowUpTab.allCases, id: \.self) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)
                    }

                    // Tab content: never show recordings when locked or off
                    Group {
                        if recordingFeaturesActive {
                            switch selectedTab {
                            case .appointments:
                                AppointmentsSectionView().frame(minHeight: 300)
                            case .recordings:
                                RecordingsView()
                            }
                        } else {
                            AppointmentsSectionView().frame(minHeight: 300)
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
            // Add the sheet (same pattern as Trips/Today's Appointments)
            .sheet(isPresented: $showTopObjectionsSheet) {
                NavigationStack {
                    ObjectionsSectionView()
                        .navigationTitle("Top Objections")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showTopObjectionsSheet = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $showTripsSheet) {
                NavigationView {
                    TripsSectionView()
                        .navigationTitle("Trips")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) { // right side
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
                            ToolbarItem(placement: .confirmationAction) { // right side
                                Button("Done") {
                                    showTodaysAppointmentsSheet = false
                                }
                            }
                        }
                }
            }
            
        }
    }
}
