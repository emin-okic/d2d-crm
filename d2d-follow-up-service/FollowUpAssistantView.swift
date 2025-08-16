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
    @Query private var appointments: [Appointment]
    @Query private var objections: [Objection]

    // Existing sheets
    @State private var showTripsSheet = false
    @State private var showTodaysAppointmentsSheet = false
    @State private var showTopObjectionsSheet = false

    // NEW: floating toolbar sheets
    @State private var showingProspectPicker = false
    @State private var selectedProspect: Prospect?
    @State private var showRecordingsSheet = false

    // Recording feature gate (unchanged)
    @AppStorage("recordingModeEnabled") private var recordingModeEnabled: Bool = true
    @AppStorage("studioUnlocked") private var studioUnlocked: Bool = false
    private var recordingFeaturesActive: Bool { studioUnlocked && recordingModeEnabled }

    private var appointmentsToday: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return appointments.filter { cal.isDate($0.date, inSameDayAs: today) }.count
    }

    private var totalTrips: Int { trips.count }

    private var topObjectionText: String {
        objections
            .filter { $0.text != "Converted To Sale" }
            .sorted { $0.timesHeard > $1.timesHeard }
            .first?.text ?? "—"
    }

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: - Header
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
                            HStack(spacing: 12) {
                                Button { showTodaysAppointmentsSheet = true } label: {
                                    LeaderboardCardView(title: "Appointments Today", count: appointmentsToday)
                                }
                                .buttonStyle(.plain)

                                Button { showTripsSheet = true } label: {
                                    LeaderboardCardView(title: "Trips Made", count: totalTrips)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Top Objection scorecard
                        Button { showTopObjectionsSheet = true } label: {
                            LeaderboardTextCardView(title: "Top Objection", text: topObjectionText)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)

                        // MARK: - Appointments (no tabs now)
                        // AppointmentsSectionView already scrolls and is clamped to 300pt
                        ScrollView {
                            AppointmentsSectionView()
                        }
                        .frame(maxHeight: 400)
                    }
                    .padding(.bottom, 20)
                }

                // MARK: - Floating bottom-left toolbar (Mic above +)
                VStack(spacing: 12) {
                    // Mic (opens RecordingsView)
                    Button {
                        showRecordingsSheet = true
                    } label: {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.blue))
                            .shadow(radius: 4)
                    }

                    // Plus (opens Prospect picker -> Schedule)
                    Button {
                        showingProspectPicker = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.blue))
                            .shadow(radius: 4)
                    }
                }
                .padding(.bottom, 30)
                .padding(.leading, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .zIndex(999)
            }
            .onAppear {
                let defaults = UserDefaults(suiteName: "group.okic.d2dcrm")
                defaults?.set(appointmentsToday, forKey: "appointmentsToday")
                WidgetCenter.shared.reloadAllTimelines()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)

            // SHEETS

            // Top Objections
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

            // Trips
            .sheet(isPresented: $showTripsSheet) {
                NavigationView {
                    TripsSectionView()
                        .navigationTitle("Trips")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showTripsSheet = false }
                            }
                        }
                }
            }

            // Today's appointments
            .sheet(isPresented: $showTodaysAppointmentsSheet) {
                NavigationStack {
                    TodaysAppointmentsView()
                        .navigationTitle("Today's Appointments")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showTodaysAppointmentsSheet = false }
                            }
                        }
                }
            }

            // NEW: Prospect picker for scheduling
            .sheet(isPresented: $showingProspectPicker) {
                NavigationStack {
                    List(prospects) { prospect in
                        Button {
                            selectedProspect = prospect
                            showingProspectPicker = false
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(prospect.fullName)
                                Text(prospect.address)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 10)
                        }
                    }
                    .navigationTitle("Pick Prospect")
                    .listStyle(.plain)
                }
            }
            .sheet(item: $selectedProspect) { p in
                // You can pass a default date if you like
                ScheduleAppointmentView(prospect: p)
            }

            // NEW: Recordings sheet
            .sheet(isPresented: $showRecordingsSheet) {
                NavigationStack {
                    RecordingsView()
                        .navigationTitle("The Recording Studio")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showRecordingsSheet = false }
                            }
                        }
                }
            }
        }
    }
}
