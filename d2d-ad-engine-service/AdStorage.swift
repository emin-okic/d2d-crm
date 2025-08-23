//
//  AdStorage.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/23/25.
//


import Foundation

final class AdStorage {
    static let shared = AdStorage()
    private init() {}

    private let impressionsKey = "d2d_ad_impressions_v1"

    struct State: Codable {
        var impressions: [AdImpression] = []
    }

    private var state: State = {
        if let data = UserDefaults.standard.data(forKey: "d2d_ad_impressions_v1"),
           let decoded = try? JSONDecoder().decode(State.self, from: data) {
            return decoded
        }
        return State()
    }()

    func recordImpression(_ ad: Ad, at date: Date = Date()) {
        state.impressions.append(.init(adId: ad.id, timestamp: date))
        persist()
    }

    func recordDismiss(_ ad: Ad) { /* hook for analytics later */ }
    func recordClick(_ ad: Ad)   { /* hook for analytics later */ }

    /// Returns impressions for this ad within the last `window` seconds.
    func recentImpressions(for ad: Ad, within window: TimeInterval) -> Int {
        let cutoff = Date().addingTimeInterval(-window)
        return state.impressions.filter { $0.adId == ad.id && $0.timestamp >= cutoff }.count
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: impressionsKey)
        }
    }
}
