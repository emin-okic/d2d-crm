//
//  AppReviewController.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/11/25.
//

import Foundation

extension UserDefaults {
    private enum Keys {
        static let hasLeftReview = "hasLeftReview"
    }

    var hasLeftReview: Bool {
        get { bool(forKey: Keys.hasLeftReview) }
        set { set(newValue, forKey: Keys.hasLeftReview) }
    }
}
