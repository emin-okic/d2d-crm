//
//  AppStoreReviewHelper.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/8/25.
//

import StoreKit
import UIKit

@MainActor
enum AppStoreReviewHelper {

    /// Call this from a visible UI moment. If Apple throttles the prompt,
    /// we fall back to opening the App Store review page.
    static func requestReviewOrOpenStore(appId: String) {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else {
            openWriteReviewPage(appId: appId)
            return
        }

        if #available(iOS 18.0, *) {
            AppStore.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    /// Opens the “Write a Review” page directly in the App Store app.
    static func openWriteReviewPage(appId: String) {
        let urlStr = "itms-apps://itunes.apple.com/app/id\(appId)?action=write-review"
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url)
        }
    }
}
