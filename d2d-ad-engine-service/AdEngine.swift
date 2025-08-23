//
//  AdEngine.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/23/25.
//


import Foundation
import Combine

public final class AdEngine: ObservableObject {
    public static let shared = AdEngine()
    private init() {}

    /// Publish the current ad (or nil if none eligible)
    @Published public private(set) var currentAd: Ad?

    /// All ads; inject from your backend later.
    private var inventory: [Ad] = []

    /// Rotation timer (default every 20s)
    private var timerCancellable: AnyCancellable?

    /// Global default frequency cap: impressions per ad per hour (override per ad via `maxImpressionsPerHour`)
    public var defaultMaxImpressionsPerHour: Int = 1

    /// Start rotating through ads
    public func start(inventory: [Ad], periodSeconds: TimeInterval = 20) {
        self.inventory = inventory.sorted { $0.priority > $1.priority }
        rotateToNextEligibleAd()

        timerCancellable?.cancel()
        timerCancellable = Timer
            .publish(every: periodSeconds, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.rotateToNextEligibleAd()
            }
    }

    public func stop() {
        timerCancellable?.cancel()
        timerCancellable = nil
        currentAd = nil
    }

    public func notify(_ event: AdEvent, ad: Ad) {
        switch event {
        case .impression:
            AdStorage.shared.recordImpression(ad)
        case .click:
            AdStorage.shared.recordClick(ad)
        case .dismiss:
            AdStorage.shared.recordDismiss(ad)
        }
    }

    private func rotateToNextEligibleAd() {
        guard !inventory.isEmpty else { currentAd = nil; return }

        // Shuffle but weight by priority
        let weighted = inventory.flatMap { Array(repeating: $0, count: max(1, 1 + $0.priority)) }.shuffled()

        if let eligible = weighted.first(where: { isEligible($0) }) {
            if currentAd?.id != eligible.id {
                currentAd = eligible
            }
        } else {
            currentAd = nil
        }
    }

    private func isEligible(_ ad: Ad) -> Bool {
        // Frequency capping window = 1 hour
        let maxPerHour = ad.maxImpressionsPerHour ?? defaultMaxImpressionsPerHour
        if maxPerHour <= 0 { return false }

        let recent = AdStorage.shared.recentImpressions(for: ad, within: 3600)
        return recent < maxPerHour
    }
}
