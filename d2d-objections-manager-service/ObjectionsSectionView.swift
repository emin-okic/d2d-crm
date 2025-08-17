//
//  ObjectionsSectionView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//
import SwiftUI
import SwiftData

struct ObjectionsSectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var objections: [Objection]

    @State private var selectedObjection: Objection?
    @State private var showingAddObjection = false

    // ✅ Multi-delete state
    @State private var isEditing = false
    @State private var selectedObjections: Set<Objection> = []
    @State private var showDeleteConfirm = false
    @State private var trashPulse = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Biggest Objections")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal, 20)

                    if objections.isEmpty {
                        Text("No objections recorded yet.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                    } else {
                        let ranked = objections
                            .filter { $0.text != "Converted To Sale" }
                            .sorted { $0.timesHeard > $1.timesHeard }
                            .enumerated()
                            .map { RankedObjection(rank: $0.offset + 1, objection: $0.element) }

                        VStack(spacing: 0) {
                            ForEach(ranked) { ranked in
                                HStack {
                                    if isEditing {
                                        Image(systemName: selectedObjections.contains(ranked.objection) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(.blue)
                                    }

                                    Button {
                                        if isEditing {
                                            toggleSelection(for: ranked.objection)
                                        } else {
                                            selectedObjection = ranked.objection
                                        }
                                    } label: {
                                        HStack {
                                            Text("#\(ranked.rank)")
                                                .frame(width: 40, alignment: .leading)
                                            VStack(alignment: .leading) {
                                                Text(ranked.objection.text)
                                                    .font(.headline)
                                            }
                                            .padding(.vertical, 10)
                                            Spacer()
                                            Text("×\(ranked.objection.timesHeard)")
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 20)
                                    }
                                    .buttonStyle(.plain)
                                }

                                Divider().padding(.leading, 60)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.top, 12)
            }

            // Floating toolbar
            VStack(spacing: 12) {
                // Add Objection
                Button {
                    showingAddObjection = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color.blue))
                        .shadow(radius: 4)
                }

                // Trash (multi-delete toggle/confirm)
                Button {
                    if isEditing {
                        if selectedObjections.isEmpty {
                            withAnimation {
                                isEditing = false
                                trashPulse = false
                            }
                        } else {
                            showDeleteConfirm = true
                        }
                    } else {
                        withAnimation {
                            isEditing = true
                            trashPulse = true
                        }
                    }
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle().fill(isEditing ? Color.red : Color.blue)
                            )
                            .scaleEffect(isEditing ? (trashPulse ? 1.06 : 1.0) : 1.0)
                            .rotationEffect(.degrees(isEditing ? (trashPulse ? 2 : -2) : 0))
                            .shadow(color: (isEditing ? Color.red.opacity(0.45) : Color.black.opacity(0.25)),
                                    radius: 6, x: 0, y: 2)
                            .animation(
                                isEditing
                                ? .easeInOut(duration: 0.75).repeatForever(autoreverses: true)
                                : .default,
                                value: trashPulse
                            )

                        if isEditing && !selectedObjections.isEmpty {
                            Text("\(selectedObjections.count)")
                                .font(.caption2).bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.black.opacity(0.7)))
                                .offset(x: 10, y: -10)
                        }
                    }
                }
                .accessibilityLabel(isEditing ? "Delete selected objections" : "Enter delete mode")
            }
            .padding(.bottom, 30)
            .padding(.leading, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .zIndex(999)
        }
        .sheet(item: $selectedObjection) { obj in
            ObjectionDetailsView(objection: obj)
        }
        .sheet(isPresented: $showingAddObjection) {
            AddObjectionView()
        }
        .alert("Delete selected objections?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                deleteSelected()
                withAnimation {
                    isEditing = false
                    trashPulse = false
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action can’t be undone.")
        }
    }

    // MARK: - Helpers
    private func toggleSelection(for obj: Objection) {
        if selectedObjections.contains(obj) {
            selectedObjections.remove(obj)
        } else {
            selectedObjections.insert(obj)
        }
    }

    private func deleteSelected() {
        for obj in selectedObjections {
            modelContext.delete(obj)
        }
        try? modelContext.save()
        selectedObjections.removeAll()
    }
}
