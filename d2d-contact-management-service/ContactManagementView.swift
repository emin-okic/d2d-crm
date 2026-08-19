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
    @AppStorage("hasCompletedInitialContactTutorial") private var hasCompletedInitialContactTutorial = false
    @State private var isInitialContactTutorialVisible = false
    @State private var initialContactTutorialStep: InitialContactTutorialStep = .tapAdd
    @State private var showContactTutorialConfetti = false

    private var shouldStartInitialContactTutorial: Bool {
        hasCompletedInitialPropertyTutorial &&
        !hasCompletedInitialContactTutorial &&
        selectedList == "Prospects"
    }

    private var shouldShowInitialContactTutorialOverlay: Bool {
        isInitialContactTutorialVisible &&
        !hasCompletedInitialContactTutorial &&
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
                        advanceInitialContactTutorialToOptionsIfNeeded()

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
            .overlay(
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
                        x: geo.size.width - 45, // 20 trailing + 25 half width
                        y: geo.size.height - 55 // 30 bottom + 25 half height
                    )
                    .zIndex(999)
                }
            )
            .overlay(
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
                    isTutorialActive: isInitialContactTutorialVisible && initialContactTutorialStep == .chooseMethod,
                    onTutorialContactAdded: completeInitialContactTutorial,
                    showDuplicateToast: $showDuplicateToast,
                    duplicateNames: $duplicateNames
                )
            )
            .overlay(
                Group {
                    if showImportSuccess {
                        ToastMessageView(message: "Contacts imported successfully!")
                    } else if showDuplicateToast {
                        let message = duplicateNames.joined(separator: ", ") + " already exist."
                        ToastMessageView(message: message)
                    }
                }
            )
            .overlay(
                Group {
                    if showContactTutorialConfetti {
                        ConfettiBurstView()
                            .zIndex(4500)
                    }
                }
            )
            .overlay(
                Group {
                    if shouldShowInitialContactTutorialOverlay {
                        InitialContactTutorialOverlayView(step: initialContactTutorialStep)
                            .allowsHitTesting(false)
                            .transition(.opacity)
                            .zIndex(4400)
                    }
                }
            )
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
                        completeInitialContactTutorial()
                    } onCancel: {
                        activeSheet = nil
                    }
                    .presentationDetents([.fraction(0.5)]) // 50% of screen height
                    .presentationDragIndicator(.visible)    // optional: show the drag handle
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
                    startInitialContactTutorialIfNeeded()
                }
            }
            .onChange(of: hasCompletedInitialPropertyTutorial) { _, completed in
                guard completed else { return }
                startInitialContactTutorialIfNeeded()
            }
            .onAppear {
                startInitialContactTutorialIfNeeded()
            }
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
                selectedList: $selectedList,
                onSave: onSave,
                selectedProspect: $selectedProspect,
                isSearchFocused: $isSearchFocused,
                isDeleting: $isDeletingContacts,
                selectedProspects: $selectedProspects,
                onClearSearchFilter: clearSearchFilter
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
                onContactAdded: completeInitialContactTutorial
            )
        }
    }

    private func clearSearchFilter() {
        searchText = ""
        activeSearchFilter = nil
    }

    private func startInitialContactTutorialIfNeeded() {
        guard shouldStartInitialContactTutorial else { return }
        guard !isInitialContactTutorialVisible else { return }

        initialContactTutorialStep = .tapAdd
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            guard shouldStartInitialContactTutorial else { return }
            withAnimation(.easeOut(duration: 0.28)) {
                isInitialContactTutorialVisible = true
            }
        }
    }

    private func advanceInitialContactTutorialToOptionsIfNeeded() {
        guard isInitialContactTutorialVisible else { return }
        guard initialContactTutorialStep == .tapAdd else { return }

        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            initialContactTutorialStep = .chooseMethod
        }
    }

    private func completeInitialContactTutorial() {
        guard isInitialContactTutorialVisible else { return }

        ContactScreenHapticsController.shared.successConfirmationTap()
        ContactScreenSoundController.shared.playSound1()

        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            initialContactTutorialStep = .completed
            showContactTutorialConfetti = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.2)) {
                showContactTutorialConfetti = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            hasCompletedInitialContactTutorial = true
            withAnimation(.easeOut(duration: 0.24)) {
                isInitialContactTutorialVisible = false
            }
        }
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
