//
//  TripDetailsView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/19/25.
//
import SwiftUI
import SwiftData

struct TripDetailsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var trip: Trip

    @State private var startAddress: String
    @State private var endAddress: String
    @State private var date: Date

    @FocusState private var focusedField: Field?
    @StateObject private var searchVM = SearchCompleterViewModel()

    @State private var showDeleteConfirmation = false
    @State private var showDateEditor = false
    @State private var showTimeEditor = false
    @State private var isSaving = false

    // MARK: - Init
    init(trip: Trip) {
        self.trip = trip
        _startAddress = State(initialValue: trip.startAddress)
        _endAddress = State(initialValue: trip.endAddress)
        _date = State(initialValue: trip.date)
    }

    // MARK: - Dirty check
    private var hasUnsavedEdits: Bool {
        startAddress.trimmingCharacters(in: .whitespacesAndNewlines) != trip.startAddress.trimmingCharacters(in: .whitespacesAndNewlines) ||
        endAddress.trimmingCharacters(in: .whitespacesAndNewlines) != trip.endAddress.trimmingCharacters(in: .whitespacesAndNewlines) ||
        date != trip.date
    }

    private var hasUnsavedAddressEdits: Bool {
        startAddress.trimmingCharacters(in: .whitespacesAndNewlines) != trip.startAddress.trimmingCharacters(in: .whitespacesAndNewlines) ||
        endAddress.trimmingCharacters(in: .whitespacesAndNewlines) != trip.endAddress.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isEditingAddress: Bool {
        focusedField != nil || hasUnsavedAddressEdits
    }

    private var canSave: Bool {
        hasUnsavedEdits &&
        !isSaving &&
        !startAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !endAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    routePreview
                    tripSummary
                    routeEditor
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 130)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Trip Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        TripManagerHapticsController.shared.lightTap()
                        TripManagerSoundController.shared.playSound1()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomActions
            }
        }
        .alert("Delete Trip?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                TripManagerHapticsController.shared.mediumTap()
                TripManagerSoundController.shared.playSound1()

                context.delete(trip)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {
                TripManagerHapticsController.shared.lightTap()
                TripManagerSoundController.shared.playSound1()
            }
        } message: {
            Text("This trip will be permanently deleted.")
        }
        .sheet(isPresented: $showDateEditor) {
            dateEditorSheet(
                title: "Edit Date",
                displayedComponents: [.date],
                detent: .fraction(0.34)
            )
        }
        .sheet(isPresented: $showTimeEditor) {
            dateEditorSheet(
                title: "Edit Time",
                displayedComponents: [.hourAndMinute],
                detent: .fraction(0.28)
            )
        }
    }

    private var routePreview: some View {
        Button {
            TripManagerHapticsController.shared.lightTap()
            TripManagerSoundController.shared.playSound1()
            openTripInAppleMaps()
        } label: {
            ZStack(alignment: .bottomLeading) {
                RouteMapView(startAddress: startAddress, endAddress: endAddress)
                    .frame(height: 210)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                LinearGradient(
                    colors: [.clear, .black.opacity(0.62)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Label("\(trip.miles, specifier: "%.1f") miles", systemImage: "car.fill")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Open route in Apple Maps")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.86))
                }
                .padding(16)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var tripSummary: some View {
        HStack(spacing: 10) {
            metricTile(title: "Distance", value: String(format: "%.1f", trip.miles), unit: "mi", iconName: "gauge.with.dots.needle.33percent")
            editableMetricTile(
                title: "Date",
                value: date.formatted(.dateTime.month(.abbreviated).day()),
                unit: date.formatted(.dateTime.year()),
                iconName: "calendar"
            ) {
                TripManagerHapticsController.shared.lightTap()
                TripManagerSoundController.shared.playSound1()
                showDateEditor = true
            }
            editableMetricTile(
                title: "Time",
                value: date.formatted(.dateTime.hour().minute()),
                unit: "",
                iconName: "clock"
            ) {
                TripManagerHapticsController.shared.lightTap()
                TripManagerSoundController.shared.playSound1()
                showTimeEditor = true
            }
        }
    }

    private var routeEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Route")

            VStack(spacing: 0) {
                TripAddressFieldView(
                    iconName: "circle.fill",
                    placeholder: "Start Address",
                    iconColor: .green,
                    addressText: $startAddress,
                    focusedField: $focusedField,
                    fieldType: .start,
                    searchVM: searchVM
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .simultaneousGesture(TapGesture().onEnded {
                    TripManagerHapticsController.shared.lightTap()
                    TripManagerSoundController.shared.playSound1()
                })

                Divider()
                    .padding(.leading, 42)

                TripAddressFieldView(
                    iconName: "mappin.circle.fill",
                    placeholder: "End Address",
                    iconColor: .red,
                    addressText: $endAddress,
                    focusedField: $focusedField,
                    fieldType: .end,
                    searchVM: searchVM
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .simultaneousGesture(TapGesture().onEnded {
                    TripManagerHapticsController.shared.lightTap()
                    TripManagerSoundController.shared.playSound1()
                })
            }
            .background(cardBackground)
        }
    }

    private var bottomActions: some View {
        HStack(spacing: 12) {
            if isEditingAddress {
                Button {
                    revertAddressEdits()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.headline)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            } else {
                Button(role: .destructive) {
                    TripManagerHapticsController.shared.lightTap()
                    TripManagerSoundController.shared.playSound1()
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.headline)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            Button {
                saveTrip()
            } label: {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark")
                    }

                    Text(hasUnsavedEdits ? "Save Changes" : "Saved")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSave)
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
        .animation(.spring(response: 0.25, dampingFraction: 0.88), value: isEditingAddress)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.secondary)
    }

    private func metricTile(title: String, value: String, unit: String, iconName: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: iconName)
                .font(.subheadline)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 94)
        .background(cardBackground)
    }

    private func editableMetricTile(title: String, value: String, unit: String, iconName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            metricTile(title: title, value: value, unit: unit, iconName: iconName)
        }
        .buttonStyle(.plain)
    }

    private func dateEditorSheet(title: String, displayedComponents: DatePickerComponents, detent: PresentationDetent) -> some View {
        NavigationStack {
            VStack(spacing: 18) {
                DatePicker(title, selection: $date, displayedComponents: displayedComponents)
                    .datePickerStyle(.wheel)
                    .labelsHidden()

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        TripManagerHapticsController.shared.lightTap()
                        TripManagerSoundController.shared.playSound1()
                        showDateEditor = false
                        showTimeEditor = false
                    }
                }
            }
        }
        .presentationDetents([detent])
        .presentationDragIndicator(.visible)
    }

    private func revertAddressEdits() {
        TripManagerHapticsController.shared.mediumTap()
        TripManagerSoundController.shared.playSound1()

        startAddress = trip.startAddress
        endAddress = trip.endAddress
        focusedField = nil
        searchVM.results = []
    }

    private func openTripInAppleMaps() {
        let encodedStart = startAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedEnd = endAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        guard let url = URL(string: "http://maps.apple.com/?saddr=\(encodedStart)&daddr=\(encodedEnd)&dirflg=d") else {
            return
        }

        UIApplication.shared.open(url)
    }

    private func saveTrip() {
        guard canSave else { return }

        TripManagerHapticsController.shared.successConfirmationTap()
        TripManagerSoundController.shared.playSound1()

        isSaving = true
        Task {
            let distance = await TripsController.shared.calculateMiles(
                from: startAddress,
                to: endAddress
            )

            await MainActor.run {
                trip.startAddress = startAddress
                trip.endAddress = endAddress
                trip.miles = distance
                trip.date = date
                try? context.save()
                isSaving = false
                focusedField = nil
            }
        }
    }
}
