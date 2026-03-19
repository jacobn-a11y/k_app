import Testing
import Foundation
@testable import HallyuCore

@Suite("InteractionTracker Tests")
struct InteractionTrackerTests {

    @Test("Initial count is zero")
    func initialCount() async {
        let tracker = InteractionTracker()
        let count = await tracker.todayCount
        #expect(count == 0)
    }

    @Test("Recording interaction increments count")
    func recordIncrementsCount() async {
        let tracker = InteractionTracker()
        await tracker.recordInteraction(role: .comprehension, promptTokens: 100, completionTokens: 50)
        let count = await tracker.todayCount
        #expect(count == 1)
    }

    @Test("Multiple recordings increment correctly")
    func multipleRecordings() async {
        let tracker = InteractionTracker()
        await tracker.recordInteraction(role: .comprehension, promptTokens: 100, completionTokens: 50)
        await tracker.recordInteraction(role: .grammar, promptTokens: 200, completionTokens: 100)
        await tracker.recordInteraction(role: .pronunciation, promptTokens: 150, completionTokens: 75)
        let count = await tracker.todayCount
        #expect(count == 3)
    }

    @Test("Token tracking sums correctly")
    func tokenTracking() async {
        let tracker = InteractionTracker()
        await tracker.recordInteraction(role: .comprehension, promptTokens: 100, completionTokens: 50)
        await tracker.recordInteraction(role: .grammar, promptTokens: 200, completionTokens: 100)
        let total = await tracker.totalTokensToday
        #expect(total == 450) // 100+50+200+100
    }

    @Test("Per-role counting works")
    func perRoleCounting() async {
        let tracker = InteractionTracker()
        await tracker.recordInteraction(role: .comprehension, promptTokens: 100, completionTokens: 50)
        await tracker.recordInteraction(role: .comprehension, promptTokens: 100, completionTokens: 50)
        await tracker.recordInteraction(role: .grammar, promptTokens: 200, completionTokens: 100)
        let comprehensionCount = await tracker.count(for: .comprehension)
        let grammarCount = await tracker.count(for: .grammar)
        let culturalCount = await tracker.count(for: .cultural)
        #expect(comprehensionCount == 2)
        #expect(grammarCount == 1)
        #expect(culturalCount == 0)
    }
}
