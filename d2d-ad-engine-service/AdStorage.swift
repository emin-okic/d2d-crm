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
    private let lastIndexKey   = "d2d_ad_last_startup_index_v1"

    struct State: Codable { var impressions: [AdImpression] = [] }
    private var state: State = {
        if let data = UserDefaults.standard.data(forKey: "d2d_ad_impressions_v1"),
           let decoded = try? JSONDecoder().decode(State.self, from: data) { return decoded }
        return State()
    }()

    // MARK: - Startup picker (round-robin)
    func nextStartupAd(from inventory: [Ad]) -> Ad? {
        guard !inventory.isEmpty else { return nil }
        let last = UserDefaults.standard.integer(forKey: lastIndexKey) // default 0
        let nextIndex = (last + 1) % inventory.count
        UserDefaults.standard.set(nextIndex, forKey: lastIndexKey)
        return inventory[nextIndex]
    }

    // MARK: - Analytics
    func recordImpression(_ ad: Ad, at date: Date = Date()) {
        state.impressions.append(.init(adId: ad.id, timestamp: date))
        persist()
    }
    func recordDismiss(_ ad: Ad) { /* hook */ }
    func recordClick(_ ad: Ad)   { /* hook */ }

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
