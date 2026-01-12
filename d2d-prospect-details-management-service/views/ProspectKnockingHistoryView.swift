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

    var body: some View {
        VStack(spacing: 12) {

            // Toolbar
            HStack {
                Text("Knocking History")
                    .font(.headline)
                Spacer()
                Button {
                    handleTrashTap()
                } label: {
                    Image(systemName: "trash.fill")
                        .foregroundColor(isDeleting ? .red : .blue)
                }
            }
            .padding(.horizontal)

            if prospect.knockHistory.isEmpty {
                Text("No knocks recorded yet.")
                    .foregroundColor(.secondary)
                    .font(.callout)
                    .padding(.top, 8)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(prospect.sortedKnocks) { knock in
                            HStack(spacing: 10) {

                                if isDeleting {
                                    Image(systemName:
                                            selectedKnocks.contains(knock)
                                            ? "checkmark.circle.fill"
                                            : "circle"
                                    )
                                    .foregroundColor(.red)
                                }

                                knockRow(knock)
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isDeleting && selectedKnocks.contains(knock)
                                          ? Color.red.opacity(0.06)
                                          : Color(.secondarySystemBackground))
                            )
                            .onTapGesture {
                                if isDeleting {
                                    toggleSelection(knock)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, 6)
                }
            }
        }
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
        } else {
            selectedKnocks.insert(knock)
        }
    }

    private func handleTrashTap() {
        if isDeleting {
            if selectedKnocks.isEmpty {
                // exit delete mode
                withAnimation {
                    isDeleting = false
                }
            } else {
                deleteSelectedKnocks()
            }
        } else {
            withAnimation {
                isDeleting = true
            }
        }
    }

    private func deleteSelectedKnocks() {
        for knock in selectedKnocks {
            // remove from relationship
            prospect.knockHistory.removeAll { $0.id == knock.id }
            // delete from SwiftData
            modelContext.delete(knock)
        }

        try? modelContext.save()

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
