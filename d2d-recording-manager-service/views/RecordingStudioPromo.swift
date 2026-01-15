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
            ZStack {
                // Subtle gradient backdrop (Salesforce/HubSpot-style airy hero)
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.secondarySystemBackground)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Hero Card
                    VStack(spacing: 16) {
                        // Brand-ish icon in a soft “badge”
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 88, height: 88)
                                .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
                                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)

                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundStyle(.blue)
                        }

                        // Headline
                        Text("Unlock Your Recording Studio")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .multilineTextAlignment(.center)

                        // Subhead
                        Text("Practice, review, and auto-score your pitch to convert faster.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: 560)
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 20)
                    .background(
                        // Elevated, card-like container
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.08), radius: 18, y: 10)
                    )
                    .overlay(
                        // Hairline top/bottom dividers for that enterprise “crispness”
                        VStack {
                            Divider().opacity(0.05)
                            Spacer()
                            Divider().opacity(0.05)
                        }
                    )
                    .padding(.horizontal)

                    Spacer(minLength: 0)

                    // Single CTA — primary, high-contrast, wide
                    Button {
                        // ✅ Haptic + sound feedback
                        FollowUpScreenHapticsController.shared.lightTap()
                        FollowUpScreenSoundController.shared.playSound1()
                        
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
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                            Text("Rate on the App Store")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                                .shadow(color: .blue.opacity(0.25), radius: 12, y: 6)
                        )
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .accessibilityIdentifier("rateOnAppStoreButton")
                    }

                    // Micro reassurance text (kept subtle, doesn’t add new content)
                    Text("You’ll unlock as soon as you return to the app.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, -4)

                    Spacer(minLength: 16)
                }
                .padding(.top, 28)
                .padding(.bottom, 12)
                .navigationTitle("Recording Studio")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        // Unlock when app returns from the App Store (submit or cancel)
        .onChange(of: scenePhase) { phase in
            guard phase == .active, pendingUnlockFromReview else { return }
            if let t = openedReviewAt, Date().timeIntervalSince(t) > 3.0 {
                pendingUnlockFromReview = false
                onUnlock()
            }
        }
    }
}
