//
//  InitialContactTutorialOverlayView.swift
//  d2d-studio
//
//  Created by Codex on 8/19/26.
//

import SwiftUI

enum InitialContactTutorialStep {
    case tapAdd
    case chooseMethod
    case completed
}

struct InitialContactTutorialOverlayView: View {
    let step: InitialContactTutorialStep

    @State private var pulse = false
    @State private var tapBounce = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if step == .tapAdd {
                    Color.black.opacity(0.50)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    addButtonTarget(in: geometry)

                    tutorialCard(
                        title: "Add your first contact",
                        message: "Tap the plus button to choose how you want to add a prospect.",
                        systemImage: "person.crop.circle.badge.plus",
                        progressText: "Step 1 of 2"
                    )
                    .frame(maxWidth: 340)
                    .position(x: geometry.size.width / 2, y: min(geometry.size.height * 0.26, 230))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if step == .completed {
                    Color.black.opacity(0.34)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    completionCard
                        .frame(maxWidth: 330)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.42)
                        .transition(.scale(scale: 0.86).combined(with: .opacity))
                }
            }
            .onAppear(perform: startAnimations)
            .onChange(of: step) { _, _ in
                startAnimations()
            }
        }
    }

    private func addButtonTarget(in geometry: GeometryProxy) -> some View {
        let target = CGPoint(x: 57, y: geometry.size.height - 96)

        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.28), lineWidth: 1.5)
                .frame(width: 112, height: 112)
                .scaleEffect(pulse ? 1.22 : 0.84)
                .opacity(pulse ? 0.06 : 0.68)

            Circle()
                .stroke(Color(red: 0.02, green: 0.60, blue: 1.0), lineWidth: 3)
                .frame(width: 76, height: 76)
                .scaleEffect(pulse ? 1.08 : 0.92)
                .opacity(pulse ? 0.45 : 1.0)

            Image(systemName: "hand.tap.fill")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
                .offset(y: tapBounce ? -8 : 5)
        }
        .position(target)
        .allowsHitTesting(false)
    }

    private func tutorialCard(title: String, message: String, systemImage: String, progressText: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color(red: 0.02, green: 0.60, blue: 1.0)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(progressText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(red: 0.48, green: 0.86, blue: 1.0))
                        .textCase(.uppercase)

                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }

                Spacer(minLength: 0)
            }

            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.76))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Capsule()
                    .fill(Color(red: 0.02, green: 0.60, blue: 1.0))
                    .frame(width: 34, height: 5)

                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 18, height: 5)
            }
            .padding(.top, 2)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.04, green: 0.10, blue: 0.18).opacity(0.90))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.32), radius: 22, x: 0, y: 12)
        .padding(.horizontal, 22)
        .allowsHitTesting(false)
    }

    private var completionCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.18))
                    .frame(width: 74, height: 74)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Color.green)
            }

            Text("First contact added")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            Text("Your contact is ready for notes, follow-ups, appointments, and knocking history.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.74))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(red: 0.04, green: 0.12, blue: 0.18).opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.36), radius: 24, x: 0, y: 14)
        .padding(.horizontal, 24)
        .allowsHitTesting(false)
    }

    private func startAnimations() {
        pulse = false
        tapBounce = false

        withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
            pulse = true
        }

        withAnimation(.easeInOut(duration: 0.72).repeatForever(autoreverses: true)) {
            tapBounce = true
        }
    }
}

struct InitialContactAddOptionsTutorialBanner: View {
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color(red: 0.02, green: 0.60, blue: 1.0).opacity(pulse ? 0.12 : 0.45), lineWidth: 5)
                        .frame(width: 46, height: 46)
                        .scaleEffect(pulse ? 1.18 : 0.88)

                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color(red: 0.02, green: 0.60, blue: 1.0))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Step 2 of 2")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(red: 0.02, green: 0.60, blue: 1.0))
                        .textCase(.uppercase)

                    Text("Pick the fastest path for this contact.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 6) {
                optionLine(icon: "person.crop.circle.badge.plus", text: "Import from Contacts for saved phone contacts.")
                optionLine(icon: "square.and.pencil", text: "Add Manually when you want full control.")
                optionLine(icon: "camera.viewfinder", text: "Scan Business Card with the camera.")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.02, green: 0.60, blue: 1.0).opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(red: 0.02, green: 0.60, blue: 1.0).opacity(0.32), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private func optionLine(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(red: 0.02, green: 0.60, blue: 1.0))
                .frame(width: 18)

            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
