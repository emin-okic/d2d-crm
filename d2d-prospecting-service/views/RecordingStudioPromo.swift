//
//  RecordingStudioPromo.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/8/25.
//

import SwiftUI

struct RecordingStudioPromo: View {
    var onUnlock: () -> Void
    @Environment(\.scenePhase) private var scenePhase

    @State private var openedReviewAt: Date?
    @State private var pendingUnlockFromReview = false

    private let appId = "6748091911" // <-- your real App Store ID

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // --- ONE-PAGE FEATURE PITCH ---
                VStack(spacing: 12) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 72))
                    Text("Unlock Your Recording Studio")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text("Practice, review, and auto-score your pitch to convert faster.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 32)

                Spacer()

                // --- SINGLE REVIEW CTA ---
                Button {
                    openedReviewAt = Date()
                    pendingUnlockFromReview = true
                    AppStoreReviewHelper.requestReviewOrOpenStore(appId: appId)

                    // Fallback unlock if Apple shows in-app prompt (no scene change)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        if pendingUnlockFromReview {
                            pendingUnlockFromReview = false
                            onUnlock()
                        }
                    }
                } label: {
                    cta("Rate on the App Store", filled: true)
                }

                Spacer()
            }
            .navigationTitle("Recording Studio")
            .navigationBarTitleDisplayMode(.inline)
        }
        // Unlock when app returns from the App Store (submit or cancel)
        .onChange(of: scenePhase) { phase in
            guard phase == .active, pendingUnlockFromReview else { return }
            if let t = openedReviewAt, Date().timeIntervalSince(t) > 0.8 {
                pendingUnlockFromReview = false
                onUnlock()
            }
        }
    }

    private func cta(_ title: String, filled: Bool, color: Color = .blue) -> some View {
        Text(title)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(filled ? color : Color.gray.opacity(0.2))
            .foregroundColor(filled ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
    }
}
