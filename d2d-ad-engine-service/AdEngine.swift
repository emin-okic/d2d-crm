//
//  AdEngine.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/23/25.
//

import Foundation
import Combine
import UIKit

public final class AdEngine: ObservableObject {
    public static let shared = AdEngine()
    private init() {}

    @Published public private(set) var currentAd: Ad?

    private var inventory: [Ad] = []

    // Session gate: once closed (X or click), don't show again until next app launch
    private var sessionClosed = false

    // ===== NEW: one-shot startup API (no rotation) =====
    public func startSingleShot(inventory: [Ad]) {
        guard !sessionClosed else { return } // already dismissed/clicked this session
        self.inventory = inventory

        if let ad = AdStorage.shared.nextStartupAd(from: inventory) {
            currentAd = ad
        } else {
            currentAd = nil
        }
    }

    public func closeForSession(_ ad: Ad?) {
        if let ad { notify(.dismiss, ad: ad) }
        sessionClosed = true
        currentAd = nil
    }

    public func notifyClickAndClose(_ ad: Ad) {
        notify(.click, ad: ad)
        sessionClosed = true
        currentAd = nil
    }

    // ======== legacy rotation pieces kept but unused ========
    private var timerCancellable: AnyCancellable?
    public var defaultMaxImpressionsPerHour: Int = 1
    public func start(inventory: [Ad], periodSeconds: TimeInterval = 20) { /* no-op in single-shot mode */ }
    public func stop() { timerCancellable?.cancel(); timerCancellable = nil; currentAd = nil }

    private let sessionId = UUID().uuidString // or inject from App

    public func notify(_ event: AdEvent, ad: Ad) {
        let mappedEvent = (event == .dismiss) ? AdEvent.click : event
        // existing local storage hooks
        switch event {
        case .impression: AdStorage.shared.recordImpression(ad)
        case .click:      AdStorage.shared.recordClick(ad)
        case .dismiss:    AdStorage.shared.recordDismiss(ad)
        }

        let payload = ImpressionPayload(
            adId: ad.id,
            event: mappedEvent.rawValue,
            timestamp: Date(),
            sessionId: sessionId,
            appBuild: Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
            deviceModel: UIDevice.current.model
        )
        CloudKitAdLogger.shared.log(payload)
    }
    
}
