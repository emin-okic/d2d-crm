//
//  KnockStreakSheetView.swift
//  d2d-studio
//
//  Created by Codex on 8/3/26.
//

import SwiftUI
import SwiftData

struct KnockStreakSheetView: View {
    @Query private var allKnocks: [Knock]

    private var summary: KnockStreakSummary {
        KnockStreakCalculator.summary(from: allKnocks)
    }

    private var recentDays: [KnockStreakDay] {
        KnockStreakCalculator.recentDays(from: summary)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                statsGrid
                recentActivity
                reminderPanel
            }
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.16), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: min(Double(summary.displayedCurrentStreak) / 7, 1))
                    .stroke(
                        AngularGradient(colors: [.orange, .yellow, .orange], center: .center),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(summary.displayedCurrentStreak)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())

                    Text(summary.displayedCurrentStreak == 1 ? "day" : "days")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 104, height: 104)

            VStack(alignment: .leading, spacing: 8) {
                Text("Knock Streak")
                    .font(.title2.weight(.bold))

                Text(headerMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Label(summary.statusText, systemImage: summary.knockedToday ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(summary.knockedToday ? .green : .orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background((summary.knockedToday ? Color.green : Color.orange).opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private var statsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            statTile("Current", "\(summary.displayedCurrentStreak)", "flame.fill", .orange)
            statTile("Best", "\(summary.longestStreak)", "trophy.fill", .purple)
            statTile("Active", "\(summary.totalActiveDays)", "calendar", .blue)
        }
    }

    private func statTile(_ title: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Last 14 days")
                    .font(.headline)

                Spacer()

                Label("knock days", systemImage: "door.left.hand.open")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 5) {
                ForEach(recentDays) { day in
                    VStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(dayColor(for: day.count))
                            .frame(height: 30)
                            .overlay {
                                if day.count > 0 {
                                    Text("\(day.count)")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }

                        Text(day.date.formatted(.dateTime.weekday(.narrow)))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("\(day.date.formatted(.dateTime.month().day())), \(day.count) knocks")
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var reminderPanel: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.orange)
                .frame(width: 36, height: 36)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Streak reminders")
                    .font(.headline)

                Text(reminderMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var headerMessage: String {
        if summary.currentStreak == 0 {
            return "Knock today to start a streak. Consecutive calendar days keep it alive."
        }

        if summary.knockedToday {
            return "You have knocked today, so this streak is protected until tomorrow."
        }

        return "Knock today to keep this streak from resetting."
    }

    private var reminderMessage: String {
        if summary.currentStreak > 2 {
            return "When a 3+ day streak is at risk, the app schedules a same-day local reminder to get back to knocking."
        }

        return "Reach a 3 day streak and reminders will help protect it when a day is almost missed."
    }

    private func dayColor(for count: Int) -> Color {
        guard count > 0 else { return Color.secondary.opacity(0.12) }
        return Color.orange.opacity(min(0.34 + (Double(count) * 0.12), 1))
    }
}
