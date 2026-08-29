//
//  ProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import SwiftData
import ContactsUI

struct ContactManagementView: View {
    private struct ExportFile: Identifiable {
        let id = UUID()
        let url: URL
    }

    private enum ActiveSheet: Identifiable {
        case export(ExportFile)
        case emailGate
        case addProspect

        var id: String {
            switch self {
            case .export(let file):
                return "export-\(file.id)"
            case .emailGate:
                return "emailGate"
            case .addProspect:
                return "addProspect"
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
    @Binding var selectedList: String
    @Binding var searchText: String
    @Binding var activeSearchFilter: ContactSearchFilter?
    var onSave: () -> Void
    var onNavigateToMap: (MapContactSelection) -> Void = { _ in }

    // Shared state
    @State private var selectedSearchField: ContactSearchField = .all
    @StateObject private var controller = ContactManagerController()

    // Menu + overlays
    @State private var showingImportFromContacts = false
    @State private var showImportSuccess = false

    @Query private var prospects: [Prospect]
    @Query private var customers: [Customer]
    
    @State private var showingAddCustomer = false
    
    @State private var selectedProspect: Prospect?
    @State private var selectedCustomer: Customer?
    
    @FocusState private var isSearchFocused: Bool
    
    @State private var isDeletingContacts = false
    @State private var selectedProspects: Set<Prospect> = []
    @State private var selectedCustomers: Set<Customer> = []
    @State private var showDeleteContactsConfirm = false
    
    private var selectedDeleteCount: Int {
        selectedList == "Prospects"
            ? selectedProspects.count
            : selectedCustomers.count
    }
    
    @State private var activeSheet: ActiveSheet?
    @StateObject private var emailGate = EmailGateManager.shared
    
    @State private var showDuplicateToast = false
    @State private var duplicateNames: [String] = []

    @AppStorage("hasCompletedInitialPropertyTutorial") private var hasCompletedInitialPropertyTutorial = false
    @AppStorage("hasCompletedContactScreenTutorial") private var hasCompletedContactScreenTutorial = false
    @State private var isContactTutorialVisible = false
    @State private var contactTutorialStep: ContactScreenTutorialStep = .search
    @State private var showContactTutorialReward = false
    @State private var shouldResumeContactTutorialAfterDetails = false

    private var shouldStartContactTutorial: Bool {
        hasCompletedInitialPropertyTutorial &&
        !hasCompletedContactScreenTutorial &&
        !showingImportFromContacts &&
        activeSheet == nil &&
        !showingAddCustomer
    }
    
    var body: some View {
        
        NavigationView {
            ZStack {
                
                managementContent

                // Toolbar
                ContactsToolbarView(
                    onAddTapped: {
                        if selectedList == "Prospects" {
                            withAnimation(.spring()) {
                                showingImportFromContacts = true
                            }
                        } else {
                            showingAddCustomer = true
                        }
                    },
                    isDeleting: $isDeletingContacts,
                    selectedCount: selectedDeleteCount,
                    onDeleteConfirmed: {
                        showDeleteContactsConfirm = true
                    }
                )
                
            }
            .navigationTitle("")
            .overlay(exportOverlay)
            .overlay(importOverlay)
            .overlay(toastOverlay)
            .overlay(tutorialRewardOverlay)
            .overlay(tutorialOverlay)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .export(let file):
                    ShareSheet(activityItems: [file.url])
                case .emailGate:
                    ExportEmailGateView {
                        activeSheet = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            performExport()
                        }
                    }
                    .presentationDetents([.fraction(0.5)])
                    .presentationDragIndicator(.visible)
                case .addProspect:
                    ProspectCreateStepperView { newProspect in
                        modelContext.insert(newProspect)
                        try? modelContext.save()

                        clearSearchFilter()
                        activeSheet = nil
                        onSave()
                    } onCancel: {
                        activeSheet = nil
                    }
                    .presentationDetents([.fraction(0.5), .fraction(0.58), .large])
                    .presentationDragIndicator(.visible)
                }
            }
            .alert("Delete selected contacts?",
                   isPresented: $showDeleteContactsConfirm) {

                Button("Delete", role: .destructive) {
                    
                    ContactScreenHapticsController.shared.mediumTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                    deleteSelectedContacts()
                    
                }

                Button("Cancel", role: .cancel) {
                    
                    ContactScreenHapticsController.shared.mediumTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                }
            }
            .onChange(of: selectedList) { _, newValue in
                if newValue == "Prospects" {
                    Task {
                        await controller.fetchNextSuggestedNeighbor(
                            from: customers,
                            existingProspects: prospects
                        )
                    }
                }
            }
            .onChange(of: hasCompletedInitialPropertyTutorial) { _, completed in
                guard completed else { return }
                startContactTutorialIfNeeded()
            }
            .onChange(of: selectedProspect) { _, prospect in
                handleContactDetailsSelectionChanged(isPresented: prospect != nil)
            }
            .onChange(of: selectedCustomer) { _, customer in
                handleContactDetailsSelectionChanged(isPresented: customer != nil)
            }
            .onAppear {
                startContactTutorialIfNeeded()
            }
        }
    }
    
    @ViewBuilder
    private var exportOverlay: some View {
        GeometryReader { geo in
            ExportCSVButton(isUnlocked: emailGate.isUnlocked) {
                if emailGate.isUnlocked {
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    performExport()
                } else {
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    activeSheet = .emailGate
                }
            }
            .position(
                x: geo.size.width - 45,
                y: geo.size.height - 55
            )
            .zIndex(999)
        }
    }

    private var importOverlay: some View {
        ImportOverlayView(
            showingImportFromContacts: $showingImportFromContacts,
            showImportSuccess: $showImportSuccess,
            selectedList: $selectedList,
            searchText: $searchText,
            prospects: prospects,
            customers: customers,
            modelContext: modelContext,
            onSave: onSave,
            onOpenDuplicateProspect: { prospect in
                selectedProspect = prospect
            },
            onOpenDuplicateCustomer: { customer in
                selectedCustomer = customer
            },
            onAddManually: {
                activeSheet = .addProspect
            },
            showDuplicateToast: $showDuplicateToast,
            duplicateNames: $duplicateNames
        )
    }

    @ViewBuilder
    private var toastOverlay: some View {
        if showImportSuccess {
            ToastMessageView(message: "Contacts imported successfully!")
        } else if showDuplicateToast {
            let message = duplicateNames.joined(separator: ", ") + " already exist."
            ToastMessageView(message: message)
        }
    }

    @ViewBuilder
    private var tutorialRewardOverlay: some View {
        if showContactTutorialReward {
            ConfettiBurstView()
                .zIndex(4600)
        }
    }

    @ViewBuilder
    private var tutorialOverlay: some View {
        if isContactTutorialVisible {
            ContactScreenTutorialOverlayView(
                step: contactTutorialStep,
                onPrevious: previousContactTutorialStep,
                onNext: nextContactTutorialStep,
                onSkip: finishContactTutorial
            )
            .transition(.opacity)
            .zIndex(4500)
        }
    }

    private func performExport() {
        do {
            let url: URL
            if selectedList == "Prospects" {
                url = try CSVExportService.exportProspects(prospects)
            } else {
                url = try CSVExportService.exportCustomers(customers)
            }
            activeSheet = .export(ExportFile(url: url))
        } catch {
            print("❌ Export failed:", error)
        }
    }
    
    @ViewBuilder
    private var managementContent: some View {
        if selectedList == "Prospects" {
            ProspectManagementView(
                searchText: $searchText,
                selectedSearchField: $selectedSearchField,
                activeSearchFilter: $activeSearchFilter,
                suggestedProspect: $controller.suggestedProspect,
                suggestedNeighborSourceAddress: $controller.suggestedNeighborSourceAddress,
                selectedList: $selectedList,
                onSave: onSave,
                selectedProspect: $selectedProspect,
                isSearchFocused: $isSearchFocused,
                isDeleting: $isDeletingContacts,
                selectedProspects: $selectedProspects,
                onClearSearchFilter: clearSearchFilter,
                onNavigateToMap: onNavigateToMap,
                onProspectOpenRequested: handleTutorialProspectOpenRequested
            )
        } else {
            CustomerManagementView(
                searchText: $searchText,
                selectedSearchField: $selectedSearchField,
                activeSearchFilter: $activeSearchFilter,
                selectedList: $selectedList,
                onSave: onSave,
                showingAddCustomer: $showingAddCustomer,
                selectedCustomer: $selectedCustomer,
                isSearchFocused: $isSearchFocused,
                isDeleting: $isDeletingContacts,
                selectedCustomers: $selectedCustomers,
                onClearSearchFilter: clearSearchFilter,
                onNavigateToMap: onNavigateToMap,
                onCustomerOpenRequested: handleTutorialCustomerOpenRequested
            )
        }
    }

    private func clearSearchFilter() {
        searchText = ""
        activeSearchFilter = nil
    }

    private func startContactTutorialIfNeeded() {
        guard shouldStartContactTutorial else { return }
        guard !isContactTutorialVisible else { return }

        contactTutorialStep = .search
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            guard shouldStartContactTutorial else { return }
            withAnimation(.easeOut(duration: 0.26)) {
                isContactTutorialVisible = true
            }
        }
    }

    private func previousContactTutorialStep() {
        guard let previous = ContactScreenTutorialStep(rawValue: contactTutorialStep.rawValue - 1) else { return }

        ContactScreenHapticsController.shared.lightTap()
        ContactScreenSoundController.shared.playSound1()

        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            contactTutorialStep = previous
        }
    }

    private func nextContactTutorialStep() {
        ContactScreenHapticsController.shared.lightTap()
        ContactScreenSoundController.shared.playSound1()

        guard let next = ContactScreenTutorialStep(rawValue: contactTutorialStep.rawValue + 1) else {
            finishContactTutorial()
            return
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            contactTutorialStep = next
        }
    }

    private func handleTutorialProspectOpenRequested(_ prospect: Prospect) -> Bool {
        guard beginTutorialContactDetailsReward() else { return false }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.58) {
            selectedProspect = prospect
        }

        return true
    }

    private func handleTutorialCustomerOpenRequested(_ customer: Customer) -> Bool {
        guard beginTutorialContactDetailsReward() else { return false }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.58) {
            selectedCustomer = customer
        }

        return true
    }

    private func beginTutorialContactDetailsReward() -> Bool {
        guard isContactTutorialVisible && contactTutorialStep == .contacts else { return false }

        shouldResumeContactTutorialAfterDetails = true
        ContactScreenHapticsController.shared.successConfirmationTap()
        ContactScreenSoundController.shared.playSound1()

        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
            showContactTutorialReward = true
            isContactTutorialVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.18)) {
                showContactTutorialReward = false
            }
        }

        return true
    }

    private func handleContactDetailsSelectionChanged(isPresented: Bool) {
        guard !isPresented else { return }
        guard shouldResumeContactTutorialAfterDetails else { return }

        shouldResumeContactTutorialAfterDetails = false
        contactTutorialStep = .add

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            guard !hasCompletedContactScreenTutorial else { return }
            guard !showingImportFromContacts && activeSheet == nil && !showingAddCustomer else { return }

            withAnimation(.easeOut(duration: 0.24)) {
                isContactTutorialVisible = true
            }
        }
    }

    private func finishContactTutorial() {
        guard !hasCompletedContactScreenTutorial else { return }

        ContactScreenHapticsController.shared.successConfirmationTap()
        ContactScreenSoundController.shared.playSound1()

        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            showContactTutorialReward = true
            isContactTutorialVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.2)) {
                showContactTutorialReward = false
            }
        }

        hasCompletedContactScreenTutorial = true
    }
    
    private func deleteSelectedContacts() {
        
        withAnimation {
            
            ContactScreenHapticsController.shared.successConfirmationTap()
            ContactScreenSoundController.shared.playSound1()

            if selectedList == "Prospects" {
                for p in selectedProspects {
                    p.appointments.forEach { modelContext.delete($0) }
                    modelContext.delete(p)
                }
                selectedProspects.removeAll()
            } else {
                for c in selectedCustomers {
                    c.appointments.forEach { modelContext.delete($0) }
                    modelContext.delete(c)
                }
                selectedCustomers.removeAll()
            }

            try? modelContext.save()
            isDeletingContacts = false
        }
    }
    
}
