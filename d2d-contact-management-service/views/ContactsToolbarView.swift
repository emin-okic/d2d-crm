//
//  ContactsToolbarView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/13/25.
//

import SwiftUI

struct ContactsToolbarView: View {

    var onAddTapped: () -> Void
    @Binding var isDeleting: Bool
    var selectedCount: Int
    var onDeleteConfirmed: () -> Void
    let isExportUnlocked: Bool
    var onExportTapped: () -> Void

    var body: some View {
        ContactScreenToolbarLiquidGlass {
            ContactToolbarButtons(
                onAddTapped: onAddTapped,
                isDeleting: $isDeleting,
                selectedCount: selectedCount,
                onDeleteConfirmed: onDeleteConfirmed,
                isExportUnlocked: isExportUnlocked,
                onExportTapped: onExportTapped
            )
        }
        .accessibilityElement(children: .contain)
    }
}

private struct ContactToolbarButtons: View {
    var onAddTapped: () -> Void
    @Binding var isDeleting: Bool
    var selectedCount: Int
    var onDeleteConfirmed: () -> Void
    let isExportUnlocked: Bool
    var onExportTapped: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            CreateContactButton(action: onAddTapped)

            DeleteContactButton(
                isDeleting: $isDeleting,
                selectedCount: selectedCount,
                onDeleteConfirmed: onDeleteConfirmed
            )

            ExportCSVButton(isUnlocked: isExportUnlocked, onTap: onExportTapped)
        }
    }
}

struct ContactListCommandRow: View {
    @Binding var selectedList: String
    @Binding var isDeleting: Bool
    let selectedDeleteCount: Int
    var onAddTapped: () -> Void
    var onDeleteConfirmed: () -> Void
    let isExportUnlocked: Bool
    var onExportTapped: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            commandShelf {
                HStack(alignment: .center, spacing: 12) {
                    ToggleChipsView(selectedList: $selectedList, horizontalPadding: 0)

                    Divider()
                        .frame(height: 34)

                    toolbarButtons
                }
            }

            commandShelf {
                VStack(spacing: 10) {
                    ToggleChipsView(selectedList: $selectedList, horizontalPadding: 0)

                    Divider()

                    toolbarButtons
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var toolbarButtons: some View {
        ContactToolbarButtons(
            onAddTapped: onAddTapped,
            isDeleting: $isDeleting,
            selectedCount: selectedDeleteCount,
            onDeleteConfirmed: onDeleteConfirmed,
            isExportUnlocked: isExportUnlocked,
            onExportTapped: onExportTapped
        )
    }

    private func commandShelf<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ContactScreenToolbarLiquidGlass {
            content()
        }
    }
}
