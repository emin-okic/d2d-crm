//
//  ProspectKnockingHistoryView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/21/25.
//


import SwiftUI
import SwiftData

struct ProspectKnockingHistoryView: View {

    @Bindable var prospect: Prospect
    @Environment(\.modelContext) private var modelContext

    @State private var isDeleting = false
    @State private var selectedKnocks: Set<Knock> = []
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            if prospect.knockHistory.isEmpty {
                ContentUnavailableView(
                    "No Knocks Yet",
                    systemImage: "hand.tap",
                    description: Text("Recorded knocks will appear here.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(prospect.sortedKnocks) { knock in
                            HStack(spacing: 10) {
                                if isDeleting {
                                    Image(
                                        systemName: selectedKnocks.contains(knock)
                                            ? "checkmark.circle.fill"
                                            : "circle"
                                    )
                                    .font(.title3)
                                    .foregroundStyle(.red)
                                    .accessibilityHidden(true)
                                }

                                knockRow(knock)
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        isDeleting && selectedKnocks.contains(knock)
                                            ? Color.red.opacity(0.08)
                                            : Color(.secondarySystemBackground)
                                    )
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isDeleting {
                                    toggleSelection(knock)
                                }
                            }
                            .accessibilityAddTraits(isDeleting ? .isButton : [])
                            .accessibilityValue(
                                isDeleting && selectedKnocks.contains(knock)
                                    ? "Selected"
                                    : ""
                            )
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                }
                .scrollDisabled(prospect.knockHistory.count <= 3)
            }
        }
        .toolbar {
            if !prospect.knockHistory.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isDeleting ? "Done" : "Select") {
                        toggleDeleteMode()
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isDeleting {
                deleteActionBar
            }
        }
        .alert(
            "Delete \(selectedKnocks.count) Knock\(selectedKnocks.count == 1 ? "" : "s")?",
            isPresented: $showDeleteConfirm
        ) {
            Button("Delete", role: .destructive) {
                ContactScreenHapticsController.shared.mediumTap()
                ContactScreenSoundController.shared.playSound1()
                deleteSelectedKnocks()
            }
            Button("Cancel", role: .cancel) {
                ContactScreenHapticsController.shared.lightTap()
                ContactScreenSoundController.shared.playSound1()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private var deleteActionBar: some View {
        VStack(spacing: 8) {
            Text(
                selectedKnocks.isEmpty
                    ? "Select the knocks you want to remove"
                    : "\(selectedKnocks.count) selected"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Button(role: .destructive) {
                ContactScreenHapticsController.shared.mediumTap()
                ContactScreenSoundController.shared.playSound1()
                showDeleteConfirm = true
            } label: {
                Label(
                    selectedKnocks.isEmpty
                        ? "Delete Knocks"
                        : "Delete \(selectedKnocks.count) Knock\(selectedKnocks.count == 1 ? "" : "s")",
                    systemImage: "trash"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(selectedKnocks.isEmpty)
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(.bar)
    }

    // MARK: - Row UI
    private func knockRow(_ knock: Knock) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(knock.status, systemImage: icon(for: knock.status))
                    .font(.subheadline)
                Spacer()
                Text(knock.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Text("📍 \(knock.latitude, specifier: "%.5f"), \(knock.longitude, specifier: "%.5f")")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Actions
    private func toggleSelection(_ knock: Knock) {
        
        if selectedKnocks.contains(knock) {
            
            selectedKnocks.remove(knock)
            
            ContactScreenHapticsController.shared.lightTap()
            ContactScreenSoundController.shared.playSound1()
            
        } else {
            
            selectedKnocks.insert(knock)
            
            ContactScreenHapticsController.shared.lightTap()
            ContactScreenSoundController.shared.playSound1()
            
        }
    }

    private func toggleDeleteMode() {
        ContactScreenHapticsController.shared.lightTap()
        ContactScreenSoundController.shared.playSound1()

        withAnimation {
            isDeleting.toggle()

            if !isDeleting {
                selectedKnocks.removeAll()
            }
        }
    }

    private func deleteSelectedKnocks() {
        
        for knock in selectedKnocks {
            
            prospect.knockHistory.removeAll { $0.id == knock.id }
            
            modelContext.delete(knock)
            
        }

        try? modelContext.save()
        
        ContactScreenHapticsController.shared.successConfirmationTap()
        ContactScreenSoundController.shared.playSound1()

        selectedKnocks.removeAll()
        
        withAnimation {
            isDeleting = false
        }
    }

    // MARK: - Icon helper
    private func icon(for status: String) -> String {
        let lower = status.lowercased()
        if lower.contains("converted") || lower.contains("sale") {
            return "checkmark.seal.fill"
        } else if lower.contains("follow") {
            return "clock.fill"
        } else if lower.contains("wasn") || lower.contains("no answer") {
            return "house.slash.fill"
        } else if lower.contains("unqualified") {
            return "xmark.octagon.fill"
        } else {
            return "hand.tap.fill"
        }
    }
}
