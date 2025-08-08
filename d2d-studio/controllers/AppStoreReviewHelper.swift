//
//  AppStoreReviewHelper.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/8/25.
//


import StoreKit
import UIKit

enum AppStoreReviewHelper {
    /// Call this from a visible UI moment. If SKStoreReviewController
    /// decides not to show (quota), we deep-link to the review page.
    static func requestReviewOrOpenStore(appId: String) {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        {
            // This may silently no-op if Apple throttles prompts.
            SKStoreReviewController.requestReview(in: scene)
        } else {
            // No active scene? Fall back to deep link.
            openWriteReviewPage(appId: appId)
        }
    }

    /// Opens the “Write a Review” page directly in the App Store app.
    static func openWriteReviewPage(appId: String) {
        let urlStr = "itms-apps://itunes.apple.com/app/id\(appId)?action=write-review"
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
