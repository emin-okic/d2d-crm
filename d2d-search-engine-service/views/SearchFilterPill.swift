//
//  SearchFilterPill.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/31/25.
//

import SwiftUI

struct SearchFilterPill: View {
    @Binding var searchText: String
    @Binding var selectedField: ContactSearchField
    @FocusState<Bool>.Binding var isFocused: Bool
    var onSubmit: () -> Void
    var onClear: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(ContactSearchField.allCases) { field in
                    Button {
                        selectedField = field
                    } label: {
                        Label(field.label, systemImage: field.systemImage)
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: selectedField.systemImage)
                        .font(.caption.weight(.semibold))
                    Text(selectedField.label)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1), in: Capsule())
            }
            .menuOrder(.fixed)

            TextField("Filter by \(selectedField.label.lowercased())", text: $searchText)
                .focused($isFocused)
                .font(.subheadline)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit {
                    onSubmit()
                }

            if !searchText.isEmpty {
                Button {
                    onClear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Clear Search")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}

struct ContactFilterBanner: View {
    let filter: ContactSearchFilter
    let resultCount: Int
    let listName: String
    var onClear: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: filter.field.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Active Filter")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("\(listName): \(resultCount) match\(resultCount == 1 ? "" : "es") for \"\(filter.displayText)\"")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 0)

            Button(action: onClear) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Clear Contact Filter")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: 420)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}
