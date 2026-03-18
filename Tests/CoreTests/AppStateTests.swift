import Testing
import Foundation
@testable import HallyuCore

@Suite("AppState Tests")
struct AppStateTests {

    @Test("CEFRLevel ordering is correct")
    func cefrLevelOrdering() {
        #expect(AppState.CEFRLevel.preA1 < AppState.CEFRLevel.a1)
        #expect(AppState.CEFRLevel.a1 < AppState.CEFRLevel.a2)
        #expect(AppState.CEFRLevel.a2 < AppState.CEFRLevel.b1)
        #expect(AppState.CEFRLevel.b1 < AppState.CEFRLevel.b2)
    }

    @Test("CEFRLevel rawValue matches expected strings")
    func cefrLevelRawValues() {
        #expect(AppState.CEFRLevel.preA1.rawValue == "pre-A1")
        #expect(AppState.CEFRLevel.a1.rawValue == "A1")
        #expect(AppState.CEFRLevel.a2.rawValue == "A2")
        #expect(AppState.CEFRLevel.b1.rawValue == "B1")
        #expect(AppState.CEFRLevel.b2.rawValue == "B2")
    }

    @Test("SubscriptionTier cases exist")
    func subscriptionTiers() {
        #expect(AppState.SubscriptionTier.allCases.count == 3)
        #expect(AppState.SubscriptionTier.free.rawValue == "free")
        #expect(AppState.SubscriptionTier.core.rawValue == "core")
        #expect(AppState.SubscriptionTier.pro.rawValue == "pro")
    }
}
