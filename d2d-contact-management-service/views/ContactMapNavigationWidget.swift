//
//  ContactMapNavigationWidget.swift
//  d2d-studio
//
//  Created by Codex on 8/24/26.
//

import SwiftUI

enum ContactMapNavigationWidgetLayout {
    case row
    case tile
}

struct ContactMapNavigationWidget: View {
    let title: String
    let subtitle: String
    let isDisabled: Bool
    var layout: ContactMapNavigationWidgetLayout = .row
    let action: () -> Void

    var body: some View {
        ContactDetailsUtilityWidget(
            icon: "map.fill",
            title: title,
            subtitle: subtitle,
            color: .blue,
            isDisabled: isDisabled,
            layout: layout,
            action: action
        )
    }
}

struct ContactDetailsUtilityWidget: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var isDisabled: Bool = false
    var layout: ContactMapNavigationWidgetLayout = .row
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            switch layout {
            case .row:
                rowContent
            case .tile:
                tileContent
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.58 : 1)
    }

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(isDisabled ? 0.08 : 0.14))
                .frame(width: 38, height: 38)

            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isDisabled ? .secondary : color)
        }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            iconBadge

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var tileContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                iconBadge
                    .scaleEffect(0.9)

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 0.5)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    Form {
        Section {
            ContactMapNavigationWidget(
                title: "Show on Map",
                subtitle: "Open marker and knocking popup",
                isDisabled: false,
                action: {}
            )
        }

        Section {
            HStack(spacing: 10) {
                ContactDetailsUtilityWidget(
                    icon: "person.text.rectangle.fill",
                    title: "Demographics",
                    subtitle: "Add profile and company info",
                    color: .indigo,
                    layout: .tile,
                    action: {}
                )

                ContactMapNavigationWidget(
                    title: "Show on Map",
                    subtitle: "Open marker and knocking popup",
                    isDisabled: false,
                    layout: .tile,
                    action: {}
                )
            }
        }
    }
}
