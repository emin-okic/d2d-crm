//
//  ProspectManagementView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/23/25.
//

import SwiftUI
import SwiftData

enum ProspectStatusFilter: String, CaseIterable, Identifiable {
    case all
    case unqualified

    var id: String { rawValue }

    func matches(_ prospect: Prospect) -> Bool {
        switch self {
        case .all:
            return true
        case .unqualified:
            return prospect.isUnqualified
        }
    }
}

struct ProspectManagementView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Binding var searchText: String
    @Binding var selectedSearchField: ContactSearchField
    @Binding var activeSearchFilter: ContactSearchFilter?
    @Binding var suggestedProspect: Prospect?
    @Binding var suggestedNeighborSourceAddress: String?
    @Binding var selectedList: String
    
    var onSave: () -> Void

    @Query private var prospects: [Prospect]

    private var totalProspects: Int {
        prospects.filter { $0.list == "Prospects" }.count
    }
    
    @Binding var selectedProspect: Prospect?
    
    @FocusState<Bool>.Binding var isSearchFocused: Bool
    
    @Binding var isDeleting: Bool
    @Binding var selectedProspects: Set<Prospect>
    var onClearSearchFilter: () -> Void
    var onNavigateToMap: (MapContactSelection) -> Void = { _ in }
    var onProspectOpenRequested: (Prospect) -> Bool = { _ in false }
    var onSuggestionReview: () -> Void = {}
    var onSuggestionRejected: () -> Void = {}

    @State private var isShowingSuggestedProspectSheet = false
    @State private var dismissedSuggestionAddress: String?
    @State private var statusFilter: ProspectStatusFilter = .all

    private var unqualifiedProspectCount: Int {
        prospects.filter { $0.list == "Prospects" && $0.isUnqualified }.count
    }

    private var visibleProspects: [Prospect] {
        prospects.filter { prospect in
            guard prospect.list == selectedList, statusFilter.matches(prospect) else {
                return false
            }

            guard let filter = activeSearchFilter, !filter.isEmpty else {
                return true
            }

            return prospect.matches(filter)
        }
    }

    private var filteredProspectCount: Int {
        visibleProspects.count
    }

    private var areAllVisibleProspectsSelected: Bool {
        !visibleProspects.isEmpty && visibleProspects.allSatisfy(selectedProspects.contains)
    }

    var body: some View {
        VStack(spacing: 12) {
            
            ProspectFilterRow(
                searchText: $searchText,
                selectedField: $selectedSearchField,
                isSearchFocused: $isSearchFocused,
                onSubmit: applySearchFilter,
                onClear: onClearSearchFilter
            )

            if let filter = activeSearchFilter, !filter.isEmpty {
                ContactFilterBanner(
                    filter: filter,
                    resultCount: filteredProspectCount,
                    listName: selectedList,
                    onClear: onClearSearchFilter
                )
                .padding(.horizontal, 20)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if shouldShowSuggestionBanner, let suggestedProspect {
                SuggestedProspectBannerView(
                    suggestion: suggestedProspect,
                    onOpen: {
                        ContactScreenHapticsController.shared.lightTap()
                        ContactScreenSoundController.shared.playSound1()
                        onSuggestionReview()
                        isShowingSuggestedProspectSheet = true
                    },
                    onDismiss: dismissSuggestionBanner
                )
                .padding(.horizontal, 20)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            ProspectHeaderView(totalProspects: totalProspects)

            // Toggle chips under header (uses shared binding now)
            ToggleChipsView(selectedList: $selectedList)

            statusFilterBar
                .padding(.horizontal, 20)

            ProspectContainerView(
                selectedList: $selectedList,
                activeSearchFilter: $activeSearchFilter,
                statusFilter: $statusFilter,
                selectedProspect: $selectedProspect,
                isDeleting: $isDeleting,
                selectedProspects: $selectedProspects,
                onNavigateToMap: onNavigateToMap,
                onProspectOpenRequested: onProspectOpenRequested
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
        .overlay {
            if isShowingSuggestedProspectSheet {
                Color.black.opacity(0.44)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isShowingSuggestedProspectSheet)
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: shouldShowSuggestionBanner)
        .onChange(of: statusFilter) { _, _ in
            selectedProspects.removeAll()
        }
        .onChange(of: suggestedProspect?.address) { _, newAddress in
            guard newAddress != dismissedSuggestionAddress else { return }
            dismissedSuggestionAddress = nil
            isShowingSuggestedProspectSheet = false
        }
        .sheet(isPresented: $isShowingSuggestedProspectSheet, onDismiss: clearSuggestion) {
            if let suggestion = suggestedProspect {
                SuggestedProspectSheetView(
                    suggestion: suggestion,
                    nearbyCustomerAddress: suggestedNeighborSourceAddress,
                    onAdd: {
                        modelContext.insert(suggestion)
                        try? modelContext.save()
                        clearSuggestion()
                        onClearSearchFilter()
                        onSave()
                    },
                    onDismiss: clearSuggestion
                )
            }
        }
    }

    private var statusFilterBar: some View {
        HStack(spacing: 8) {
            statusFilterButton(
                title: "All",
                count: totalProspects,
                systemImage: "person.2.fill",
                filter: .all
            )

            statusFilterButton(
                title: "Unqualified",
                count: unqualifiedProspectCount,
                systemImage: "xmark.octagon.fill",
                filter: .unqualified
            )

            Spacer(minLength: 0)

            if isDeleting && statusFilter == .unqualified && !visibleProspects.isEmpty {
                Button(areAllVisibleProspectsSelected ? "Deselect All" : "Select All") {
                    toggleAllVisibleProspects()
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.plain)
                .foregroundStyle(.red)
                .accessibilityHint("Applies to the currently visible unqualified prospects")
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isDeleting)
    }

    private func statusFilterButton(
        title: String,
        count: Int,
        systemImage: String,
        filter: ProspectStatusFilter
    ) -> some View {
        let isSelected = statusFilter == filter

        return Button {
            ContactScreenHapticsController.shared.lightTap()
            statusFilter = filter
        } label: {
            Label("\(title) \(count)", systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : filter == .unqualified ? Color.red : Color.primary)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(
                    isSelected
                        ? (filter == .unqualified ? Color.red : Color.accentColor)
                        : Color(.secondarySystemBackground),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(count) prospects")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func toggleAllVisibleProspects() {
        ContactScreenHapticsController.shared.lightTap()

        if areAllVisibleProspectsSelected {
            visibleProspects.forEach { selectedProspects.remove($0) }
        } else {
            selectedProspects.formUnion(visibleProspects)
        }
    }

    private var shouldShowSuggestionBanner: Bool {
        guard let suggestedProspect else { return false }
        return suggestedProspect.address != dismissedSuggestionAddress && !isShowingSuggestedProspectSheet
    }

    private func dismissSuggestionBanner() {
        ContactScreenHapticsController.shared.lightTap()
        ContactScreenSoundController.shared.playSound1()
        rejectSuggestion()
    }

    private func clearSuggestion() {
        dismissedSuggestionAddress = suggestedProspect?.address
        suggestedProspect = nil
        suggestedNeighborSourceAddress = nil
        isShowingSuggestedProspectSheet = false
    }

    private func rejectSuggestion() {
        dismissedSuggestionAddress = suggestedProspect?.address
        onSuggestionRejected()
        isShowingSuggestedProspectSheet = false
    }

    private func applySearchFilter() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onClearSearchFilter()
            return
        }

        activeSearchFilter = ContactSearchFilter(field: selectedSearchField, query: trimmed)
        searchText = ""
        isSearchFocused = false
    }
}
