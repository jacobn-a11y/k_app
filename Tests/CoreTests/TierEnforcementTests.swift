import Testing
import Foundation
@testable import HallyuCore

@Suite("Tier Enforcement Tests")
struct TierEnforcementTests {

    @Test("Free tier has 0 daily limit")
    func freeTierLimit() {
        let limits = ClaudeTierLimits.limits(for: .free)
        #expect(limits.dailyLimit == 0)
        #expect(!limits.isAllowed(currentCount: 0))
    }

    @Test("Core tier has 50 daily limit")
    func coreTierLimit() {
        let limits = ClaudeTierLimits.limits(for: .core)
        #expect(limits.dailyLimit == 50)
        #expect(limits.isAllowed(currentCount: 0))
        #expect(limits.isAllowed(currentCount: 49))
        #expect(!limits.isAllowed(currentCount: 50))
        #expect(!limits.isAllowed(currentCount: 100))
    }

    @Test("Pro tier has unlimited access")
    func proTierLimit() {
        let limits = ClaudeTierLimits.limits(for: .pro)
        #expect(limits.dailyLimit == nil)
        #expect(limits.isAllowed(currentCount: 0))
        #expect(limits.isAllowed(currentCount: 1000))
        #expect(limits.isAllowed(currentCount: Int.max))
    }

    @Test("ClaudeRole enum has all 5 roles")
    func allRoles() {
        let roles = ClaudeRole.allCases
        #expect(roles.count == 5)
        #expect(roles.contains(.comprehension))
        #expect(roles.contains(.pronunciation))
        #expect(roles.contains(.grammar))
        #expect(roles.contains(.contentAdapter))
        #expect(roles.contains(.cultural))
    }

    @Test("ClaudeRole raw values are correct")
    func roleRawValues() {
        #expect(ClaudeRole.comprehension.rawValue == "comprehension")
        #expect(ClaudeRole.pronunciation.rawValue == "pronunciation")
        #expect(ClaudeRole.grammar.rawValue == "grammar")
        #expect(ClaudeRole.contentAdapter.rawValue == "content_adapter")
        #expect(ClaudeRole.cultural.rawValue == "cultural")
    }
}
