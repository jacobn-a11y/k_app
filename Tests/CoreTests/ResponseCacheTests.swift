import Testing
import Foundation
@testable import HallyuCore

@Suite("ResponseCache Tests")
struct ResponseCacheTests {

    @Test("Cache key generation is deterministic")
    func cacheKeyDeterministic() {
        let key1 = ResponseCache.key(for: "comprehension", context: "안녕_A1")
        let key2 = ResponseCache.key(for: "comprehension", context: "안녕_A1")
        #expect(key1 == key2)
    }

    @Test("Different inputs produce different cache keys")
    func cacheKeyDiffers() {
        let key1 = ResponseCache.key(for: "comprehension", context: "안녕_A1")
        let key2 = ResponseCache.key(for: "grammar", context: "안녕_A1")
        #expect(key1 != key2)
    }

    @Test("Cache set and get roundtrip")
    func cacheRoundtrip() async {
        let cache = ResponseCache()
        let response = ComprehensionResponse(
            literalMeaning: "hello",
            contextualMeaning: "greeting",
            grammarPattern: nil,
            simplerExample: "hi",
            registerNote: nil
        )
        await cache.set(response, for: "test_key")
        let retrieved: ComprehensionResponse? = await cache.get(for: "test_key")
        #expect(retrieved?.literalMeaning == "hello")
    }

    @Test("Cache returns nil for missing key")
    func cacheMiss() async {
        let cache = ResponseCache()
        let result: ComprehensionResponse? = await cache.get(for: "nonexistent")
        #expect(result == nil)
    }

    @Test("Cache clear removes all entries")
    func cacheClear() async {
        let cache = ResponseCache()
        let response = ComprehensionResponse(
            literalMeaning: "test",
            contextualMeaning: "test",
            grammarPattern: nil,
            simplerExample: "test",
            registerNote: nil
        )
        await cache.set(response, for: "key1")
        await cache.clear()
        let result: ComprehensionResponse? = await cache.get(for: "key1")
        #expect(result == nil)
    }
}
