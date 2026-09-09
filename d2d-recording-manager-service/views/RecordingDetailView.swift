//
//  RecordingDetailView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/1/25.
//

import SwiftUI
import AVFoundation
import SwiftData

struct RecordingDetailView: View {
    @Bindable var recording: Recording
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var prospects: [Prospect]
    @Query private var customers: [Customer]

    // MARK: - Editing State
    @State private var tempFileName: String = ""
    @State private var showRevertConfirmation = false

    // MARK: - Audio
    @State private var audioPlayer: AVAudioPlayer?
    @State private var waveformSamples: [CGFloat] = []
    @State private var duration: TimeInterval = 1
    @State private var currentTime: TimeInterval = 0
    @State private var timer: Timer?
    
    @State private var tempTitle: String = ""
    @State private var showContactPicker = false
    @State private var selectedProspect: Prospect?
    @State private var selectedCustomer: Customer?

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // MARK: - Header Card
                        VStack(alignment: .leading, spacing: 12) {
                            
                            // Editable Title
                            TextField("Recording Title", text: $tempTitle)
                                .font(.title2.bold())
                                .textFieldStyle(.plain)
                            
                            if let text = recording.objection?.text {
                                TagView(text: text, color: .blue)
                            }
                            
                            // Always show stars, even if rating is nil or 0
                            HStack(spacing: 4) {
                                ForEach(0..<5, id: \.self) { i in
                                    Image(systemName: i < (recording.rating ?? 0) ? "star.fill" : "star")
                                        .foregroundColor(i < (recording.rating ?? 0) ? .yellow : .gray.opacity(0.4))
                                        .onTapGesture {
                                            
                                            // Haptics & sound
                                            RecordingScreenHapticsController.shared.lightTap()
                                            RecordingScreenSoundController.shared.playSound1()
                                            
                                            recording.rating = i + 1
                                            try? modelContext.save()
                                        }
                                }
                            }
                        }
                        .padding()
                        .background(cardBackground)
                        
                        // MARK: - Playback Card
                        VStack(spacing: 16) {
                            
                            WaveformView(
                                samples: waveformSamples,
                                currentProgress: currentTime / duration
                            ) { seek(to: $0) }
                                .frame(height: 60)
                            
                            HStack {
                                Text(formatTime(currentTime))
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(formatTime(duration))
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: {
                                RecordingScreenHapticsController.shared.lightTap()
                                RecordingScreenSoundController.shared.playSound1()
                                playOrPause()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    Text(isPlaying ? "Pause" : "Play Recording")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isPlaying ? Color.orange : Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                        }
                        .padding()
                        .background(cardBackground)
                        
                        // MARK: - Contact Card
                        RecordingContactRow(
                            prospect: recording.prospect,
                            customer: recording.customer,
                            onOpen: openLinkedContact,
                            onChange: { showContactPicker = true }
                        )
                        .padding()
                        .background(cardBackground)
                        
                    }
                    .padding()
                }
                .navigationTitle("Recording")
                .navigationBarTitleDisplayMode(.inline)
                
                
                RecordingDetailToolbarView(
                    onDeleteTapped: {
                        onDelete()
                        dismiss()
                    }
                )
                
            }

            // MARK: - Toolbar
            .toolbar {

                // ⬅️ Back Button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        
                        RecordingScreenHapticsController.shared.lightTap()
                        RecordingScreenSoundController.shared.playSound1()
                        
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }

                // Save / Revert
                if hasUnsavedEdits {
                    
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        
                        Button("Revert") {
                            
                            RecordingScreenHapticsController.shared.lightTap()
                            RecordingScreenSoundController.shared.playSound1()
                            
                            showRevertConfirmation = true
                        }
                        .foregroundColor(.red)

                        Button("Save") {
                            
                            RecordingScreenHapticsController.shared.successConfirmationTap()
                            RecordingScreenSoundController.shared.playSound1()
                            
                            commitEdits()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .alert("Revert Changes?", isPresented: $showRevertConfirmation) {
                Button("Revert", role: .destructive) {
                    
                    RecordingScreenHapticsController.shared.mediumTap()
                    RecordingScreenSoundController.shared.playSound1()
                    
                    revertEdits()
                }
                Button("Cancel", role: .cancel) {
                    
                    RecordingScreenHapticsController.shared.lightTap()
                    RecordingScreenSoundController.shared.playSound1()
                    
                }
            } message: {
                Text("This will discard any unsaved changes.")
            }
            .sheet(isPresented: $showContactPicker) {
                RecordingContactPickerView(
                    prospects: prospects,
                    customers: customers,
                    hasAssignedContact: recording.prospect != nil || recording.customer != nil,
                    onSelectProspect: { prospect in
                        recording.prospect = prospect
                        recording.customer = nil
                        try? modelContext.save()
                        showContactPicker = false
                    },
                    onSelectCustomer: { customer in
                        recording.prospect = nil
                        recording.customer = customer
                        try? modelContext.save()
                        showContactPicker = false
                    },
                    onUnassign: {
                        recording.prospect = nil
                        recording.customer = nil
                        try? modelContext.save()
                        showContactPicker = false
                    },
                    onCancel: {
                        showContactPicker = false
                    }
                )
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
            .onAppear {
                tempTitle = recording.title
                loadAudio()
            }
            .onDisappear {
                timer?.invalidate()
                audioPlayer?.stop()
            }
        }
    }

    // MARK: - Derived State

    private var hasUnsavedEdits: Bool {
        tempTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            != recording.title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isPlaying: Bool {
        audioPlayer?.isPlaying ?? false
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.04))
            )
    }

    // MARK: - Save / Revert

    private func commitEdits() {
        let trimmed = tempTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        recording.title = trimmed
        try? modelContext.save()
    }

    private func revertEdits() {
        tempTitle = recording.title
    }
    
    private func openLinkedContact() {
        RecordingScreenHapticsController.shared.lightTap()
        RecordingScreenSoundController.shared.playSound1()
        
        if let prospect = recording.prospect {
            selectedProspect = prospect
        } else if let customer = recording.customer {
            selectedCustomer = customer
        } else {
            showContactPicker = true
        }
    }

    // MARK: - Audio Helpers

    func loadAudio() {
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(recording.fileName)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            duration = audioPlayer?.duration ?? 1
            waveformSamples = generateFakeWaveform()
        } catch {
            print("❌ Failed to load audio:", error)
        }
    }

    func playOrPause() {
        guard let player = audioPlayer else { return }

        if player.isPlaying {
            player.pause()
            timer?.invalidate()
        } else {
            player.play()
            startTimer()
        }
    }

    func seek(to progress: CGFloat) {
        guard let player = audioPlayer else { return }
        let time = Double(progress) * player.duration
        player.currentTime = time
        currentTime = time
        if !player.isPlaying { player.play() }
        startTimer()
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                currentTime = audioPlayer?.currentTime ?? 0
            }
        }
    }

    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func generateFakeWaveform() -> [CGFloat] {
        (0..<100).map { _ in .random(in: 0.2...1.0) }
    }
}

private struct RecordingContactRow: View {
    let prospect: Prospect?
    let customer: Customer?
    let onOpen: () -> Void
    let onChange: () -> Void
    
    private var contactName: String {
        prospect?.fullName ?? customer?.fullName ?? "No contact assigned"
    }
    
    private var contactAddress: String? {
        prospect?.address ?? customer?.address
    }
    
    private var contactType: String {
        prospect != nil ? "Prospect" : customer != nil ? "Customer" : "Tap to assign this recording"
    }
    
    private var iconName: String {
        prospect != nil ? "person.crop.circle" : customer != nil ? "checkmark.seal.fill" : "person.crop.circle.badge.questionmark"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onOpen) {
                HStack(spacing: 12) {
                    Image(systemName: iconName)
                        .font(.title3)
                        .foregroundStyle(customer != nil ? .green : .blue)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(contactName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        Text(contactAddress ?? contactType)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Button(action: onChange) {
                Image(systemName: prospect == nil && customer == nil ? "plus.circle.fill" : "pencil.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(prospect == nil && customer == nil ? "Assign contact" : "Change contact")
        }
    }
}

private struct RecordingContactPickerView: View {
    let prospects: [Prospect]
    let customers: [Customer]
    let hasAssignedContact: Bool
    let onSelectProspect: (Prospect) -> Void
    let onSelectCustomer: (Customer) -> Void
    let onUnassign: () -> Void
    let onCancel: () -> Void
    
    @State private var searchText = ""
    
    private var filteredProspects: [Prospect] {
        filteredContacts(prospects)
    }
    
    private var filteredCustomers: [Customer] {
        filteredContacts(customers)
    }
    
    var body: some View {
        NavigationStack {
            List {
                if prospects.isEmpty && customers.isEmpty {
                    ContentUnavailableView(
                        "No Contacts",
                        systemImage: "person.crop.circle.badge.questionmark",
                        description: Text("Create a prospect or customer before assigning this recording.")
                    )
                } else if filteredProspects.isEmpty && filteredCustomers.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
                
                if !filteredCustomers.isEmpty {
                    Section("Customers") {
                        ForEach(filteredCustomers.sorted { $0.fullName < $1.fullName }) { customer in
                            Button {
                                onSelectCustomer(customer)
                            } label: {
                                ContactPickerRow(
                                    name: customer.fullName,
                                    address: customer.address,
                                    icon: "checkmark.seal.fill",
                                    color: .green
                                )
                            }
                        }
                    }
                }
                
                if !filteredProspects.isEmpty {
                    Section("Prospects") {
                        ForEach(filteredProspects.sorted { $0.fullName < $1.fullName }) { prospect in
                            Button {
                                onSelectProspect(prospect)
                            } label: {
                                ContactPickerRow(
                                    name: prospect.fullName,
                                    address: prospect.address,
                                    icon: "person.crop.circle",
                                    color: .blue
                                )
                            }
                        }
                    }
                }
                
                if hasAssignedContact {
                    Section {
                        Button(role: .destructive, action: onUnassign) {
                            Label("Remove Contact Link", systemImage: "link.badge.minus")
                        }
                    }
                }
            }
            .navigationTitle("Recording Contact")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search contacts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
    
    private func filteredContacts<T: ContactProtocol>(_ contacts: [T]) -> [T] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return contacts }
        
        return contacts.filter {
            $0.fullName.localizedCaseInsensitiveContains(query) ||
            $0.address.localizedCaseInsensitiveContains(query)
        }
    }
}

private struct ContactPickerRow: View {
    let name: String
    let address: String
    let icon: String
    let color: Color
    
    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(color)
        }
    }
}
