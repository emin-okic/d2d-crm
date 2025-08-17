//
//  MapSearchView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//  Stepper-integrated version (shows KnockStepperPopupView ONLY for Follow-Up Later)
//

import SwiftUI
import MapKit
import CoreLocation
import SwiftData
import Combine
import Contacts

struct MapSearchView: View {
    @Binding var searchText: String
    @Binding var region: MKCoordinateRegion
    @Binding var selectedList: String
    @Binding var addressToCenter: String?

    @Query private var prospects: [Prospect]
    @Query private var customers: [Customer]
    @Query private var objections: [Objection]

    @StateObject private var controller: MapController

    // Existing prompt/flow state
    @State private var pendingAddress: String?
    @State private var showOutcomePrompt = false
    @State private var showNoteInput = false
    @State private var prospectToNote: Prospect?

    @State private var showObjectionPicker = false
    @State private var objectionOptions: [Objection] = []
    @State private var selectedObjection: Objection?
    @State private var showingAddObjection = false

    @State private var showConversionSheet = false
    @State private var prospectToConvert: Prospect?

    @State private var showTripPrompt = false
    @State private var showTripPopup = false

    @State private var showFollowUpSheet = false
    @State private var followUpAddress: String = ""
    @State private var followUpProspectName: String = ""
    @State private var showFollowUpPrompt = false

    @State private var shouldAskForTripAfterFollowUp = false

    @StateObject private var tapManager = MapTapAddressManager()
    @StateObject private var searchVM = SearchCompleterViewModel()
    @FocusState private var isSearchFocused: Bool

    @State private var isTappedAddressCustomer = false

    struct PopupState: Identifiable, Equatable {
        let id = UUID()
        let place: IdentifiablePlace
        static func == (lhs: PopupState, rhs: PopupState) -> Bool { lhs.id == rhs.id }
    }

    @State private var popupState: PopupState?
    @State private var popupScreenPosition: CGPoint? = nil

    @State private var isSearchExpanded = false
    @Namespace private var animationNamespace

    @Environment(\.modelContext) private var modelContext

    @State private var pendingRecordingFileName: String?

    @AppStorage("recordingModeEnabled") private var recordingModeEnabled: Bool = true
    @AppStorage("studioUnlocked") private var studioUnlocked: Bool = false
    private var recordingFeaturesActive: Bool { studioUnlocked && recordingModeEnabled }

    @State private var knockController: KnockActionController? = nil

    // NEW: Stepper state (only used for Follow-Up Later)
    @State private var stepperState: KnockStepperState? = nil
    
    private var hasCustomers: Bool {
        // Show KP/S if *either* there is at least one Prospect flagged as a customer,
        // or at least one Customer record exists.
        !customers.isEmpty || prospects.contains { $0.list == "Customers" }
    }
    
    private var totalKnocks: Int { prospects.flatMap { $0.knockHistory }.count }
    
    private var averageKnocksPerCustomer: Int {
        // Prefer prospects that have been flipped to Customers; if none, fall back to Customer models
        let countsFromProspects = prospects
            .filter { $0.list == "Customers" }
            .map { $0.knockHistory.count }

        let countsFromCustomers = customers
            .map { $0.knockHistory.count }

        let counts = !countsFromProspects.isEmpty ? countsFromProspects : countsFromCustomers
        guard !counts.isEmpty else { return 0 }
        return Int(Double(counts.reduce(0, +)) / Double(counts.count))
    }
    
    @State private var showConfetti = false
    
    init(searchText: Binding<String>,
         region: Binding<MKCoordinateRegion>,
         selectedList: Binding<String>,
         addressToCenter: Binding<String?>) {
        _searchText = searchText
        _region = region
        _selectedList = selectedList
        _addressToCenter = addressToCenter
        _controller = StateObject(wrappedValue: MapController(region: region.wrappedValue))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {

                MapDisplayView(
                    region: $controller.region,
                    markers: controller.markers,
                    onMarkerTapped: { place in
                        // Keep ProspectPopupView behavior as-is
                        let state = PopupState(place: place)
                        popupState = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { popupState = state }

                        if let mapView = MapDisplayView.cachedMapView {
                            let raw = mapView.convert(place.location, toPointTo: mapView)
                            let popupW: CGFloat = 240
                            let halfW = popupW / 2
                            let halfH: CGFloat = 60
                            let offsetY = halfH + 14
                            let x = min(max(raw.x, halfW), geo.size.width - halfW)
                            let y = min(max(raw.y - offsetY, halfH), geo.size.height - halfH)
                            popupScreenPosition = CGPoint(x: x, y: y)
                        }
                    },
                    onMapTapped: { coordinate in
                        // Keep existing alert for outcomes
                        tapManager.handleTap(at: coordinate)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            let tapped = tapManager.tappedAddress
                            if !tapped.isEmpty {
                                pendingAddress = tapped
                                isTappedAddressCustomer = customers.contains {
                                    $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
                                    tapped.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                                showOutcomePrompt = true
                            }
                        }
                    },
                    onRegionChange: { newRegion in
                        controller.region = newRegion
                        if popupState != nil { popupState = nil }
                    }
                )
                .frame(maxHeight: .infinity)
                .edgesIgnoringSafeArea(.horizontal)

                ScorecardBar(
                    totalKnocks: totalKnocks,
                    avgKnocksPerSale: averageKnocksPerCustomer,
                    hasSignedUp: hasCustomers   // ← was: hasSignedUp
                )

                prospectPopup

                FloatingSearchAndMicButtons(
                    searchText: $searchText,
                    isExpanded: $isSearchExpanded,
                    isFocused: $isSearchFocused,
                    viewModel: searchVM,
                    animationNamespace: animationNamespace,
                    onSubmit: { submitSearch() },
                    onSelectResult: { handleCompletionTap($0) }
                )
            }
            // Stepper overlay — presented ONLY when stepperState is set (Follow-Up Later path)
            .overlay(
              Group {
                if let s = stepperState {
                    KnockStepperPopupView(
                      context: s.ctx,
                      objections: objections,
                      saveKnock: { outcome in
                        knockController!.saveKnockOnly(
                          address: s.ctx.address,
                          status: outcome.rawValue,
                          prospects: prospects,
                          onUpdateMarkers: { updateMarkers() }
                        )
                      },
                      // ⬇️ Attach deferred recording when an objection is selected
                      incrementObjection: { obj in
                        obj.timesHeard += 1

                        if recordingFeaturesActive, let name = pendingRecordingFileName {
                          let rec = Recording(fileName: name, date: .now, objection: obj, rating: 3)
                          modelContext.insert(rec)
                          pendingRecordingFileName = nil
                        }

                        try? modelContext.save()
                      },
                      saveFollowUp: { prospect, date in
                          let appt = Appointment(
                            title: "Follow-Up",
                            location: prospect.address,
                            clientName: prospect.fullName,
                            date: date,
                            type: "Follow-Up",
                            notes: prospect.notes.map { $0.content },
                            prospect: prospect
                          )
                          modelContext.insert(appt)
                          try? modelContext.save()
                      },
                      convertToCustomer: { prospect, done in
                        self.prospectToConvert = prospect
                        self.showConversionSheet = true
                        done()
                      },
                      addNote: { prospect, text in
                        prospect.notes.append(Note(content: text))
                        try? modelContext.save()
                      },
                      logTrip: { start, end, date in
                        guard !end.isEmpty else { return }
                        let trip = Trip(startAddress: start, endAddress: end, miles: 0, date: date)
                        modelContext.insert(trip)
                        try? modelContext.save()
                      },
                      onClose: {
                          self.stepperState = nil
                          // 🎉 Confetti only now, after stepper has been dismissed
                          withAnimation { showConfetti = true }
                      }
                    )
                  .frame(width: 280, height: 280) // ⬅️ hard clamp
                  .position(x: geo.size.width / 2, y: geo.size.height * 0.42)
                  .transition(.scale.combined(with: .opacity))
                  .zIndex(1000)
                }
              }
            )
            
            if showConfetti {
                ConfettiBurstView()
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(5000)
                    .onAppear {
                        // Auto dismiss after a few seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { showConfetti = false }
                        }
                    }
            }
            
        }
        .onReceive(NotificationCenter.default.publisher(for: .mapShouldRecenterAllMarkers)) { _ in
                    controller.recenterToFitAllMarkers()
                }
        .onChange(of: searchText) { searchVM.updateQuery($0) }
        .onAppear {
            updateMarkers()
            knockController = KnockActionController(modelContext: modelContext, controller: controller)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(name: .mapShouldRecenterAllMarkers, object: nil)
                }
            
        }
        .onChange(of: prospects) { _ in updateMarkers() }
        .onChange(of: selectedList) { _ in updateMarkers() }
        .onChange(of: addressToCenter) { handleMapCenterChange(newAddress: $0) }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil,from:nil,for:nil)
        }
        // Keep existing sheets/alerts; they simply won't be used during Follow-Up stepper
        .alert("Knock Outcome", isPresented: $showOutcomePrompt) {
            if !isTappedAddressCustomer {
                Button("Converted To Sale") {
                    if let addr = pendingAddress {
                        knockController?.handleKnockAndConvertToCustomer(
                            address: addr,
                            status: "Converted To Sale",
                            prospects: prospects,
                            onUpdateMarkers: { updateMarkers() },
                            onSetCustomerMarker: {
                                if let index = controller.markers.firstIndex(where: {
                                    $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
                                    addr.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                                }) {
                                    controller.markers[index] = IdentifiablePlace(
                                        address: addr,
                                        location: controller.markers[index].location,
                                        count: controller.markers[index].count,
                                        list: "Customers"
                                    )
                                }
                            },
                            onShowConversionSheet: { prospect in
                                prospectToConvert = prospect
                                showConversionSheet = true
                            }
                        )
                    }
                }
            }
            Button("Wasn't Home") {
                if let addr = pendingAddress {
                    knockController?.handleKnockAndPromptNote(
                        address: addr,
                        status: "Wasn't Home",
                        prospects: prospects,
                        onUpdateMarkers: { updateMarkers() },
                        onShowNoteInput: { prospect in
                            prospectToNote = prospect
                            showNoteInput = true
                        }
                    )
                }
            }
            Button("Follow-Up Later") {
                if let addr = pendingAddress {
                    // ➜ NEW: Open the stepper instead of the old objection/follow-up prompts
                    stepperState = .init(ctx: .init(address: addr, isCustomer: isTappedAddressCustomer, prospect: nil))
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Did someone answer at \(pendingAddress ?? "this address")?") }
        .sheet(isPresented: $showNoteInput) {
            if let prospect = prospectToNote {
                LogNoteView(
                    prospect: prospect,
                    objection: selectedObjection,
                    pendingAddress: pendingAddress
                ) {
                    followUpAddress = prospect.address
                    followUpProspectName = prospect.fullName
                    selectedObjection = nil
                    showTripPrompt = true
                }
            }
        }
        .sheet(isPresented: $showObjectionPicker) {
            ObjectionSelectorView(
                isPresented: $showObjectionPicker,
                onSelect: { obj in
                    selectedObjection = obj
                    if let name = pendingRecordingFileName {
                        let newRecording = Recording(fileName: name, date: .now, objection: obj, rating: 3)
                        modelContext.insert(newRecording)
                        try? modelContext.save()
                        pendingRecordingFileName = nil
                    }
                    showFollowUpSheet = true
                },
                filter: { $0.text != "Converted To Sale" }
            )
        }
        .alert("Schedule Follow-Up?", isPresented: $showFollowUpPrompt) {
            Button("Yes") { showFollowUpSheet = true }
            Button("No", role: .cancel) { showTripPrompt = true }
        } message: { Text("Schedule follow-up for \(followUpProspectName)?") }
        .sheet(isPresented: $showFollowUpSheet, onDismiss: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showNoteInput = true
            }
        }) {
            if let prospect = prospectToNote {
                FollowUpScheduleView(prospect: prospect)
            }
        }
        .alert("Log a trip?", isPresented: $showTripPrompt) {
            Button("Yes") { showTripPopup = true }
            Button("No", role: .cancel) {}
        }
        .sheet(isPresented: $showTripPopup) {
            if let addr = pendingAddress { LogTripPopupView(endAddress: addr) }
        }
        .sheet(isPresented: $showingAddObjection, onDismiss: {
            if let _ = prospectToNote { showFollowUpSheet = true }
        }) {
            AddObjectionView()
        }
        .overlay(
            Group {
                if showConversionSheet, let prospect = prospectToConvert {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .onTapGesture { showConversionSheet = false }

                    CustomerCreateStepperView(
                        initialName: prospect.fullName,
                        initialAddress: prospect.address,
                        initialPhone: prospect.contactPhone,
                        initialEmail: prospect.contactEmail
                    ) { newCustomer in
                        // update prospect → customer
                        prospect.fullName = newCustomer.fullName
                        prospect.address = newCustomer.address
                        prospect.contactPhone = newCustomer.contactPhone
                        prospect.contactEmail = newCustomer.contactEmail
                        prospect.list = "Customers"

                        try? modelContext.save()
                        updateMarkers()
                        selectedList = "Customers"
                        showConversionSheet = false
                        
                        // ✅ Only now show confetti
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation { showConfetti = true }
                        }
                    } onCancel: {
                        showConversionSheet = false
                    }
                    .frame(width: 300, height: 300)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .shadow(radius: 8)
                    .position(x: UIScreen.main.bounds.midX,
                              y: UIScreen.main.bounds.midY * 0.9)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(2000)
                }
            }
        )
    }

    private func presentObjectionFlow(filtered: [Objection], for prospect: Prospect) {
        objectionOptions = filtered
        prospectToNote = prospect
        followUpAddress = prospect.address
        followUpProspectName = prospect.fullName
        if filtered.isEmpty {
            showObjectionPicker = false
            showingAddObjection = true
        } else {
            showObjectionPicker = true
        }
    }

    private var prospectPopup: some View {
        Group {
            if let popup = popupState, let pos = popupScreenPosition {
                ProspectPopupView(
                    place: popup.place,
                    isCustomer: popup.place.list == "Customers",
                    onClose: { popupState = nil },
                    onOutcomeSelected: { outcome, fileName in
                        pendingAddress = popup.place.address
                        isTappedAddressCustomer = popup.place.list == "Customers"
                        popupState = nil
                        // Route follow-ups into the stepper; keep others as-is
                        if outcome == "Follow Up Later" {
                            pendingRecordingFileName = fileName
                            if let addr = pendingAddress {
                                stepperState = .init(ctx: .init(address: addr, isCustomer: isTappedAddressCustomer, prospect: nil))
                            }
                        } else {
                            handleOutcome(outcome, recordingFileName: fileName)
                        }
                    },
                    recordingModeEnabled: recordingModeEnabled
                )
                .frame(width: 240)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .position(pos)
                .zIndex(999)
                .id(popup.id)
            }
        }
    }

    private func handleOutcome(_ status: String, recordingFileName: String?) {
        if status == "Converted To Sale" {
            let objection = Objection(text: "Converted To Sale", response: "Handled successfully", timesHeard: 0)
            modelContext.insert(objection)
            if let name = recordingFileName {
                let newRecording = Recording(fileName: name, date: .now, objection: objection, rating: 5)
                modelContext.insert(newRecording)
            }
            if let addr = pendingAddress {
                knockController?.handleKnockAndConvertToCustomer(
                    address: addr,
                    status: "Converted To Sale",
                    prospects: prospects,
                    onUpdateMarkers: { updateMarkers() },
                    onSetCustomerMarker: {
                        if let index = controller.markers.firstIndex(where: {
                            $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
                            addr.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                        }) {
                            controller.markers[index] = IdentifiablePlace(
                                address: addr,
                                location: controller.markers[index].location,
                                count: controller.markers[index].count,
                                list: "Customers"
                            )
                        }
                    },
                    onShowConversionSheet: { prospect in
                        prospectToConvert = prospect
                        showConversionSheet = true
                    }
                )
            }
        } else if status == "Follow Up Later" {
            // NEW: Route to stepper instead of the old flow
            pendingRecordingFileName = recordingFileName
            if let addr = pendingAddress {
                stepperState = .init(ctx: .init(address: addr, isCustomer: isTappedAddressCustomer, prospect: nil))
            }
        } else if status == "Wasn't Home" {
            if let addr = pendingAddress {
                knockController?.handleKnockAndPromptNote(
                    address: addr,
                    status: "Wasn't Home",
                    prospects: prospects,
                    onUpdateMarkers: { updateMarkers() },
                    onShowNoteInput: { prospect in
                        prospectToNote = prospect
                        showNoteInput = true
                    }
                )
            }
        }
        try? modelContext.save()
    }

    private func handleMapCenterChange(newAddress: String?) {
        guard let query = newAddress else { return }
        Task {
            if let coord = await controller.geocodeAddress(query) {
                withAnimation {
                    controller.region = MKCoordinateRegion(center: coord, latitudinalMeters: 1609.34, longitudinalMeters: 1609.34)
                }
            }
            addressToCenter = nil
        }
    }

    private func handleCompletionTap(_ result: MKLocalSearchCompletion) {
        let req = MKLocalSearch.Request(completion: result)
        MKLocalSearch(request: req).start { resp, _ in
            guard let item = resp?.mapItems.first else { return }
            let addr = item.placemark.title ?? "\(item.placemark.name ?? ""), \(item.placemark.locality ?? "")"
            DispatchQueue.main.async {
                searchText = addr
                controller.region = MKCoordinateRegion(center: item.placemark.coordinate, latitudinalMeters: 1609.34, longitudinalMeters: 1609.34)
                searchVM.results = []
                isSearchFocused = false
                // Do NOT auto-open stepper here; follow-up path only
                pendingAddress = addr
            }
        }
    }

    private func submitSearch() {
        SearchHandler.submitManualSearch(
            searchText: searchText,
            pendingAddress: &pendingAddress,
            showOutcomePrompt: &showOutcomePrompt,
            clearSearchText: { searchText = "" }
        )
    }

    private func updateMarkers() {
        controller.setMarkers(prospects: prospects, customers: customers)
    }
}

// MARK: - Stepper types used here

extension MapSearchView {
    struct KnockStepperState: Identifiable, Equatable { let id = UUID(); var ctx: KnockContext }
}
