import Foundation

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
    // In a real app, this would use StoreKit 2's Product, Transaction, etc.
    // This implementation provides the business logic layer that wraps StoreKit.

    private(set) var currentTier: AppState.SubscriptionTier = .free
    private var cachedProducts: [SubscriptionProduct] = []
    private var activeSubscription: SubscriptionStatus?
    private let tierKey = "com.hallyu.subscriptionTier"

    init() {
        // Load persisted tier
        if let saved = UserDefaults.standard.string(forKey: tierKey),
           let tier = AppState.SubscriptionTier(rawValue: saved) {
            currentTier = tier
        }
    }

    // MARK: - Load Products

    func loadProducts() async throws -> [SubscriptionProduct] {
        // In production, this calls StoreKit 2:
        // let products = try await Product.products(for: SubscriptionProductId.allCases.map(\.rawValue))
        // For now, return the product catalog:
        let products = [
            SubscriptionProduct(
                id: SubscriptionProductId.coreMonthly.rawValue,
                name: "Core Monthly",
                description: "Claude AI coach, full media library, progress tracking",
                priceFormatted: "$12.99/month",
                tier: "core"
            ),
            SubscriptionProduct(
                id: SubscriptionProductId.coreAnnual.rawValue,
                name: "Core Annual",
                description: "Claude AI coach, full media library, progress tracking",
                priceFormatted: "$99.99/year",
                tier: "core"
            ),
            SubscriptionProduct(
                id: SubscriptionProductId.proMonthly.rawValue,
                name: "Pro Monthly",
                description: "Everything in Core + unlimited AI coaching",
                priceFormatted: "$19.99/month",
                tier: "pro"
            ),
            SubscriptionProduct(
                id: SubscriptionProductId.proAnnual.rawValue,
                name: "Pro Annual",
                description: "Everything in Core + unlimited AI coaching",
                priceFormatted: "$149.99/year",
                tier: "pro"
            ),
        ]
        cachedProducts = products
        return products
    }

    // MARK: - Purchase

    func purchase(productId: String) async throws -> SubscriptionStatus {
        guard let productEnum = SubscriptionProductId(rawValue: productId) else {
            throw SubscriptionError.productNotFound
        }

        // In production:
        // guard let product = try await Product.products(for: [productId]).first else { throw ... }
        // let result = try await product.purchase()
        // switch result { case .success(let verification): ... }

        let tier = productEnum.tier
        currentTier = tier
        persistTier(tier)

        let status = SubscriptionStatus(
            tier: tier.rawValue,
            isActive: true,
            expiresAt: productEnum.isAnnual
                ? Date().addingTimeInterval(365 * 24 * 3600)
                : Date().addingTimeInterval(30 * 24 * 3600)
        )
        activeSubscription = status
        return status
    }

    // MARK: - Restore

    func restorePurchases() async throws -> SubscriptionStatus {
        // In production:
        // for await result in Transaction.currentEntitlements { ... }

        // If no active subscription found, reset to free
        if activeSubscription == nil {
            currentTier = .free
            persistTier(.free)
            return SubscriptionStatus(tier: "free", isActive: true, expiresAt: nil)
        }

        return activeSubscription!
    }

    // MARK: - Entitlement

    func checkEntitlement(feature: String) -> Bool {
        guard let feat = SubscriptionFeature(rawValue: feature) else { return false }
        return tierMeetsMinimum(current: currentTier, required: feat.minimumTier)
    }

    // MARK: - Helpers

    private func tierMeetsMinimum(current: AppState.SubscriptionTier, required: AppState.SubscriptionTier) -> Bool {
        let order: [AppState.SubscriptionTier] = [.free, .core, .pro]
        guard let currentIndex = order.firstIndex(of: current),
              let requiredIndex = order.firstIndex(of: required) else { return false }
        return currentIndex >= requiredIndex
    }

    private func persistTier(_ tier: AppState.SubscriptionTier) {
        UserDefaults.standard.set(tier.rawValue, forKey: tierKey)
    }
}
