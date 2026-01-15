//
//  RecordingStudioWalkthrough.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/8/25.
//

import SwiftUI

struct RecordingStudioWalkthrough: View {
    var onDone: () -> Void

    // If you have a brand color for your search button, swap .blue for that.
    private let brandBlue = Color.blue
    private let cardBG = Color(.systemBackground)
    private let pageBG = LinearGradient(
        colors: [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)],
        startPoint: .top, endPoint: .bottom
    )

    var body: some View {
        NavigationView {
            ZStack {
                pageBG.ignoresSafeArea()

                // Centered card – single screen, no scroll
                VStack {
                    Spacer(minLength: 0)

                    VStack(spacing: 18) {
                        // Top “brand bar” accent (common in enterprise product pages)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(brandBlue.opacity(0.15))
                            .frame(height: 8)
                            .frame(maxWidth: 120)

                        // Icon in soft circle
                        ZStack {
                            Circle()
                                .fill(brandBlue.opacity(0.12))
                                .frame(width: 88, height: 88)
                            Image(systemName: "mic.and.signal.meter.fill")
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundColor(brandBlue)
                        }

                        // Headline
                        Text("Start a Session")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)

                        // Subheadline
                        Text("Auto Transcribe & Score")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        // Descriptions – keep your exact copy, formatted like a product features list
                        VStack(alignment: .leading, spacing: 10) {
                            featureRow("Pick an objection, tap record, and practice your pitch.")
                            featureRow("We compare your words to best-in-class responses.")
                            featureRow("Play back calls, rename, and track your progress.")
                        }
                        .padding(.top, 4)
                        .frame(maxWidth: 520, alignment: .center)

                        // CTA with haptics + sound
                        Button {
                            // ✅ Haptic + Sound feedback
                            FollowUpScreenHapticsController.shared.lightTap()
                            FollowUpScreenSoundController.shared.playSound1()
                            
                            // Original action
                            onDone()
                        } label: {
                            Text("Got it")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(brandBlue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .shadow(color: brandBlue.opacity(0.25), radius: 8, y: 4)
                        }
                        .padding(.top, 6)
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 22)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(cardBG)
                            .shadow(color: Color.black.opacity(0.08), radius: 16, y: 8)
                    )
                    .frame(maxWidth: 620)
                    .padding(.horizontal, 16)

                    Spacer(minLength: 0)
                }
            }
            .navigationTitle("Quick Tour")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func featureRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(brandBlue)
                .padding(.top, 2)
            Text(text)
                .font(.callout)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
