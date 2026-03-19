import Foundation
#if canImport(StoreKit)
import StoreKit
#endif

// MARK: - Subscription Errors

enum SubscriptionError: Error, LocalizedError {
    case productNotFound
    case purchaseFailed(String)
    case purchaseCancelled
    case verificationFailed
    case restoreFailed
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .productNotFound: return "Subscription product not found."
        case .purchaseFailed(let msg): return "Purchase failed: \(msg)"
        case .purchaseCancelled: return "Purchase was cancelled."
        case .verificationFailed: return "Could not verify your purchase."
        case .restoreFailed: return "Could not restore purchases."
        case .notAvailable: return "In-app purchases are not available."
        }
    }
}

// MARK: - Product IDs

enum SubscriptionProductId: String, CaseIterable {
    case coreMonthly = "com.hallyu.core.monthly"
    case coreAnnual = "com.hallyu.core.annual"
    case proMonthly = "com.hallyu.pro.monthly"
    case proAnnual = "com.hallyu.pro.annual"

    var tier: AppState.SubscriptionTier {
        switch self {
        case .coreMonthly, .coreAnnual: return .core
        case .proMonthly, .proAnnual: return .pro
        }
    }

    var isAnnual: Bool {
        switch self {
        case .coreAnnual, .proAnnual: return true
        default: return false
        }
    }
}

// MARK: - Feature Entitlements

enum SubscriptionFeature: String, CaseIterable {
    case claudeCoach = "claude_coach"
    case unlimitedClaude = "unlimited_claude"
    case mediaDownloads = "media_downloads"
    case advancedProgress = "advanced_progress"
    case allMedia = "all_media"

    var minimumTier: AppState.SubscriptionTier {
        switch self {
        case .claudeCoach: return .core
        case .unlimitedClaude: return .pro
        case .mediaDownloads: return .core
        case .advancedProgress: return .core
        case .allMedia: return .core
        }
    }
}

// MARK: - Subscription Service Implementation

final class StoreKitSubscriptionService: SubscriptionServiceProtocol, @unchecked Sendable {
    private(set) var currentTier: AppState.SubscriptionTier = .free
    private var cachedProducts: [SubscriptionProduct] = []
    private var activeSubscription: SubscriptionStatus?
    private let tierKey = "com.hallyu.subscriptionTier"

    #if canImport(StoreKit)
    private var storeProducts: [Product] = []
    #endif

    init() {
        if let data = KeychainHelper.load(forKey: tierKey),
           let saved = String(data: data, encoding: .utf8),
           let tier = AppState.SubscriptionTier(rawValue: saved) {
            currentTier = tier
        }
    }

    // MARK: - Load Products

    func loadProducts() async throws -> [SubscriptionProduct] {
        #if canImport(StoreKit)
        guard !SubscriptionProductId.allCases.isEmpty else {
            throw SubscriptionError.notAvailable
        }

        let ids = SubscriptionProductId.allCases.map(\.rawValue)
        let products = try await Product.products(for: ids)
        guard !products.isEmpty else {
            throw SubscriptionError.notAvailable
        }

        storeProducts = products
        cachedProducts = products
            .sorted { $0.displayName < $1.displayName }
            .map {
                SubscriptionProduct(
                    id: $0.id,
                    name: $0.displayName,
                    description: $0.description,
                    priceFormatted: $0.displayPrice,
                    tier: SubscriptionProductId(rawValue: $0.id)?.tier.rawValue ?? "free"
                )
            }

        return cachedProducts
        #else
        throw SubscriptionError.notAvailable
        #endif
    }

    // MARK: - Purchase

    func purchase(productId: String) async throws -> SubscriptionStatus {
        guard let productEnum = SubscriptionProductId(rawValue: productId) else {
            throw SubscriptionError.productNotFound
        }

        #if canImport(StoreKit)
        let product = try await resolveProduct(withId: productId)
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()

            let tier = productEnum.tier
            currentTier = tier
            persistTier(tier)

            let status = SubscriptionStatus(
                tier: tier.rawValue,
                isActive: true,
                expiresAt: transaction.expirationDate
            )
            activeSubscription = status
            return status

        case .pending:
            throw SubscriptionError.purchaseFailed("Transaction pending approval.")

        case .userCancelled:
            throw SubscriptionError.purchaseCancelled

        @unknown default:
            throw SubscriptionError.purchaseFailed("Unknown StoreKit purchase state.")
        }
        #else
        throw SubscriptionError.notAvailable
        #endif
    }

    // MARK: - Restore

    func restorePurchases() async throws -> SubscriptionStatus {
        #if canImport(StoreKit)
        var highestTier: AppState.SubscriptionTier = .free
        var latestExpiration: Date?

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            let tier = SubscriptionProductId(rawValue: transaction.productID)?.tier ?? .free
            if tierRank(tier) > tierRank(highestTier) {
                highestTier = tier
            }
            if let expiration = transaction.expirationDate,
               latestExpiration == nil || expiration > latestExpiration! {
                latestExpiration = expiration
            }
        }

        currentTier = highestTier
        persistTier(highestTier)

        let status = SubscriptionStatus(
            tier: highestTier.rawValue,
            isActive: true,
            expiresAt: latestExpiration
        )
        activeSubscription = status
        return status
        #else
        throw SubscriptionError.notAvailable
        #endif
    }

    // MARK: - Entitlement

    func checkEntitlement(feature: String) -> Bool {
        guard let feat = SubscriptionFeature(rawValue: feature) else { return false }
        return tierMeetsMinimum(current: currentTier, required: feat.minimumTier)
    }

    // MARK: - Helpers

    private func tierMeetsMinimum(current: AppState.SubscriptionTier, required: AppState.SubscriptionTier) -> Bool {
        tierRank(current) >= tierRank(required)
    }

    private func tierRank(_ tier: AppState.SubscriptionTier) -> Int {
        switch tier {
        case .free: return 0
        case .core: return 1
        case .pro: return 2
        }
    }

    private func persistTier(_ tier: AppState.SubscriptionTier) {
        if let data = tier.rawValue.data(using: .utf8) {
            KeychainHelper.save(data, forKey: tierKey)
        }
    }

    #if canImport(StoreKit)
    private func resolveProduct(withId id: String) async throws -> Product {
        if let cached = storeProducts.first(where: { $0.id == id }) {
            return cached
        }

        let products = try await Product.products(for: [id])
        guard let product = products.first else {
            throw SubscriptionError.productNotFound
        }
        storeProducts = storeProducts + [product]
        return product
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw SubscriptionError.verificationFailed
        }
    }
    #endif
}
