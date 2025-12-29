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
    
    @Environment(\.modelContext) private var modelContext
    
    @Query private var prospects: [Prospect]
    @Query private var trips: [Trip]
    @Query private var appointments: [Appointment]
    @Query private var objections: [Objection]

    // Existing sheets
    @State private var showTripsSheet = false
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

    private var topObjectionText: String {
        objections
            .filter { $0.text != "Converted To Sale" }
            .sorted { $0.timesHeard > $1.timesHeard }
            .first?.text ?? "—"
    }

    // promo/walkthrough celebration state (same flow as Map)
    @State private var showPromo = false
    @State private var showWalkthrough = false
    @State private var showCelebration = false
    
    @State private var showAppointmentsFullScreen = false
    
    @State private var showFullScreenProspectPicker = false
    
    private var dailyTrips: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return trips.filter {
            calendar.isDate($0.date, inSameDayAs: today)
        }.count
    }
    
    @Query private var recordings: [Recording]
    
    // MARK: - Appointment toolbar state
    @State private var isEditingAppointments = false
    @State private var selectedAppointments: Set<Appointment> = []
    @State private var showDeleteAppointmentsConfirm = false
    @State private var showAppointmentsPicker = false
    
    @State private var filteredAppointments: [Appointment] = []

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: - Header
                        HStack {
                            Text("Follow Up Assistant")
                                .font(.title)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // MARK: - Summary Cards
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                
                                // Recordings scorecard (NEW)
                                Button {
                                    if studioUnlocked {
                                        showRecordingsSheet = true
                                    } else {
                                        showPromo = true
                                    }
                                } label: {
                                    RecordingsScorecardView(
                                        unlocked: studioUnlocked,
                                        count: recordings.count
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                Button {
                                    showTripsSheet = true
                                } label: {
                                    LeaderboardCardView(
                                        title: "Trips Today",
                                        count: dailyTrips
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)

                        // MARK: - Appointments
                        // AppointmentsSectionView already scrolls and is clamped to 300pt
                        ScrollView {
                            ZStack(alignment: .topTrailing) {
                                AppointmentsContainerView(
                                    isEditing: $isEditingAppointments,
                                    selectedAppointments: $selectedAppointments,
                                    filteredAppointments: $filteredAppointments
                                )
                                .padding(.horizontal, 20)
                                .frame(maxHeight: 500)
                                
                                // Expand button
                                Button {
                                    showAppointmentsFullScreen = true
                                } label: {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.system(size: 18, weight: .semibold))
                                        .padding(10)
                                        .background(Color(.systemGray5).opacity(0.9))
                                        .clipShape(Circle())
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 30)
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxHeight: 700)
                    }
                    .padding(.bottom, 5)
                }
                
                
                // Floating Apple Maps button
                if !appointments.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            OpenInAppleMapsButton(
                                appointments: appointments.filter { Calendar.current.isDate($0.date, inSameDayAs: Date()) }
                            )
                            .padding(.bottom, 30)
                            .padding(.trailing, 20)
                        }
                    }
                    .zIndex(998)
                }
                
                AppointmentsToolbar(
                    showProspectPicker: $showAppointmentsPicker,
                    isEditing: $isEditingAppointments,
                    selectedAppointments: $selectedAppointments,
                    showDeleteConfirm: $showDeleteAppointmentsConfirm
                )
                
            }
            .onAppear {
                let defaults = UserDefaults(suiteName: "group.okic.d2dcrm")
                defaults?.set(appointmentsToday, forKey: "appointmentsToday")
                WidgetCenter.shared.reloadAllTimelines()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)

            // SHEETS
            .sheet(isPresented: $showAppointmentsPicker) {
                NavigationStack {
                    List(prospects) { prospect in
                        Button {
                            selectedProspect = prospect
                            showAppointmentsPicker = false
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
            .alert("Delete selected appointments?", isPresented: $showDeleteAppointmentsConfirm) {
                Button("Delete", role: .destructive) {
                    deleteSelectedAppointments()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action can’t be undone.")
            }
            .sheet(isPresented: $showAppointmentsFullScreen) {
                FullScreenAppointmentsView(
                    isPresented: $showAppointmentsFullScreen,
                    prospects: prospects
                )
            }
            // Promo to request App Store review → unlock
            .sheet(isPresented: $showPromo) {
                RecordingStudioPromo {
                    // onUnlock callback
                    studioUnlocked = true
                    showPromo = false
                    showCelebration = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        showCelebration = false
                        showWalkthrough = true
                    }
                }
            }

            // Quick walkthrough after unlocking
            .sheet(isPresented: $showWalkthrough) {
                RecordingStudioWalkthrough { showWalkthrough = false }
            }

            // Full-screen confetti celebration when unlocked
            .fullScreenCover(isPresented: $showCelebration) {
                FullScreenCelebrationView(dimOpacity: 0.08)
            }

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
                        .navigationTitle("Recording Studio")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
    
    private func deleteSelectedAppointments() {
        withAnimation {
            let toDelete = selectedAppointments
            selectedAppointments.removeAll()
            for appt in toDelete {
                modelContext.delete(appt)
            }
            do {
                try modelContext.save()
            } catch {
                print("Error saving after deletion: \(error)")
            }
            isEditingAppointments = false
        }
    }
}
