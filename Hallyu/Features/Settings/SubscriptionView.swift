import SwiftUI

struct SubscriptionView: View {
    @Environment(ServiceContainer.self) private var services
    @State private var products: [SubscriptionProduct] = []
    @State private var isLoading = false
    @State private var selectedBilling: BillingPeriod = .monthly
    @State private var purchaseError: String?
    @State private var showError = false
    let currentTier: AppState.SubscriptionTier
    let onTierChanged: (AppState.SubscriptionTier) -> Void

    enum BillingPeriod {
        case monthly, annual
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                billingToggle
                tierCards
                restoreButton
                legalText
            }
            .padding()
        }
        .navigationTitle("Upgrade")
        .inlineNavigationTitleDisplayMode()
        .task { await loadProducts() }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(purchaseError ?? "An error occurred.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Unlock Your Full\nKorean Journey")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Choose the plan that fits your learning style")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Billing Toggle

    private var billingToggle: some View {
        Picker("Billing", selection: $selectedBilling) {
            Text("Monthly").tag(BillingPeriod.monthly)
            Text("Annual (Save 35%)").tag(BillingPeriod.annual)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Tier Cards

    private var tierCards: some View {
        VStack(spacing: 16) {
            // Core tier
            TierCard(
                name: "Core",
                price: corePrice,
                features: [
                    "Claude AI Korean coach (50/day)",
                    "Full media library",
                    "Progress tracking & CEFR milestones",
                    "Offline downloads",
                ],
                isCurrent: currentTier == .core,
                isPopular: true,
                isLoading: isLoading
            ) {
                guard let productId = coreProductId else {
                    purchaseError = "Core product is not available in this storefront."
                    showError = true
                    return
                }
                await purchaseProduct(productId)
            }

            // Pro tier
            TierCard(
                name: "Pro",
                price: proPrice,
                features: [
                    "Everything in Core",
                    "Unlimited Claude AI coaching",
                    "Priority content updates",
                    "Advanced pronunciation analysis",
                ],
                isCurrent: currentTier == .pro,
                isPopular: false,
                isLoading: isLoading
            ) {
                guard let productId = proProductId else {
                    purchaseError = "Pro product is not available in this storefront."
                    showError = true
                    return
                }
                await purchaseProduct(productId)
            }
        }
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task { await restorePurchases() }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    // MARK: - Legal

    private var legalText: some View {
        Text("Payment will be charged to your Apple ID account. Subscription automatically renews unless turned off at least 24 hours before the end of the current period.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    // MARK: - Actions

    private func loadProducts() async {
        do {
            products = try await services.subscription.loadProducts()
        } catch {
            purchaseError = error.localizedDescription
            showError = true
        }
    }

    private func purchaseProduct(_ productId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let status = try await services.subscription.purchase(productId: productId)
            if let tier = AppState.SubscriptionTier(rawValue: status.tier) {
                onTierChanged(tier)
            }
        } catch {
            purchaseError = error.localizedDescription
            showError = true
        }
    }

    private func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let status = try await services.subscription.restorePurchases()
            if let tier = AppState.SubscriptionTier(rawValue: status.tier) {
                onTierChanged(tier)
            }
        } catch {
            purchaseError = error.localizedDescription
            showError = true
        }
    }

    private var coreProductId: String? {
        if selectedBilling == .monthly {
            return products.first(where: { $0.id == SubscriptionProductId.coreMonthly.rawValue })?.id
        }
        return products.first(where: { $0.id == SubscriptionProductId.coreAnnual.rawValue })?.id
    }

    private var proProductId: String? {
        if selectedBilling == .monthly {
            return products.first(where: { $0.id == SubscriptionProductId.proMonthly.rawValue })?.id
        }
        return products.first(where: { $0.id == SubscriptionProductId.proAnnual.rawValue })?.id
    }

    private var corePrice: String {
        if let id = coreProductId, let product = products.first(where: { $0.id == id }) {
            return product.priceFormatted
        }
        return selectedBilling == .monthly ? "$12.99/mo" : "$99.99/yr"
    }

    private var proPrice: String {
        if let id = proProductId, let product = products.first(where: { $0.id == id }) {
            return product.priceFormatted
        }
        return selectedBilling == .monthly ? "$19.99/mo" : "$149.99/yr"
    }
}

// MARK: - Tier Card

struct TierCard: View {
    let name: String
    let price: String
    let features: [String]
    let isCurrent: Bool
    let isPopular: Bool
    let isLoading: Bool
    let onSubscribe: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(name)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                if isPopular {
                    Text("Popular")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }

            Text(price)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.subheadline)
                        Text(feature)
                            .font(.subheadline)
                    }
                }
            }

            if isCurrent {
                Text("Current Plan")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundStyle(.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Button {
                    Task { await onSubscribe() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Subscribe")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .buttonStyle(.borderedProminent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(isLoading)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPopular ? Color.blue : .clear, lineWidth: 2)
        )
    }
}

private extension View {
    @ViewBuilder
    func inlineNavigationTitleDisplayMode() -> some View {
        #if os(iOS) || os(tvOS) || os(watchOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
