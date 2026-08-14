//
//  WelcomeOnboardingView.swift
//  d2d-studio
//
//  Created by Codex on 8/14/26.
//

import SwiftUI

struct WelcomeOnboardingView: View {
    let onContinue: () -> Void

    private let features = [
        "Live territory map",
        "Prospect and customer CRM",
        "Follow-up pipeline",
        "Appointment reminders",
        "Local-first records"
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                background

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        heroPreview
                            .frame(maxWidth: .infinity)
                            .padding(.top, 62)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Welcome to\nD2D CRM")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineSpacing(2)

                            Text("Map every door, track every conversation, and keep follow-ups moving from your first knock.")
                                .font(.system(size: 22, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.62))
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 28)

                        featureCard
                            .padding(.horizontal, 24)

                        Spacer(minLength: geometry.safeAreaInsets.bottom + 124)
                    }
                }

            }
            .overlay(alignment: .bottom) {
                bottomAction
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom - 8, 0))
            }
            .ignoresSafeArea()
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.09, blue: 0.17),
                Color(red: 0.09, green: 0.19, blue: 0.31),
                Color(red: 0.16, green: 0.35, blue: 0.38)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var heroPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 46, style: .continuous)
                .fill(Color.black)
                .frame(width: 222, height: 410)
                .shadow(color: Color.black.opacity(0.42), radius: 20, x: 0, y: 14)

            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.07, green: 0.18, blue: 0.31),
                            Color(red: 0.12, green: 0.31, blue: 0.42),
                            Color(red: 0.03, green: 0.35, blue: 0.48)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 198, height: 386)
                .overlay(phoneContent.clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous)))
                .overlay(alignment: .top) {
                    Capsule(style: .continuous)
                        .fill(Color.black)
                        .frame(width: 82, height: 22)
                        .padding(.top, 9)
                }
        }
    }

    private var phoneContent: some View {
        VStack(spacing: 11) {
            HStack(spacing: 8) {
                Image(systemName: "map.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(red: 0.34, green: 0.83, blue: 1.0))

                Text("Oak Ridge Route")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.84))
                    .lineLimit(1)

                Spacer()

                Image(systemName: "location.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
            }
            .padding(.horizontal, 14)
            .padding(.top, 45)

            HStack(spacing: 8) {
                statPill("42", "Doors")
                statPill("9", "Hot")
                statPill("3", "Appts")
            }
            .padding(.horizontal, 14)

            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white.opacity(0.07))

                MapLineShape()
                    .stroke(Color.white.opacity(0.55), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .padding(34)

                MapLineShape()
                    .trim(from: 0.38, to: 1.0)
                    .stroke(Color(red: 0.0, green: 0.58, blue: 0.93), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .padding(34)

                mapPin(x: -54, y: -34, color: .green)
                mapPin(x: 38, y: -54, color: .orange)
                mapPin(x: 56, y: 40, color: Color(red: 0.0, green: 0.58, blue: 0.93))
                mapPin(x: -18, y: 60, color: .red)
            }
            .frame(height: 166)
            .padding(.horizontal, 14)

            VStack(spacing: 10) {
                miniContactRow(name: "Maria K.", status: "Follow up today", icon: "calendar.badge.clock")
                miniContactRow(name: "Cedar Ave", status: "New prospect", icon: "person.crop.circle.badge.plus")
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
    }

    private var featureCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("What's Included")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Text("Ready")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.64))
            }
            .padding(.bottom, 14)

            Divider()
                .overlay(Color.white.opacity(0.10))

            ForEach(features, id: \.self) { feature in
                HStack(spacing: 16) {
                    Text(feature)
                        .font(.system(size: 23, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Spacer()

                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color(red: 0.25, green: 0.92, blue: 0.55))
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color(red: 0.05, green: 0.42, blue: 0.25)))
                }
                .padding(.vertical, 15)

                if feature != features.last {
                    Divider()
                        .overlay(Color.white.opacity(0.10))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 26)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(red: 0.04, green: 0.14, blue: 0.23).opacity(0.68))
        )
    }

    private var bottomAction: some View {
        VStack(spacing: 0) {
            Button(action: onContinue) {
                Text("Get Started")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color(red: 0.02, green: 0.60, blue: 1.0))
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(Color(red: 0.20, green: 0.88, blue: 1.0), lineWidth: 1.5)
                            )
                    )
                    .shadow(color: Color(red: 0.0, green: 0.51, blue: 0.95).opacity(0.42), radius: 24, x: 0, y: 12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .padding(.top, 22)
            .padding(.bottom, 18)
        }
        .background(
            ZStack {
                Color(red: 0.11, green: 0.27, blue: 0.32)
                LinearGradient(
                    colors: [
                        Color(red: 0.11, green: 0.27, blue: 0.32).opacity(0.18),
                        Color(red: 0.11, green: 0.27, blue: 0.32)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        )
    }

    private func statPill(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color.white.opacity(0.09))
        )
    }

    private func mapPin(x: CGFloat, y: CGFloat, color: Color) -> some View {
        Image(systemName: "mappin.circle.fill")
            .font(.system(size: 24, weight: .bold))
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, color)
            .shadow(color: Color.black.opacity(0.28), radius: 4, x: 0, y: 2)
            .offset(x: x, y: y)
    }

    private func miniContactRow(name: String, status: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(red: 0.34, green: 0.83, blue: 1.0))
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.white.opacity(0.10)))

            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(status)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.02, green: 0.10, blue: 0.17).opacity(0.54))
        )
    }
}

private struct MapLineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY * 0.72))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.midY * 0.78),
            control1: CGPoint(x: rect.minX + 28, y: rect.maxY * 0.58),
            control2: CGPoint(x: rect.midX - 34, y: rect.minY + 18)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY * 0.34),
            control1: CGPoint(x: rect.midX + 28, y: rect.midY + 8),
            control2: CGPoint(x: rect.maxX - 42, y: rect.maxY * 0.82)
        )
        return path
    }
}

#Preview {
    WelcomeOnboardingView(onContinue: {})
}
