//
//  StoreManager.swift
//  d2d-studio
//
//  Created by Emin Okic on 6/8/26.
//


import StoreKit

@MainActor
final class StoreManager: ObservableObject {

    @Published var adsRemoved = false

    private let removeAdsID = "com.d2dstudio.removeads"

    // 👇 ALWAYS put helpers ABOVE usage
    private func checkVerified<T>(
        _ result: VerificationResult<T>
    ) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    func purchaseRemoveAds() async {
        do {
            let products = try await Product.products(for: [removeAdsID])
            guard let product = products.first else { return }

            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                adsRemoved = true
                await transaction.finish()

            case .userCancelled, .pending:
                break

            @unknown default:
                break
            }

        } catch {
            print("Purchase failed:", error)
        }
    }
}
