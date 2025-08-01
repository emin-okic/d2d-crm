//
//  MapSearchView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
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

    @StateObject private var controller: MapController
    @State private var pendingAddress: String?
    @State private var showOutcomePrompt = false
    @State private var showNoteInput = false
    @State private var prospectToNote: Prospect?

    @State private var showObjectionPicker = false
    @State private var objectionOptions: [Objection] = []
    @State private var selectedObjection: Objection?
    @Query private var objections: [Objection]

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

    @State private var showingAddObjection = false

    @AppStorage("hasSeenKnockTutorial") private var hasSeenKnockTutorial: Bool = false
    @State private var showKnockTutorial = false

    @StateObject private var searchVM = SearchCompleterViewModel()

    @FocusState private var isSearchFocused: Bool

    @State private var isTappedAddressCustomer = false

    @State private var selectedPlace: IdentifiablePlace?
    @State private var showProspectPopup = false

    @State private var popupScreenPosition: CGPoint? = nil
    
    @State private var isSearchExpanded = false
    @Namespace private var animationNamespace

    @Environment(\.modelContext) private var modelContext
    
    @State private var pendingRecordingFileName: String?

    private var hasSignedUp: Bool {
        prospects
            .flatMap { $0.knockHistory }
            .contains { $0.status == "Converted To Sale" }
    }

    private var totalKnocks: Int {
        prospects.flatMap { $0.knockHistory }.count
    }

    private var averageKnocksPerCustomer: Int {
        let customerKnocks = prospects
            .filter { $0.list == "Customers" }
            .map { $0.knockHistory.count }
        guard !customerKnocks.isEmpty else { return 0 }
        return Int(Double(customerKnocks.reduce(0, +)) / Double(customerKnocks.count))
    }

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
                        selectedPlace = place
                        showProspectPopup = true
                        if let mapView = MapDisplayView.cachedMapView {
                            let raw = mapView.convert(place.location, toPointTo: mapView)
                            let popupW: CGFloat = 240
                            let halfW = popupW/2
                            let halfH: CGFloat = 60
                            let offsetY = halfH + 14
                            let x = min(max(raw.x, halfW), geo.size.width-halfW)
                            let y = min(max(raw.y-offsetY, halfH), geo.size.height-halfH)
                            popupScreenPosition = CGPoint(x: x, y: y)
                        }
                    },
                    onMapTapped: { coordinate in
                        tapManager.handleTap(at: coordinate)
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.6) {
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
                        // close popup on any pan/zoom
                        if showProspectPopup { showProspectPopup = false }
                    }
                )
                .frame(maxHeight: .infinity)
                .edgesIgnoringSafeArea(.horizontal)

                ScorecardBar(totalKnocks: totalKnocks,
                             avgKnocksPerSale: averageKnocksPerCustomer,
                             hasSignedUp: hasSignedUp)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if isSearchExpanded {
                            SearchBarView(
                                searchText: $searchText,
                                isFocused: $isSearchFocused,
                                viewModel: searchVM,
                                onSubmit: {
                                    submitSearch()
                                    searchText = ""
                                    withAnimation { isSearchExpanded = false }
                                },
                                onSelectResult: {
                                    handleCompletionTap($0)
                                },
                                onCancel: {
                                    withAnimation {
                                        isSearchExpanded = false
                                        searchText = ""
                                    }
                                }
                            )
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 30)
                            .matchedGeometryEffect(id: "search", in: animationNamespace)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        } else {
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    isSearchExpanded = true
                                    isSearchFocused = true
                                }
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Circle().fill(Color.blue))
                            }
                            .matchedGeometryEffect(id: "search", in: animationNamespace)
                            .padding(.trailing, 20)
                            .padding(.bottom, 30)
                            .shadow(radius: 4)
                        }
                    }
                }

                if showProspectPopup, let place = selectedPlace, let pos = popupScreenPosition {
                    ProspectPopupView(
                        place: place,
                        isCustomer: place.list == "Customers",  // 👈 Pass whether this is a customer
                        onClose: { showProspectPopup = false },
                        onOutcomeSelected: { outcome, fileName in
                            pendingAddress = place.address
                            isTappedAddressCustomer = place.list == "Customers"
                            showProspectPopup = false
                            handleOutcome(outcome, recordingFileName: fileName)
                        }
                    )
                    .frame(width:240).background(.ultraThinMaterial)
                    .cornerRadius(16).position(pos).zIndex(999)
                }
                
                if showKnockTutorial {
                    KnockTutorialView(totalKnocks: totalKnocks) {
                        withAnimation { showKnockTutorial=false; hasSeenKnockTutorial=true }
                    }
                }
            }
        }
        .onChange(of: searchText) { searchVM.updateQuery($0) }
        .onAppear { updateMarkers() }
        .onChange(of: prospects) { _ in updateMarkers() }
        .onChange(of: selectedList) { _ in updateMarkers() }
        .onChange(of: addressToCenter) { handleMapCenterChange(newAddress: $0) }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                            to:nil,from:nil,for:nil)
        }
        .alert("Knock Outcome",isPresented:$showOutcomePrompt) {
            if !isTappedAddressCustomer {
                Button("Converted To Sale"){ handleKnockAndConvertToCustomer(status:"Converted To Sale") }
            }
            Button("Wasn't Home"){ handleKnockAndPromptNote(status:"Wasn't Home") }
            Button("Follow-Up Later"){ handleKnockAndPromptObjection(status:"Follow Up Later") }
            Button("Cancel",role:.cancel){}
        } message: { Text("Did someone answer at \(pendingAddress ?? "this address")?") }
            .sheet(isPresented:$showNoteInput){
                if let prospect=prospectToNote {
                    LogNoteView(
                        prospect:prospect,
                        objection:selectedObjection,
                        pendingAddress:pendingAddress) {
                            followUpAddress=prospect.address;
                            followUpProspectName=prospect.fullName;
                            selectedObjection=nil;
                            // showFollowUpPrompt=true
                            showTripPrompt = true
                        }
                }
            }
        .sheet(isPresented:$showObjectionPicker){
            NavigationView{
                List(objectionOptions){
                    obj in
                    Button(obj.text) {
                        selectedObjection = obj
                        obj.timesHeard += 1
                        try? modelContext.save()
                        showObjectionPicker = false

                        // ✅ Insert recording now that objection is selected
                        if let name = pendingRecordingFileName {
                            let newRecording = Recording(fileName: name, date: .now, objection: obj, rating: 3)
                            modelContext.insert(newRecording)
                            try? modelContext.save()
                            pendingRecordingFileName = nil
                        }

                        showFollowUpSheet = true
                    }
                    
        }.navigationTitle("Why not interested?")
          .toolbar{ ToolbarItem(placement:.cancellationAction){ Button("Cancel"){ showObjectionPicker=false } } } } }
        .sheet(isPresented:$showingAddObjection){ AddObjectionView() }
        .alert("Schedule Follow-Up?",isPresented:$showFollowUpPrompt){ Button("Yes"){ showFollowUpSheet=true }
                                                                  Button("No",role:.cancel){ showTripPrompt=true } } message:
              { Text("Schedule follow-up for \(followUpProspectName)?") }
            .sheet(isPresented:$showFollowUpSheet,onDismiss:{
                DispatchQueue.main.asyncAfter(deadline:.now()+0.3){
                    // showTripPrompt=true
                    showNoteInput = true
                }
            }) {
                if let prospect=prospectToNote {
                    FollowUpScheduleView(prospect:prospect)
                }
            }
        .alert("Log a trip?",isPresented:$showTripPrompt){ Button("Yes"){ showTripPopup=true }
                                                      Button("No",role:.cancel){} }
        .sheet(isPresented:$showTripPopup){ if let addr=pendingAddress { LogTripPopupView(endAddress:addr) } }
        .sheet(isPresented:$showConversionSheet){ if let prospect=prospectToConvert { SignUpPopupView(prospect:prospect,isPresented:$showConversionSheet) } }
    }
    
    private func handleOutcome(_ status: String, recordingFileName: String?) {
        if status == "Converted To Sale" {
            let objection = Objection(text: "Converted To Sale", response: "Handled successfully", timesHeard: 0)
            modelContext.insert(objection)
            if let name = recordingFileName {
                let newRecording = Recording(fileName: name, date: .now, objection: objection, rating: 5)
                modelContext.insert(newRecording)
            }
            handleKnockAndConvertToCustomer(status: status)

        } else if status == "Follow Up Later" {
            // Defer recording until objection is picked
            pendingRecordingFileName = recordingFileName
            handleKnockAndPromptObjection(status: status)

        } else if status == "Wasn't Home" {
            handleKnockAndPromptNote(status: status)
        }

        try? modelContext.save()
    }
    
    // This is for the prompts - might be redundant
    private func handleImmediateOutcome(_ status: String) {
        if status == "Converted To Sale" {
            handleKnockAndConvertToCustomer(status: status)
        } else if status == "Wasn't Home" {
            handleKnockAndPromptNote(status: status)
        } else if status == "Follow Up Later" {
            handleKnockAndPromptObjection(status: status)
        }
    }

    private func zoom(by factor: Double) {
        // update region
        let span = controller.region.span
        let newSpan = MKCoordinateSpan(latitudeDelta: span.latitudeDelta * factor,
                                       longitudeDelta: span.longitudeDelta * factor)
        controller.region = MKCoordinateRegion(center: controller.region.center, span: newSpan)
        // close popup when zoom buttons pressed
        showProspectPopup = false
    }

    private func handleMapCenterChange(newAddress: String?) {
        guard let query = newAddress else { return }
        Task {
            if let coord = await controller.geocodeAddress(query) {
                withAnimation {
                    controller.region = MKCoordinateRegion(center: coord, latitudinalMeters:1609.34, longitudinalMeters:1609.34)
                }
            }
            addressToCenter = nil
        }
    }

    @ViewBuilder private var searchSuggestionsList: some View {
        if isSearchFocused && !searchVM.results.isEmpty {
            VStack(spacing:0){
                ForEach(searchVM.results.prefix(3),id:\.self){ res in
                    Button{ handleCompletionTap(res) } label:{
                        VStack(alignment:.leading,spacing:4){
                            Text(res.title).font(.body).bold().lineLimit(1)
                            Text(res.subtitle).font(.subheadline).foregroundColor(.gray).lineLimit(1)
                        }
                        .padding(.vertical,10)
                        .padding(.horizontal)
                        .frame(maxWidth:.infinity,alignment:.leading)
                        .background(Color.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Divider()
                }
            }
            .background(Color.white).cornerRadius(12)
            .padding(.horizontal).padding(.top,4)
            .shadow(radius:4).frame(maxWidth:.infinity,maxHeight:180)
            .transition(.opacity).zIndex(10)
        }
    }

    private func handleCompletionTap(_ result: MKLocalSearchCompletion) {
        let req = MKLocalSearch.Request(completion: result)
        MKLocalSearch(request:req).start{ resp,err in
            guard let item=resp?.mapItems.first else { return }
            let addr=item.placemark.title ?? "\(item.placemark.name ?? ""), \(item.placemark.locality ?? "")"
            DispatchQueue.main.async {
                
                // Keep the text after selecting an autofill address until hit done
                searchText=addr;
                
                pendingAddress=addr;
                controller.region=MKCoordinateRegion(center:item.placemark.coordinate,latitudinalMeters:1609.34,longitudinalMeters:1609.34);
                searchVM.results=[];
                isSearchFocused=false
            }
        }
    }

    private func submitSearch() {
        searchVM.results = []
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        pendingAddress = trimmed
        showOutcomePrompt = true
        
        // Clear the search bar text
        searchText = ""
        
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func updateMarkers() {
        controller.setMarkers(prospects: prospects, customers: customers)
    }

    private func handleSearch(query: String) {
        pendingAddress = query
        showOutcomePrompt = true
    }

    private func saveKnock(address: String, status: String) -> Prospect {
        let normalized = address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()
        let location = LocationManager.shared.currentLocation
        let lat = location?.latitude ?? 0.0
        let lon = location?.longitude ?? 0.0

        var prospectId: Int64?
        var updated: Prospect

        if let existing = prospects.first(where: {
            $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalized
        }) {
            existing.count += 1
            existing.knockHistory.append(Knock(date: now, status: status, latitude: lat, longitude: lon))
            updated = existing
        } else {
            let new = Prospect(fullName: "New Prospect", address: address, count: 1, list: "Prospects")
            new.knockHistory = [Knock(date: now, status: status, latitude: lat, longitude: lon)]
            modelContext.insert(new)
            updated = new

            if let newId = DatabaseController.shared.addProspect(name: new.fullName, addr: new.address) {
                prospectId = newId
            }
        }

        if let id = prospectId {
            DatabaseController.shared.addKnock(for: id, date: now, status: status, latitude: lat, longitude: lon)
        }

        controller.performSearch(query: address)
        try? modelContext.save()
        
        return updated
    }

    private func handleKnockAndPromptNote(status: String) {
        if let addr = pendingAddress {
            let prospect = saveKnock(address: addr, status: status)

            // Only show note popup for statuses other than "Not Answered"
            if status != "Wasn't Home" {
                prospectToNote = prospect
                showNoteInput = true
            } else {
                // Optionally prompt to log a trip even if no note is added
                // DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                //     showTripPrompt = true
                // }
                return
            }
        }
    }
    
    private func handleKnockAndPromptObjection(status: String) {
        guard let addr = pendingAddress else { return }

        let prospect = saveKnock(address: addr, status: status)
        prospectToNote = prospect
        followUpAddress = prospect.address
        followUpProspectName = prospect.fullName

        if objections.isEmpty {
            // Redirect user to create a new objection before proceeding
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                selectedObjection = nil
                // showNoteInput = false
                showingAddObjection = true  // <-- triggers AddObjectionView sheet
            }
        } else {
            objectionOptions = objections.filter { $0.text != "Converted To Sale" }
            showObjectionPicker = true
            // shouldAskForTripAfterFollowUp = true // carry trip flag if needed
        }
    }
    
    private func handleKnockAndConvertToCustomer(status: String) {
        guard let addr = pendingAddress else { return }
        let prospect = saveKnock(address: addr, status: status)
        
        // Update the marker immediately to reflect "Customer" status
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

        prospectToConvert = prospect
        showConversionSheet = true
    }
}
