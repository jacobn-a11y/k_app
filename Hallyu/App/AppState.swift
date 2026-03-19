import Foundation
import Observation

@Observable
final class AppState {
    var isOnboardingComplete: Bool = false
    var currentCEFRLevel: CEFRLevel = .preA1
    var dailyGoalMinutes: Int = 15
    var currentUserId: UUID?
    var subscriptionTier: SubscriptionTier = .free
    var isAuthenticated: Bool = false

    // Offline state
    var isOffline: Bool = false
    var pendingSyncCount: Int = 0

    // Deep link navigation
    var pendingDeepLink: DeepLink?

    enum CEFRLevel: String, Codable, CaseIterable, Comparable {
        case preA1 = "pre-A1"
        case a1 = "A1"
        case a2 = "A2"
        case b1 = "B1"
        case b2 = "B2"

        static func < (lhs: CEFRLevel, rhs: CEFRLevel) -> Bool {
            let order: [CEFRLevel] = [.preA1, .a1, .a2, .b1, .b2]
            guard let lhsIndex = order.firstIndex(of: lhs),
                  let rhsIndex = order.firstIndex(of: rhs) else { return false }
            return lhsIndex < rhsIndex
        }
    }

    enum SubscriptionTier: String, Codable, CaseIterable {
        case free
        case core
        case pro
    }
}
