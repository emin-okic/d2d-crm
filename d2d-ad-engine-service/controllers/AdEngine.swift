//
//  AdEngine.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/23/25.
//

import Foundation
import Combine
import UIKit
import StoreKit

public enum RemoveAdsPurchaseState: Equatable {
    case idle
    case loading
    case pending
    case purchased
    case failed(String)

    var isLoading: Bool {
        self == .loading
    }
}

private enum RemoveAdsProduct {
    static let id = "com.d2dstudio.removeads"
    static let referenceName = "Remove Ads"
    static let appStoreConnectAppleID = "6778183326"
}

@MainActor
public final class AdEngine: ObservableObject {
    
    public static let shared = AdEngine()
    
    private init() {
        transactionUpdatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handleTransactionUpdate(result)
            }
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    @Published public private(set) var currentAd: Ad?

    private var inventory: [Ad] = []

    // Session gate: once closed (X or click), don't show again until next app launch
    private var sessionClosed = false
    
    @Published var adsRemoved = false
    @Published private(set) var removeAdsPurchaseState: RemoveAdsPurchaseState = .idle
    @Published private(set) var purchaseErrorMessage: String?
    
    private let removeAdsProductID = RemoveAdsProduct.id
    private var transactionUpdatesTask: Task<Void, Never>?
    
    func loadPurchases() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if transaction.productID == removeAdsProductID {
                unlockRemoveAds()
            }
        }
    }
    
    func purchaseRemoveAds() async {
        guard removeAdsPurchaseState != .loading else { return }

        removeAdsPurchaseState = .loading
        purchaseErrorMessage = nil

        do {
            let products = try await Product.products(for: [removeAdsProductID])

            guard let product = products.first else {
                failPurchase(
                    "\(RemoveAdsProduct.referenceName) is not available from the App Store yet. Expected product ID \(RemoveAdsProduct.id) with App Store Connect Apple ID \(RemoveAdsProduct.appStoreConnectAppleID). Confirm the Paid Apps Agreement, banking, tax, pricing, availability, and review status in App Store Connect."
                )
                return
            }

            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    unlockRemoveAds()
                    await transaction.finish()

                case .unverified(_, let error):
                    failPurchase("The purchase could not be verified: \(error.localizedDescription)")
                }

            case .pending:
                removeAdsPurchaseState = .pending

            case .userCancelled:
                removeAdsPurchaseState = .idle

            @unknown default:
                failPurchase("The App Store returned an unsupported purchase result.")
            }
        } catch {
            failPurchase("The purchase could not start: \(error.localizedDescription)")
        }
    }

    func clearPurchaseError() {
        purchaseErrorMessage = nil

        if case .failed = removeAdsPurchaseState {
            removeAdsPurchaseState = .idle
        }
    }

    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }

        if transaction.productID == removeAdsProductID {
            unlockRemoveAds()
            await transaction.finish()
        }
    }

    private func unlockRemoveAds() {
        adsRemoved = true
        currentAd = nil
        removeAdsPurchaseState = .purchased
    }

    private func failPurchase(_ message: String) {
        purchaseErrorMessage = message
        removeAdsPurchaseState = .failed(message)
    }

    // ===== NEW: one-shot startup API (no rotation) =====
    public func startSingleShot(inventory: [Ad]) {
        
        guard !adsRemoved else {

            currentAd = nil

            return

        }
        
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

    public func notify(_ event: AdEvent, ad: Ad) {
        // Local analytics stay the same
        switch event {
        case .impression: AdStorage.shared.recordImpression(ad)
        case .click:      AdStorage.shared.recordClick(ad)
        case .dismiss:    AdStorage.shared.recordDismiss(ad)
        }

        // Map to CloudKit event strings:
        // - .impression -> "impression"
        // - .click      -> "click"
        // - .dismiss    -> "cancel"   <-- changed from previous "click"
        let cloudEvent: String
        switch event {
        case .impression: cloudEvent = "impression"
        case .click:      cloudEvent = "click"
        case .dismiss:    cloudEvent = "cancel"
        }

        let payload = ImpressionPayload(
            adId: ad.id,
            event: cloudEvent,
            timestamp: Date()
        )
        CloudKitAdLogger.shared.log(payload)
    }
    
}
