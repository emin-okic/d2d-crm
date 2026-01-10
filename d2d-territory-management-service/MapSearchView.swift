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

    @State private var popupState: PopupState?
    @State private var popupScreenPosition: CGPoint? = nil

    @State private var isSearchExpanded = false
    @Namespace private var animationNamespace

    @Environment(\.modelContext) private var modelContext

    @State private var pendingRecordingFileName: String?

    @AppStorage("recordingModeEnabled") private var recordingModeEnabled: Bool = true
    @AppStorage("studioUnlocked") private var studioUnlocked: Bool = false
    private var recordingFeaturesActive: Bool { studioUnlocked && recordingModeEnabled }

    @State private var knockController: ProspectKnockActionController? = nil

    // NEW: Stepper state (only used for Follow-Up Later)
    @State private var stepperState: KnockStepperState? = nil
    
    @State private var showConfetti = false
    
    @State private var pendingAddProperty: PendingAddProperty?
    
    @StateObject private var userLocationManager = UserLocationManager()
    
    @State private var selectedPlaceID: UUID? = nil
    
    @State private var pendingBulkAdd: PendingBulkAdd?
    
    @State private var selectedUnitGroup: UnitGroup?
    
    @State private var selectedProspect: Prospect?
    @State private var selectedCustomer: Customer?
    
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
            
            mapLayer(geo: geo)
                .mapLifecycleHandlers()
                .mapSheetsAndAlerts()

        }
        
        
        // inside body chain where you had the presenter & lifecycle hooks
        .presentRotatingAdsCentered()
        .onAppear {
            // 🔹 Show exactly one ad for this app session (centered). Will differ each launch.
            AdEngine.shared.startSingleShot(inventory: AdDemoInventory.defaultAds)
        }
        .onDisappear {
            // No-op for single-shot, but keep if you want to explicitly clear.
            AdEngine.shared.stop()
        }
        .sheet(item: $stepperState) { stepperSheetView(for: $0) }
        // Listen for search focus and close popup
        .onChange(of: isSearchFocused) { focused in
            if focused {
                // Close any open popup when the search bar is tapped/focused
                withAnimation(.easeInOut(duration: 0.2)) {
                    popupState = nil
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .mapShouldRecenterAllMarkers)) { _ in
                    controller.recenterToFitAllMarkers()
                }
        .onChange(of: searchText) { searchVM.updateQuery($0) }
        .onAppear {
            updateMarkers()
            knockController = ProspectKnockActionController(modelContext: modelContext, controller: controller)
            
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
        .sheet(item: $pendingAddProperty) { addPropertySheet($0) }
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
                        
                        let newRecording = Recording(
                            fileName: name,
                            title: obj.text,
                            date: .now,
                            objection: obj,
                            rating: 3
                        )
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
            followUpSheet()
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
        .sheet(isPresented: $showConversionSheet) {
            conversionSheet()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didRequestBulkAdd)) { note in
            guard let bulk = note.object as? PendingBulkAdd else { return }
            Task { await handleBulkAdd(bulk) }
        }
        .sheet(item: $pendingBulkAdd) { bulk in
            BulkAddConfirmationSheet(
                bulk: bulk,
                onConfirm: { selected in
                    for prop in selected {
                        addProspectFromMapTap(address: prop.address, coordinate: prop.coordinate)
                    }
                    pendingBulkAdd = nil
                },
                onCancel: {
                    pendingBulkAdd = nil
                }
            )
            .presentationDetents([.fraction(0.5)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedProspect) { prospect in
            NavigationStack {
                ProspectDetailsView(prospect: prospect)
            }
        }

        .sheet(item: $selectedCustomer) { customer in
            NavigationStack {
                CustomerDetailsView(customer: customer)
            }
        }
    }
    
    @ViewBuilder
    private func conversionSheet() -> some View {
        if let prospect = prospectToConvert {
            CustomerCreateStepperView(
                initialName: prospect.fullName,
                initialAddress: prospect.address,
                initialPhone: prospect.contactPhone,
                initialEmail: prospect.contactEmail
            ) { newCustomer in
                
                // Carry over history, notes, appointments, coordinates
                newCustomer.knockHistory = prospect.knockHistory
                newCustomer.notes = prospect.notes
                newCustomer.appointments = prospect.appointments
                if newCustomer.contactPhone.isEmpty { newCustomer.contactPhone = prospect.contactPhone }
                if newCustomer.contactEmail.isEmpty { newCustomer.contactEmail = prospect.contactEmail }
                newCustomer.latitude = prospect.latitude
                newCustomer.longitude = prospect.longitude

                // Persist new customer and delete old prospect
                modelContext.insert(newCustomer)
                modelContext.delete(prospect)
                try? modelContext.save()
                
                updateMarkers()
                selectedList = "Customers"
                
                // Celebrate 🎉
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation { showConfetti = true }
                }
                
                showConversionSheet = false
            } onCancel: {
                showConversionSheet = false
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    @ViewBuilder
    private func followUpSheet() -> some View {
        if let prospect = prospectToNote {
            FollowUpScheduleView(prospect: prospect)
        }
    }
    
    
    @ViewBuilder
    private func mapLayer(geo: GeometryProxy) -> some View {
        ZStack {
            mapBaseLayer(geo: geo)
            floatingUI()
            confettiLayer()
        }
            
    }
    
    @ViewBuilder
    private func mapBaseLayer(geo: GeometryProxy) -> some View {
        MapDisplayView(
            region: $controller.region,
            markers: controller.markers,
            selectedPlaceID: selectedPlaceID,
            userLocationManager: userLocationManager,
            onMarkerTapped: { place in handleMarkerTap(place, geo: geo) },
            onMapTapped: handleMapTap,
            onRegionChange: handleRegionChange
        )
        .frame(maxHeight: .infinity)
        .edgesIgnoringSafeArea(.horizontal)

        ScorecardBar()
    }

    @ViewBuilder
    private func floatingUI() -> some View {
        FloatingSearchAndMicButtons(
            searchText: $searchText,
            isExpanded: $isSearchExpanded,
            isFocused: $isSearchFocused,
            viewModel: searchVM,
            animationNamespace: animationNamespace,
            onSubmit: { submitSearch() },
            onSelectResult: { handleCompletionTap($0) },
            userLocationManager: userLocationManager,
            mapController: controller
        )

        if !isSearchExpanded {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    QRCodeCardView()
                }
                .padding(.trailing, 20)
                .padding(.bottom, 30)
            }
        }
    }

    @ViewBuilder
    private func confettiLayer() -> some View {
        if showConfetti {
            ConfettiBurstView()
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(5000)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { showConfetti = false }
                    }
                }
        }
    }
    
    @MainActor
    private func handleBulkAdd(_ bulk: PendingBulkAdd) async {
        var resolved: [PendingAddProperty] = []
        var seenAddresses: Set<String> = []

        for prop in bulk.properties {
            let snapped = await snapToNearestRoad(coordinate: prop.coordinate)
            let address = await reverseGeocode(coordinate: snapped) ?? "Unknown Address"
            let normalized = address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

            let existsGlobally = prospects.contains { $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalized } ||
                                 customers.contains { $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalized }

            guard !existsGlobally, !seenAddresses.contains(normalized) else { continue }

            resolved.append(PendingAddProperty(address: address, coordinate: snapped))
            seenAddresses.insert(normalized)
        }

        pendingBulkAdd = PendingBulkAdd(
            center: bulk.center,
            radius: bulk.radius,
            properties: resolved
        )
    }
    
    private func unitsForBaseAddress(_ base: String) -> [UnitContact] {

        let prospectUnits = prospects
            .filter {
                parseAddress($0.address).base.lowercased() == base.lowercased()
            }
            .map { UnitContact.prospect($0) }

        let customerUnits = customers
            .filter {
                parseAddress($0.address).base.lowercased() == base.lowercased()
            }
            .map { UnitContact.customer($0) }

        return prospectUnits + customerUnits
    }
    
    private let bulkGeocoder = CLGeocoder()

    private func reverseGeocode(
        coordinate: CLLocationCoordinate2D
    ) async -> String? {

        let location = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )

        do {
            let placemarks = try await bulkGeocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }

            // Prefer full postal address if available
            if let postal = placemark.postalAddress {
                return CNPostalAddressFormatter()
                    .string(from: postal)
                    .replacingOccurrences(of: "\n", with: ", ")
            }

            // Fallbacks
            if let name = placemark.name,
               let street = placemark.thoroughfare {
                return "\(name) \(street)"
            }

            // Final fallback: build a readable address manually
            let parts = [
                placemark.subThoroughfare,
                placemark.thoroughfare,
                placemark.locality,
                placemark.administrativeArea
            ]

            let address = parts
                .compactMap { $0 }
                .joined(separator: " ")

            return address.isEmpty ? nil : address
            
        } catch {
            print("❌ Reverse geocode failed:", error)
            return nil
        }
    }
    
    private func snapToNearestRoad(
        coordinate: CLLocationCoordinate2D
    ) async -> CLLocationCoordinate2D {

        let request = MKDirections.Request()

        // Tiny offset destination (~10m) to force route solving
        let offset = 0.00009

        request.source = MKMapItem(
            placemark: MKPlacemark(coordinate: coordinate)
        )

        request.destination = MKMapItem(
            placemark: MKPlacemark(
                coordinate: CLLocationCoordinate2D(
                    latitude: coordinate.latitude + offset,
                    longitude: coordinate.longitude + offset
                )
            )
        )

        request.transportType = .walking
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)

        do {
            let response = try await directions.calculate()

            // First polyline point = snapped road position
            if let route = response.routes.first {
                let points = route.polyline.points()
                if route.polyline.pointCount > 0 {
                    return points[0].coordinate
                }
            }
        } catch {
            print("❌ Road snap failed:", error)
        }

        // Fallback: original coordinate
        return coordinate
    }
    
    @MainActor
    private func centerMapForPopup(coordinate: CLLocationCoordinate2D) {

        // Target zoom (tight enough to matter visually)
        let latMeters: CLLocationDistance = 250
        let lonMeters: CLLocationDistance = 250

        // Convert meters → degrees (approx)
        let metersToDegrees = 1.0 / 111_000.0
        let latitudeSpanDegrees = latMeters * metersToDegrees

        // Push marker into TOP HALF (25% from top)
        let verticalOffset = latitudeSpanDegrees * 0.25

        let adjustedCenter = CLLocationCoordinate2D(
            latitude: coordinate.latitude - verticalOffset,
            longitude: coordinate.longitude
        )

        withAnimation(.easeInOut(duration: 0.35)) {
            controller.region = MKCoordinateRegion(
                center: adjustedCenter,
                latitudinalMeters: latMeters,
                longitudinalMeters: lonMeters
            )
        }
    }
    
    private func centerMapForNewProperty(coordinate: CLLocationCoordinate2D) {
        guard let mapView = MapDisplayView.cachedMapView else { return }

        // Convert map coordinate → screen point
        let point = mapView.convert(coordinate, toPointTo: mapView)

        // Visible height minus detented sheet (~260)
        let sheetHeight: CGFloat = 260
        let visibleHeight = mapView.bounds.height - sheetHeight

        // Target Y = vertical center of visible map area
        let targetY = visibleHeight / 2

        // Calculate vertical delta in screen space
        let deltaY = point.y - targetY

        // Convert that delta back into map coordinates
        let offsetPoint = CGPoint(
            x: point.x,
            y: point.y + deltaY
        )

        let offsetCoordinate = mapView.convert(offsetPoint, toCoordinateFrom: mapView)

        let region = MKCoordinateRegion(
            center: offsetCoordinate,
            span: mapView.region.span
        )

        mapView.setRegion(region, animated: true)
    }
    
    @ViewBuilder
    private func stepperSheetView(for state: KnockStepperState) -> some View {
        VStack {
            Spacer()
            KnockStepperPopupView(
                context: state.ctx,
                objections: objections,
                saveKnock: saveKnockForStepper,
                incrementObjection: { obj in
                    obj.timesHeard += 1

                    if recordingFeaturesActive,
                       let name = pendingRecordingFileName {
                        let rec = Recording(
                            fileName: name,
                            title: obj.text,
                            date: .now,
                            objection: obj,
                            rating: 3
                        )
                        modelContext.insert(rec)
                        pendingRecordingFileName = nil
                    }

                    try? modelContext.save()
                },
                saveFollowUp: { prospect, date in
                    saveFollowUp(for: state.ctx, prospect: prospect, date: date)
                },
                convertToCustomer: { prospect, done in
                    convertProspectToCustomer(prospect)
                    done()
                },
                addNote: addNoteToProspect,
                logTrip: logTripForStepper,
                onClose: { stepperState = nil; withAnimation { showConfetti = true } }
            )
            .frame(width: 280, height: 280)
            .cornerRadius(16)
            .shadow(radius: 8)
            Spacer()
        }
        .presentationDetents([.fraction(0.45)])
        .presentationDragIndicator(.visible)
    }
    
    @MainActor
    private func logTripForStepper(start: String, end: String, date: Date) {
        guard !end.isEmpty else { return }

        let trip = Trip(
            startAddress: start,
            endAddress: end,
            miles: 0,
            date: date
        )

        modelContext.insert(trip)
        try? modelContext.save()
    }
    
    @MainActor
    private func addNoteToProspect(prospect: Prospect, text: String) {
        prospect.notes.append(Note(content: text))
        try? modelContext.save()
    }
    
    @MainActor
    private func convertProspectToCustomer(_ prospect: Prospect) {
        // 1️⃣ Create a new customer
        let newCustomer = Customer(
            fullName: prospect.fullName,
            address: prospect.address,
            count: prospect.knockCount
        )

        // 2️⃣ Carry over history, notes, appointments, coordinates
        newCustomer.contactPhone = prospect.contactPhone
        newCustomer.contactEmail = prospect.contactEmail
        newCustomer.notes = prospect.notes
        newCustomer.appointments = prospect.appointments
        newCustomer.knockHistory = prospect.knockHistory
        newCustomer.latitude = prospect.latitude
        newCustomer.longitude = prospect.longitude

        // 3️⃣ Persist new customer & delete old prospect
        modelContext.insert(newCustomer)
        modelContext.delete(prospect)

        try? modelContext.save()
        updateMarkers()
        
        selectedList = "Customers"
        
        // Optional UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation { showConfetti = true }
        }
    }

    private func saveKnockForStepper(outcome: KnockOutcome) -> Prospect {
        if let ctx = stepperState?.ctx, ctx.isCustomer {
            return CustomerKnockActionController(modelContext: modelContext, controller: controller)
                .saveKnockOnly(address: ctx.address,
                               status: outcome.rawValue,
                               customers: customers,
                               onUpdateMarkers: { updateMarkers() })
                .asProspectCopy()
        } else {
            return knockController!.saveKnockOnly(
                address: stepperState!.ctx.address,
                status: outcome.rawValue,
                prospects: prospects,
                onUpdateMarkers: { updateMarkers() }
            )
        }
    }
    
    @ViewBuilder
    private func addPropertySheet(_ item: PendingAddProperty) -> some View {
        AddPropertyConfirmationSheet(
            address: item.address,
            onConfirm: { addProspectFromMapTap(address: item.address, coordinate: item.coordinate); pendingAddProperty = nil },
            onCancel: { pendingAddProperty = nil }
        )
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.visible)
    }
    
    private func saveCustomerKnockForStepper(ctx: KnockContext, outcome: KnockOutcome) -> Prospect {
        let controller = CustomerKnockActionController(modelContext: modelContext, controller: controller)
        let customer = controller.saveKnockOnly(
            address: ctx.address,
            status: outcome.rawValue,
            customers: customers,
            onUpdateMarkers: { updateMarkers() }
        )
        let prospect = Prospect(
            fullName: customer.fullName,
            address: customer.address,
            count: customer.knockCount,
            list: "Customers"
        )
        prospect.latitude = customer.latitude
        prospect.longitude = customer.longitude
        return prospect
    }
    
    @ViewBuilder
    private func stepperOverlay(geo: GeometryProxy) -> some View {
        Group {
            if let s = stepperState {
                KnockStepperPopupView(
                    context: s.ctx,
                    objections: objections,
                    saveKnock: saveKnockClosure(for: s.ctx),
                    incrementObjection: { obj in
                        obj.timesHeard += 1

                        if recordingFeaturesActive,
                           let name = pendingRecordingFileName {
                            let rec = Recording(
                                fileName: name,
                                title: obj.text,
                                date: .now,
                                objection: obj,
                                rating: 3
                            )
                            modelContext.insert(rec)
                            pendingRecordingFileName = nil
                        }

                        try? modelContext.save()
                    },
                    saveFollowUp: { prospect, date in
                        saveFollowUp(for: s.ctx, prospect: prospect, date: date)
                    },
                    convertToCustomer: { prospect, done in
                        prospectToConvert = prospect
                        showConversionSheet = true
                        done()
                    },
                    addNote: { prospect, text in
                        prospect.notes.append(Note(content: text))
                        try? modelContext.save()
                    },
                    logTrip: { start, end, date in
                        guard !end.isEmpty else { return }
                        let trip = Trip(
                            startAddress: start,
                            endAddress: end,
                            miles: 0,
                            date: date
                        )
                        modelContext.insert(trip)
                        try? modelContext.save()
                    },
                    onClose: {
                        stepperState = nil
                        withAnimation { showConfetti = true }
                    }
                )
                .frame(width: 280, height: 280)
                .position(
                    x: geo.size.width / 2,
                    y: geo.size.height * 0.42
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(1000)
            }
        }
    }
    
    private func saveKnockClosure(for ctx: KnockContext) -> (KnockOutcome) -> Prospect {
        return { outcome in
            if ctx.isCustomer {
                return saveCustomerKnockForStepper(ctx: ctx, outcome: outcome)
            } else {
                return knockController!.saveKnockOnly(
                    address: ctx.address,
                    status: outcome.rawValue,
                    prospects: prospects,
                    onUpdateMarkers: { updateMarkers() }
                )
            }
        }
    }
    
    private func saveFollowUp(
        for ctx: KnockContext,
        prospect: Prospect,
        date: Date
    ) {
        if ctx.isCustomer {
            guard let customer = customers.first(where: {
                addressesMatch($0.address, ctx.address)
            }) else { return }

            let appt = Appointment(
                title: "Follow-Up",
                location: customer.address,
                clientName: customer.fullName,
                date: date,
                type: "Follow-Up",
                notes: customer.notes.map { $0.content }
            )

            customer.appointments.append(appt)
            modelContext.insert(appt)
        } else {
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
        }

        try? modelContext.save()
    }
    
    /// This function handles adding new prospects to the map
    /// It will simply ask if the prospect selected should be added or not
    /// The assumption is that sales reps will want to pre-load their prospects the day before they knock it
    private func addProspectFromMapTap(address: String, coordinate: CLLocationCoordinate2D) {
        let newProspect = Prospect(
            fullName: "New Prospect",
            address: address,
            count: 0,
            list: "Prospects"
        )
        
        // Assign coordinates once
        newProspect.latitude = coordinate.latitude
        newProspect.longitude = coordinate.longitude

        modelContext.insert(newProspect)
        try? modelContext.save()
        
        // 🔍 Print for testing
        print("""
        📍 Prospect created
        Address: \(address)
        Latitude: \(coordinate.latitude)
        Longitude: \(coordinate.longitude)
        """)

        // controller.performSearch(query: address)
        
        // Add marker WITHOUT geocoding
        controller.markers.append(
            IdentifiablePlace(
                address: address,
                location: coordinate,
                count: 0,
                list: "Prospects"
            )
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

    private func handleOutcome(_ status: String, recordingFileName: String?) {

        guard let addr = pendingAddress else { return }

        // =========================
        // CUSTOMER FLOW
        // =========================
        if isTappedAddressCustomer {

            switch status {

            case "Wasn't Home":
                let customerController = CustomerKnockActionController(
                    modelContext: modelContext,
                    controller: controller
                )

                customerController.handleKnockAndUpdateMarker(
                    address: addr,
                    status: status,
                    customers: customers,
                    onUpdateMarkers: { updateMarkers() }
                )

            case "Follow Up Later":
                pendingRecordingFileName = recordingFileName
                stepperState = .init(
                    ctx: .init(
                        address: addr,
                        isCustomer: true,
                        prospect: nil
                    )
                )
            
            case "Customer Lost":
                convertCustomerToProspect(address: addr)

            default:
                // Customers should never hit Converted To Sale
                assertionFailure("Invalid outcome '\(status)' for Customer")
            }

            try? modelContext.save()
            return
        }

        // =========================
        // PROSPECT FLOW
        // =========================
        switch status {

        case "Converted To Sale":
            if let prospect = prospects.first(where: {
                addressesMatch($0.address, addr)
            }) {
                
                // 1️⃣ Log the "Converted To Sale" knock
                knockController?.saveKnockOnly(
                    address: addr,
                    status: status,          // "Converted To Sale"
                    prospects: prospects,
                    onUpdateMarkers: { updateMarkers() }
                )
                
                // 2️⃣ Trigger the conversion sheet
                prospectToConvert = prospect
                showConversionSheet = true
            }

        case "Follow Up Later":
            pendingRecordingFileName = recordingFileName
            stepperState = .init(
                ctx: .init(
                    address: addr,
                    isCustomer: false,
                    prospect: nil
                )
            )

        case "Wasn't Home":
            knockController?.handleKnockAndPromptNote(
                address: addr,
                status: status,
                prospects: prospects,
                onUpdateMarkers: { updateMarkers() },
                onShowNoteInput: { prospect in
                    prospectToNote = prospect
                    showNoteInput = true
                }
            )
            
        case "Unqualified":
            knockController?.saveKnockOnly(
                address: addr,
                status: status,
                prospects: prospects,
                onUpdateMarkers: { updateMarkers() }
            )
        
        case "Requalified":
            if let prospect = prospects.first(where: {
                addressesMatch($0.address, addr)
            }) {

                // 1️⃣ Clear unqualified flag
                prospect.isUnqualified = false

                // 2️⃣ Clean up name (remove suffix)
                prospect.fullName = prospect.fullName
                    .replacingOccurrences(of: " - Unqualified", with: "")

                // 3️⃣ Log a knock for history
                knockController?.saveKnockOnly(
                    address: addr,
                    status: "Requalified",
                    prospects: prospects,
                    onUpdateMarkers: { updateMarkers() }
                )
            }

        default:
            break
        }

        try? modelContext.save()
    }
    
    @MainActor
    private func convertCustomerToProspect(address: String) {
        guard let customer = customers.first(where: {
            addressesMatch($0.address, address)
        }) else { return }

        // 1️⃣ Create Prospect from Customer
        let prospect = Prospect(
            fullName: customer.fullName,
            address: customer.address,
            count: customer.knockCount,
            list: "Prospects"
        )

        // 2️⃣ Carry everything over
        prospect.contactPhone = customer.contactPhone
        prospect.contactEmail = customer.contactEmail
        prospect.notes = customer.notes
        prospect.appointments = customer.appointments
        prospect.knockHistory = customer.knockHistory
        
        // 2.5 LOG THE STATE TRANSITION
        prospect.knockHistory.append(
            Knock(
                date: .now,
                status: "Customer Lost",
                latitude: prospect.latitude ?? customer.latitude ?? 0,
                longitude: prospect.longitude ?? customer.longitude ?? 0
            )
        )

        // 3️⃣ Preserve spatial identity
        prospect.latitude = customer.latitude
        prospect.longitude = customer.longitude

        // 4️⃣ Persist new Prospect
        modelContext.insert(prospect)

        // 5️⃣ Delete Customer (single source of truth)
        modelContext.delete(customer)

        // 6️⃣ Save + refresh UI
        try? modelContext.save()
        updateMarkers()

        // Optional UX
        selectedList = "Prospects"
    }
    
    @MainActor
    private func handleMapCenterChange(newAddress: String?) {
        
        guard let query = newAddress else { return }
        
        Task { @MainActor [controller] in
            
            if let coord = await controller.geocodeAddress(query) {
                withAnimation {
                    controller.region = MKCoordinateRegion(
                        center: coord,
                        latitudinalMeters: 1609.34,
                        longitudinalMeters: 1609.34
                    )
                }
            }
            addressToCenter = nil
        }
    }

    private func handleCompletionTap(_ result: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: result)
        
        MKLocalSearch(request: request).start { resp, _ in
            guard let item = resp?.mapItems.first else { return }
            let addr = item.placemark.title ?? "\(item.placemark.name ?? ""), \(item.placemark.locality ?? "")"
            
            DispatchQueue.main.async {
                self.handleSearchResult(item: item, address: addr)
            }
        }
    }

    @MainActor
    private func handleSearchResult(item: MKMapItem, address: String) {
        searchText = address
        searchVM.results = []
        isSearchFocused = false
        pendingAddress = address

        zoomToCoordinate(item.placemark.coordinate)

        if let existingProspect = prospects.first(where: { addressesMatch($0.address, address) }) {
            showPopup(for: prospectPlace(from: existingProspect))
        } else if let existingCustomer = customers.first(where: { addressesMatch($0.address, address) }) {
            showPopup(for: customerPlace(from: existingCustomer))
        } else {
            pendingAddProperty = PendingAddProperty(address: address, coordinate: item.placemark.coordinate)
        }
    }

    private func zoomToCoordinate(_ coord: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(
            center: coord,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
        withAnimation(.easeInOut(duration: 0.4)) {
            controller.region = region
        }
    }

    private func prospectPlace(from prospect: Prospect) -> IdentifiablePlace {
        IdentifiablePlace(
            address: prospect.address,
            location: CLLocationCoordinate2D(
                latitude: prospect.latitude ?? controller.region.center.latitude,
                longitude: prospect.longitude ?? controller.region.center.longitude
            ),
            count: prospect.knockHistory.count,
            list: prospect.list
        )
    }

    private func customerPlace(from customer: Customer) -> IdentifiablePlace {
        IdentifiablePlace(
            address: customer.address,
            location: CLLocationCoordinate2D(
                latitude: customer.latitude ?? controller.region.center.latitude,
                longitude: customer.longitude ?? controller.region.center.longitude
            ),
            count: customer.knockHistory.count,
            list: "Customers"
        )
    }
    
    private func addressesMatch(_ a: String, _ b: String) -> Bool {
        let normalize: (String) -> String = {
            $0.lowercased()
              .replacingOccurrences(of: ",", with: "")
              .replacingOccurrences(of: "  ", with: " ")
              .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let na = normalize(a)
        let nb = normalize(b)

        return na.contains(nb) || nb.contains(na)
    }

    private func submitSearch() {
        let query = searchText

        Task { @MainActor in
            guard let item = await SearchBarController.resolveFreeformSearch(query: query) else {
                return
            }

            let address =
                item.placemark.postalAddress
                .map {
                    CNPostalAddressFormatter()
                        .string(from: $0)
                        .replacingOccurrences(of: "\n", with: ", ")
                }
                ?? item.placemark.title
                ?? query

            searchText = ""
            searchVM.results = []
            isSearchFocused = false
            isSearchExpanded = false

            pendingAddress = address

            // 📍 Move map
            withAnimation(.easeInOut(duration: 0.4)) {
                controller.region = MKCoordinateRegion(
                    center: item.placemark.coordinate,
                    latitudinalMeters: 500,
                    longitudinalMeters: 500
                )
            }

            // 🔍 Existing Prospect?
            if let prospect = prospects.first(where: {
                addressesMatch($0.address, address)
            }) {
                showPopup(
                    for: IdentifiablePlace(
                        address: prospect.address,
                        location: CLLocationCoordinate2D(
                            latitude: prospect.latitude ?? item.placemark.coordinate.latitude,
                            longitude: prospect.longitude ?? item.placemark.coordinate.longitude
                        ),
                        count: prospect.knockHistory.count,
                        list: prospect.list
                    )
                )
                return
            }

            // 🔍 Existing Customer?
            if let customer = customers.first(where: {
                addressesMatch($0.address, address)
            }) {
                showPopup(
                    for: IdentifiablePlace(
                        address: customer.address,
                        location: CLLocationCoordinate2D(
                            latitude: customer.latitude ?? item.placemark.coordinate.latitude,
                            longitude: customer.longitude ?? item.placemark.coordinate.longitude
                        ),
                        count: customer.knockHistory.count,
                        list: "Customers"
                    )
                )
                return
            }

            // ➕ New property
            pendingAddProperty = PendingAddProperty(
                address: address,
                coordinate: item.placemark.coordinate
            )
        }
    }

    private func updateMarkers() {
        controller.setMarkers(prospects: prospects, customers: customers)
    }
}

// MARK: - Stepper types used here

extension MapSearchView {
    struct KnockStepperState: Identifiable, Equatable { let id = UUID(); var ctx: KnockContext }
}


extension MapSearchView {
    func mapLifecycleHandlers() -> some View {
        self
            .onChange(of: popupState) { newValue in
                // Close the search bar when a popup opens
                if newValue != nil, isSearchExpanded {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSearchExpanded = false
                        isSearchFocused = false
                        searchText = ""
                    }
                }
            }
    }
    
    func mapSheetsAndAlerts() -> some View {
        self
            .sheet(item: $selectedUnitGroup) { group in
                UnitSelectorPopupView(
                    baseAddress: group.base,
                    units: group.units,
                    onSelect: { unit in
                        selectedUnitGroup = nil

                        let place = IdentifiablePlace(
                            address: unit.address,
                            location: unit.coordinate ?? controller.region.center,
                            count: unit.knockCount,
                            list: unit.list,
                            isUnqualified: unit.isUnqualified
                        )

                        showPopup(for: place)
                    },
                    onClose: {
                        selectedUnitGroup = nil
                    }
                )
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
            }
        // This is for the contact popup display
        .sheet(item: $popupState) { popup in
            ProspectPopupView(
                place: popup.place,
                isCustomer: popup.place.list == "Customers",
                onClose: {
                    popupState = nil
                    selectedPlaceID = nil
                    
                    // 🔑 Force MapKit to deselect the annotation
                    if let mapView = MapDisplayView.cachedMapView {
                        DispatchQueue.main.async {
                            mapView.selectedAnnotations.forEach {
                                mapView.deselectAnnotation($0, animated: false)
                            }
                        }
                    }
                    
                },
                onOutcomeSelected: { outcome, fileName in
                    pendingAddress = popup.place.address
                    isTappedAddressCustomer = popup.place.list == "Customers"
                    popupState = nil
                    selectedPlaceID = nil

                    if outcome == "Follow Up Later" {
                        pendingRecordingFileName = fileName
                        stepperState = .init(
                            ctx: .init(
                                address: popup.place.address,
                                isCustomer: isTappedAddressCustomer,
                                prospect: nil
                            )
                        )
                    } else {
                        handleOutcome(outcome, recordingFileName: fileName)
                    }
                },
                recordingModeEnabled: recordingModeEnabled,
                onViewDetails: {
                    openDetails(for: popup.place)
                }
            )
            .presentationDetents([.fraction(0.5)])
            .presentationDragIndicator(.visible)
        }
    }
    
    /// Helper function to create the popup for Prospect or Customer
    private func showPopup(for place: IdentifiablePlace) {
        
        selectedPlaceID = place.id
        
        centerMapForPopup(coordinate: place.location)
        
        let state = PopupState(place: place)
        popupState = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            popupState = state
        }
        
    }
    
    private func openDetails(for place: IdentifiablePlace) {
        // Close popup first (important for UX)
        closePopup()

        if place.list == "Customers" ,
           let customer = customers.first(where: { $0.address == place.address }) {
            selectedCustomer = customer
            return
        }

        if let prospect = prospects.first(where: { $0.address == place.address }) {
            selectedProspect = prospect
        }
    }
    
    @MainActor
    private func closePopup() {
        popupState = nil
        selectedPlaceID = nil

        // Force MapKit to deselect the annotation
        if let mapView = MapDisplayView.cachedMapView {
            DispatchQueue.main.async {
                mapView.selectedAnnotations.forEach {
                    mapView.deselectAnnotation($0, animated: false)
                }
            }
        }
    }
    
    private func handleMarkerTap(_ place: IdentifiablePlace, geo: GeometryProxy) {
        let parts = parseAddress(place.address)
        let units = unitsForBaseAddress(parts.base)
        
        if units.count > 1 {
            handleMultiUnit(place: place, base: parts.base, units: units)
            return
        }
        
        showProspectPopup(for: place, geo: geo)
    }

    private func handleMultiUnit(place: IdentifiablePlace, base: String, units: [UnitContact]) {
        centerMapForPopup(coordinate: place.location)
        selectedUnitGroup = UnitGroup(base: base, units: units)
    }

    private func showProspectPopup(for place: IdentifiablePlace, geo: GeometryProxy) {
        centerMapForPopup(coordinate: place.location)
        
        let state = PopupState(place: place)
        popupState = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            popupState = state
        }
        
        updatePopupScreenPosition(for: place, geo: geo)
    }

    private func updatePopupScreenPosition(for place: IdentifiablePlace, geo: GeometryProxy) {
        guard let mapView = MapDisplayView.cachedMapView else { return }
        let raw = mapView.convert(place.location, toPointTo: mapView)
        let popupW: CGFloat = 240
        let halfW = popupW / 2
        let halfH: CGFloat = 60
        let offsetY = halfH + 14
        let x = min(max(raw.x, halfW), geo.size.width - halfW)
        let y = min(max(raw.y - offsetY, halfH), geo.size.height - halfH)
        popupScreenPosition = CGPoint(x: x, y: y)
    }
    
    
    private func handleMapTap(_ coordinate: CLLocationCoordinate2D) {
        // 🎯 Center map FIRST (same as marker tap)
        centerMapForNewProperty(coordinate: coordinate)
        
        // 🎯 Haptic: instant response
        MapScreenHapticsController.shared.mapTap()
        
        selectedPlaceID = nil
        
        // CLOSE SEARCH FIRST if click anywhere other than search
        if isSearchExpanded {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSearchExpanded = false
                isSearchFocused = false
                searchText = ""
            }
        }
        
        tapManager.handleTap(at: coordinate)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let tapped = tapManager.tappedAddress
            guard !tapped.isEmpty else { return }

            // If this address already exists, do nothing
            let normalized = tapped.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let exists = prospects.contains {
                $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalized
            }

            guard !exists else { return }

            pendingAddProperty = PendingAddProperty(
                address: tapped,
                coordinate: coordinate
            )
        }
    }
    
    private func handleRegionChange(_ newRegion: MKCoordinateRegion) {
        controller.region = newRegion
        if popupState != nil { popupState = nil }
    }

    
}
