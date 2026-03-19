import Testing
import Foundation
@testable import HallyuCore

@Suite("SubscriptionService Tests")
struct SubscriptionServiceTests {

    // MARK: - Product IDs

    @Test("All product IDs map to correct tiers")
    func productIdTiers() {
        #expect(SubscriptionProductId.coreMonthly.tier == .core)
        #expect(SubscriptionProductId.coreAnnual.tier == .core)
        #expect(SubscriptionProductId.proMonthly.tier == .pro)
        #expect(SubscriptionProductId.proAnnual.tier == .pro)
    }

    @Test("Annual products identified correctly")
    func annualProducts() {
        #expect(SubscriptionProductId.coreAnnual.isAnnual == true)
        #expect(SubscriptionProductId.proAnnual.isAnnual == true)
        #expect(SubscriptionProductId.coreMonthly.isAnnual == false)
        #expect(SubscriptionProductId.proMonthly.isAnnual == false)
    }

    // MARK: - Feature Entitlements

    @Test("Feature minimum tiers are correct")
    func featureMinimumTiers() {
        #expect(SubscriptionFeature.claudeCoach.minimumTier == .core)
        #expect(SubscriptionFeature.unlimitedClaude.minimumTier == .pro)
        #expect(SubscriptionFeature.mediaDownloads.minimumTier == .core)
        #expect(SubscriptionFeature.advancedProgress.minimumTier == .core)
        #expect(SubscriptionFeature.allMedia.minimumTier == .core)
    }

    // MARK: - StoreKit Subscription Service

    @Test("Service starts at free tier")
    func initialTier() {
        // Clear any persisted state for test isolation
        UserDefaults.standard.removeObject(forKey: "com.hallyu.subscriptionTier")
        let service = StoreKitSubscriptionService()
        #expect(service.currentTier == .free)
    }

    @Test("Load products returns all tiers")
    func loadProducts() async throws {
        let service = StoreKitSubscriptionService()
        let products = try await service.loadProducts()
        #expect(products.count == 4)

        let tiers = Set(products.map { $0.tier })
        #expect(tiers.contains("core"))
        #expect(tiers.contains("pro"))
    }

    @Test("Purchase updates tier to core")
    func purchaseCore() async throws {
        let service = StoreKitSubscriptionService()
        let status = try await service.purchase(productId: SubscriptionProductId.coreMonthly.rawValue)
        #expect(status.isActive == true)
        #expect(status.tier == "core")
        #expect(service.currentTier == .core)
    }

    @Test("Purchase updates tier to pro")
    func purchasePro() async throws {
        let service = StoreKitSubscriptionService()
        let status = try await service.purchase(productId: SubscriptionProductId.proMonthly.rawValue)
        #expect(status.isActive == true)
        #expect(status.tier == "pro")
        #expect(service.currentTier == .pro)
    }

    @Test("Annual purchase has later expiry")
    func annualExpiry() async throws {
        let service = StoreKitSubscriptionService()
        let status = try await service.purchase(productId: SubscriptionProductId.coreAnnual.rawValue)
        let oneYearFromNow = Date().addingTimeInterval(364 * 24 * 3600)
        #expect(status.expiresAt! > oneYearFromNow)
    }

    @Test("Purchase with invalid product ID throws")
    func invalidProductThrows() async {
        let service = StoreKitSubscriptionService()
        do {
            _ = try await service.purchase(productId: "invalid_id")
            Issue.record("Should have thrown")
        } catch {
            #expect(error is SubscriptionError)
        }
    }

    @Test("Restore with no subscription returns free")
    func restoreNoSubscription() async throws {
        UserDefaults.standard.removeObject(forKey: "com.hallyu.subscriptionTier")
        let service = StoreKitSubscriptionService()
        let status = try await service.restorePurchases()
        #expect(status.tier == "free")
    }

    // MARK: - Entitlement Checking

    @Test("Free tier has no entitlements")
    func freeNoEntitlements() {
        UserDefaults.standard.removeObject(forKey: "com.hallyu.subscriptionTier")
        let service = StoreKitSubscriptionService()
        #expect(service.checkEntitlement(feature: SubscriptionFeature.claudeCoach.rawValue) == false)
        #expect(service.checkEntitlement(feature: SubscriptionFeature.unlimitedClaude.rawValue) == false)
    }

    @Test("Core tier has core entitlements but not pro")
    func coreEntitlements() async throws {
        let service = StoreKitSubscriptionService()
        _ = try await service.purchase(productId: SubscriptionProductId.coreMonthly.rawValue)
        #expect(service.checkEntitlement(feature: SubscriptionFeature.claudeCoach.rawValue) == true)
        #expect(service.checkEntitlement(feature: SubscriptionFeature.allMedia.rawValue) == true)
        #expect(service.checkEntitlement(feature: SubscriptionFeature.unlimitedClaude.rawValue) == false)
    }

    @Test("Pro tier has all entitlements")
    func proEntitlements() async throws {
        let service = StoreKitSubscriptionService()
        _ = try await service.purchase(productId: SubscriptionProductId.proMonthly.rawValue)
        #expect(service.checkEntitlement(feature: SubscriptionFeature.claudeCoach.rawValue) == true)
        #expect(service.checkEntitlement(feature: SubscriptionFeature.unlimitedClaude.rawValue) == true)
        #expect(service.checkEntitlement(feature: SubscriptionFeature.allMedia.rawValue) == true)
    }

    @Test("Invalid feature returns false")
    func invalidFeature() {
        let service = StoreKitSubscriptionService()
        #expect(service.checkEntitlement(feature: "nonexistent") == false)
    }

    // MARK: - Mock Subscription Service

    @Test("Mock starts at free tier")
    func mockInitialTier() {
        let mock = MockSubscriptionService()
        #expect(mock.currentTier == .free)
    }

    @Test("Mock loads products")
    func mockLoadProducts() async throws {
        let mock = MockSubscriptionService()
        let products = try await mock.loadProducts()
        #expect(products.count >= 2)
    }

    @Test("Mock purchase returns active status")
    func mockPurchase() async throws {
        let mock = MockSubscriptionService()
        let status = try await mock.purchase(productId: "core_monthly")
        #expect(status.isActive == true)
    }

    @Test("Mock restore returns free status")
    func mockRestore() async throws {
        let mock = MockSubscriptionService()
        let status = try await mock.restorePurchases()
        #expect(status.tier == "free")
    }

    // MARK: - Subscription Error Display

    @Test("Subscription errors have descriptions")
    func errorDescriptions() {
        let errors: [SubscriptionError] = [
            .productNotFound,
            .purchaseFailed("test"),
            .purchaseCancelled,
            .verificationFailed,
            .restoreFailed,
            .notAvailable,
        ]
        for error in errors {
            #expect(error.errorDescription != nil)
        }
    }

    // MARK: - SubscriptionProduct Codable

    @Test("SubscriptionProduct encodes and decodes")
    func productCodable() throws {
        let product = SubscriptionProduct(
            id: "test_id",
            name: "Test",
            description: "A test product",
            priceFormatted: "$9.99",
            tier: "core"
        )
        let data = try JSONEncoder().encode(product)
        let decoded = try JSONDecoder().decode(SubscriptionProduct.self, from: data)
        #expect(decoded.id == product.id)
        #expect(decoded.tier == product.tier)
    }
}
