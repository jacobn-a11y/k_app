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
        .navigationBarTitleDisplayMode(.inline)
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
                price: selectedBilling == .monthly ? "$12.99/mo" : "$99.99/yr",
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
                let productId = selectedBilling == .monthly
                    ? SubscriptionProductId.coreMonthly.rawValue
                    : SubscriptionProductId.coreAnnual.rawValue
                await purchaseProduct(productId)
            }

            // Pro tier
            TierCard(
                name: "Pro",
                price: selectedBilling == .monthly ? "$19.99/mo" : "$149.99/yr",
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
                let productId = selectedBilling == .monthly
                    ? SubscriptionProductId.proMonthly.rawValue
                    : SubscriptionProductId.proAnnual.rawValue
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
                    .background(Color(.systemGray5))
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
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isPopular ? Color.blue : .clear, lineWidth: 2)
        )
    }
}
