import Testing
import Foundation
@testable import HallyuCore

@Suite("Enhanced ResponseCache Tests")
struct EnhancedResponseCacheTests {

    @Test("Cache count starts at zero")
    func cacheCountZero() async {
        let cache = ResponseCache()
        let count = await cache.count
        #expect(count == 0)
    }

    @Test("Cache count increments with entries")
    func cacheCountIncrements() async {
        let cache = ResponseCache()
        let response = ComprehensionResponse(
            literalMeaning: "test",
            contextualMeaning: "test",
            grammarPattern: nil,
            simplerExample: "test",
            registerNote: nil
        )
        await cache.set(response, for: "key1")
        await cache.set(response, for: "key2")
        let count = await cache.count
        #expect(count == 2)
    }

    @Test("Purge expired entries with short TTL")
    func purgeExpired() async {
        let cache = ResponseCache(ttl: 0.01) // 10ms TTL
        let response = ComprehensionResponse(
            literalMeaning: "test",
            contextualMeaning: "test",
            grammarPattern: nil,
            simplerExample: "test",
            registerNote: nil
        )
        await cache.set(response, for: "key1")
        // Wait for expiry
        try? await Task.sleep(nanoseconds: 20_000_000) // 20ms
        await cache.purgeExpired()
        let count = await cache.count
        #expect(count == 0)
    }

    @Test("Non-expired entries survive purge")
    func nonExpiredSurvive() async {
        let cache = ResponseCache(ttl: 3600) // 1 hour TTL
        let response = ComprehensionResponse(
            literalMeaning: "test",
            contextualMeaning: "test",
            grammarPattern: nil,
            simplerExample: "test",
            registerNote: nil
        )
        await cache.set(response, for: "key1")
        await cache.purgeExpired()
        let count = await cache.count
        #expect(count == 1)
    }

    @Test("Cache works with CulturalContextResponse")
    func cacheCulturalContext() async {
        let cache = ResponseCache()
        let response = CulturalContextResponse(
            explanation: "Cultural explanation",
            socialDynamics: "Social dynamics",
            honorificNote: "Use 존댓말 with elders",
            historicalContext: nil,
            relatedMedia: ["Drama A", "Drama B"]
        )
        await cache.set(response, for: "cultural_key")
        let retrieved: CulturalContextResponse? = await cache.get(for: "cultural_key")
        #expect(retrieved?.explanation == "Cultural explanation")
        #expect(retrieved?.honorificNote == "Use 존댓말 with elders")
        #expect(retrieved?.relatedMedia.count == 2)
    }

    @Test("Cache works with GrammarExplanation")
    func cacheGrammar() async {
        let cache = ResponseCache()
        let response = GrammarExplanation(
            ruleStatement: "Subject marker rule",
            explanation: "Used to mark the subject",
            contrastiveExample: "나는 vs 내가",
            retrievalQuestion: "When do you use -이 vs -가?"
        )
        await cache.set(response, for: "grammar_key")
        let retrieved: GrammarExplanation? = await cache.get(for: "grammar_key")
        #expect(retrieved?.ruleStatement == "Subject marker rule")
    }
}
