//
//  SearchHandler.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/4/25.
//

import Foundation
import SwiftUI

final class SearchHandler {
    static func submitManualSearch(
        searchText: String,
        pendingAddress: inout String?,
        showOutcomePrompt: inout Bool,
        clearSearchText: @escaping () -> Void
    ) {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        pendingAddress = trimmed
        showOutcomePrompt = true

        clearSearchText()
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
