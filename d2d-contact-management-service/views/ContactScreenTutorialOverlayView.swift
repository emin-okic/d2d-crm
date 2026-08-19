//
//  ContactScreenTutorialOverlayView.swift
//  d2d-studio
//
//  Created by Codex on 8/19/26.
//

import SwiftUI

enum ContactScreenTutorialStep: Int, CaseIterable {
    case search
    case lists
    case contacts
    case add
    case delete
    case export

    var title: String {
        switch self {
        case .search: "Find the right contact fast"
        case .lists: "Switch between lists"
        case .contacts: "Open contact details"
        case .add: "Add contacts your way"
        case .delete: "Clean up contacts"
        case .export: "Export your contacts"
        }
    }

    var message: String {
        switch self {
        case .search:
            "Use the search pill to filter by name, address, phone, email, or any field."
        case .lists:
            "Use these chips to move between Prospects and Customers without leaving the screen."
        case .contacts:
            "Tap a row to open details, notes, appointments, knocking history, and actions."
        case .add:
            "Tap plus to import from Contacts, add manually, or scan a business card."
        case .delete:
            "Use delete mode when you need to select and remove contacts in batches."
        case .export:
            "Export the current contact list to share or back up your data."
        }
    }

    var systemImage: String {
        switch self {
        case .search: "magnifyingglass"
        case .lists: "person.2.badge.gearshape.fill"
        case .contacts: "list.bullet.rectangle.portrait.fill"
        case .add: "plus.circle.fill"
        case .delete: "trash.fill"
        case .export: "square.and.arrow.up.fill"
        }
    }

    var progressText: String {
        "Step \(rawValue + 1) of \(Self.allCases.count)"
    }

    var nextTitle: String {
        self == Self.allCases.last ? "Finish" : "Next"
    }
}

struct ContactScreenTutorialOverlayView: View {
    let step: ContactScreenTutorialStep
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void

    @State private var pulse = false
    @State private var iconBounce = false

    private var canGoBack: Bool {
        step.rawValue > 0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.48)
                    .ignoresSafeArea()
                    .allowsHitTesting(step != .contacts)

                targetHighlight(in: geometry)

                tutorialCard
                    .frame(maxWidth: 350)
                    .position(cardPosition(in: geometry))
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            }
            .onAppear(perform: startAnimations)
            .onChange(of: step) { _, _ in
                startAnimations()
            }
        }
    }

    private var tutorialCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: step.systemImage)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color(red: 0.02, green: 0.60, blue: 1.0)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(step.progressText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(red: 0.48, green: 0.86, blue: 1.0))
                        .textCase(.uppercase)

                    Text(step.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Text(step.message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.78))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            progressDots

            HStack(spacing: 10) {
                Button("Skip", action: onSkip)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.70))

                Spacer(minLength: 0)

                Button(action: onPrevious) {
                    Label("Prev", systemImage: "chevron.left")
                        .labelStyle(.titleAndIcon)
                }
                .disabled(!canGoBack)
                .opacity(canGoBack ? 1 : 0.38)

                Button(action: onNext) {
                    Label(step.nextTitle, systemImage: step == .export ? "checkmark" : "chevron.right")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
            }
            .font(.subheadline.weight(.bold))
            .buttonStyle(.bordered)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.04, green: 0.10, blue: 0.18).opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.34), radius: 22, x: 0, y: 12)
        .padding(.horizontal, 18)
    }

    private var progressDots: some View {
        HStack(spacing: 7) {
            ForEach(ContactScreenTutorialStep.allCases, id: \.rawValue) { item in
                Capsule()
                    .fill(item.rawValue <= step.rawValue ? Color(red: 0.02, green: 0.60, blue: 1.0) : Color.white.opacity(0.22))
                    .frame(width: item == step ? 28 : 9, height: 6)
                    .animation(.spring(response: 0.28, dampingFraction: 0.84), value: step)
            }
        }
    }

    private func targetHighlight(in geometry: GeometryProxy) -> some View {
        let target = targetFrame(in: geometry)

        return ZStack {
            RoundedRectangle(cornerRadius: target.cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1.5)
                .frame(width: target.size.width + 28, height: target.size.height + 28)
                .scaleEffect(pulse ? 1.10 : 0.94)
                .opacity(pulse ? 0.06 : 0.70)

            RoundedRectangle(cornerRadius: target.cornerRadius, style: .continuous)
                .stroke(Color(red: 0.02, green: 0.60, blue: 1.0), lineWidth: 3)
                .frame(width: target.size.width, height: target.size.height)
                .scaleEffect(pulse ? 1.03 : 0.98)
                .opacity(pulse ? 0.58 : 1.0)

            Image(systemName: step.systemImage)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: Color.black.opacity(0.34), radius: 8, x: 0, y: 4)
                .offset(y: iconBounce ? -5 : 4)
        }
        .position(target.center)
        .allowsHitTesting(false)
    }

    private func targetFrame(in geometry: GeometryProxy) -> TutorialTargetFrame {
        switch step {
        case .search:
            return TutorialTargetFrame(
                center: CGPoint(x: geometry.size.width / 2, y: 28),
                size: CGSize(width: min(geometry.size.width - 40, 330), height: 52),
                cornerRadius: 22
            )
        case .lists:
            return TutorialTargetFrame(
                center: CGPoint(x: geometry.size.width / 2, y: 222),
                size: CGSize(width: min(geometry.size.width - 56, 300), height: 46),
                cornerRadius: 22
            )
        case .contacts:
            return TutorialTargetFrame(
                center: CGPoint(x: geometry.size.width / 2, y: min(geometry.size.height * 0.48, 390)),
                size: CGSize(width: min(geometry.size.width - 40, 350), height: 150),
                cornerRadius: 18
            )
        case .add:
            return TutorialTargetFrame(
                center: CGPoint(x: 57, y: geometry.size.height - 108),
                size: CGSize(width: 72, height: 72),
                cornerRadius: 36
            )
        case .delete:
            return TutorialTargetFrame(
                center: CGPoint(x: 57, y: geometry.size.height - 46),
                size: CGSize(width: 72, height: 72),
                cornerRadius: 36
            )
        case .export:
            return TutorialTargetFrame(
                center: CGPoint(x: geometry.size.width - 45, y: geometry.size.height - 55),
                size: CGSize(width: 72, height: 72),
                cornerRadius: 36
            )
        }
    }

    private func cardPosition(in geometry: GeometryProxy) -> CGPoint {
        switch step {
        case .search:
            CGPoint(x: geometry.size.width / 2, y: min(geometry.size.height - 170, 360))
        case .lists:
            CGPoint(x: geometry.size.width / 2, y: min(geometry.size.height - 150, 430))
        case .contacts:
            CGPoint(x: geometry.size.width / 2, y: min(geometry.size.height - 160, 180))
        case .add, .delete, .export:
            CGPoint(x: geometry.size.width / 2, y: min(geometry.size.height * 0.34, 300))
        }
    }

    private func startAnimations() {
        pulse = false
        iconBounce = false

        withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) {
            pulse = true
        }

        withAnimation(.easeInOut(duration: 0.74).repeatForever(autoreverses: true)) {
            iconBounce = true
        }
    }
}

private struct TutorialTargetFrame {
    let center: CGPoint
    let size: CGSize
    let cornerRadius: CGFloat
}
