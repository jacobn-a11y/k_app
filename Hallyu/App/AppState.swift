import Foundation
import Observation

@Observable
final class AppState {
    private static let currentUserIdKey = "appState.currentUserId"

    var isOnboardingComplete: Bool = false
    var currentCEFRLevel: CEFRLevel = .preA1
    var dailyGoalMinutes: Int = 15
    var currentUserId: UUID? {
        didSet {
            if let id = currentUserId {
                UserDefaults.standard.set(id.uuidString, forKey: Self.currentUserIdKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.currentUserIdKey)
            }
        }
    }
    var subscriptionTier: SubscriptionTier = .free
    var isAuthenticated: Bool = false

    // Offline state
    var isOffline: Bool = false
    var pendingSyncCount: Int = 0

    // Feed session state
    var feedSessionActive: Bool = false

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

    init() {
        if let storedUserId = UserDefaults.standard.string(forKey: Self.currentUserIdKey),
           let parsed = UUID(uuidString: storedUserId) {
            currentUserId = parsed
        }
    }
}
