import Testing
import Foundation
@testable import HallyuCore

@Suite("HangulReviewIntegration Tests")
struct HangulReviewIntegrationTests {

    @Test("Creates review items for completed jamo")
    func createJamoReviewItems() {
        let userId = UUID()
        let items = HangulReviewIntegration.createReviewItems(
            userId: userId,
            completedJamoIds: ["ㄱ", "ㄴ", "ㄷ"]
        )
        #expect(items.count == 3)
        for item in items {
            #expect(item.userId == userId)
            #expect(item.itemType.starts(with: "hangul_"))
        }
    }

    @Test("Recognition mode creates correct item type")
    func recognitionMode() {
        let items = HangulReviewIntegration.createReviewItems(
            userId: UUID(),
            completedJamoIds: ["ㄱ"],
            mode: .recognition
        )
        #expect(items.first?.itemType == "hangul_recognition")
    }

    @Test("Production mode creates correct item type")
    func productionMode() {
        let items = HangulReviewIntegration.createReviewItems(
            userId: UUID(),
            completedJamoIds: ["ㄱ"],
            mode: .production
        )
        #expect(items.first?.itemType == "hangul_production")
    }

    @Test("Creates syllable block review items")
    func syllableBlockReviewItems() {
        let userId = UUID()
        let items = HangulReviewIntegration.createSyllableBlockReviewItems(
            userId: userId,
            syllables: ["가", "나", "다"]
        )
        #expect(items.count == 3)
        for item in items {
            #expect(item.itemType == "hangul_syllable")
        }
    }

    @Test("Deterministic UUID is stable for same input")
    func deterministicUUID() {
        let userId = UUID()
        let items1 = HangulReviewIntegration.createReviewItems(
            userId: userId,
            completedJamoIds: ["ㄱ"]
        )
        let items2 = HangulReviewIntegration.createReviewItems(
            userId: userId,
            completedJamoIds: ["ㄱ"]
        )
        #expect(items1.first?.itemId == items2.first?.itemId)
    }

    @Test("Different jamo produce different item IDs")
    func differentJamoDifferentIds() {
        let userId = UUID()
        let items = HangulReviewIntegration.createReviewItems(
            userId: userId,
            completedJamoIds: ["ㄱ", "ㄴ"]
        )
        #expect(items[0].itemId != items[1].itemId)
    }

    @Test("Review items have initial half-life of 1 day")
    func initialHalfLife() {
        let items = HangulReviewIntegration.createReviewItems(
            userId: UUID(),
            completedJamoIds: ["ㄱ"]
        )
        #expect(items.first?.halfLifeDays == 1.0)
    }

    @Test("Review items schedule first review in ~24 hours")
    func firstReviewTiming() {
        let now = Date()
        let items = HangulReviewIntegration.createReviewItems(
            userId: UUID(),
            completedJamoIds: ["ㄱ"]
        )
        guard let nextReview = items.first?.nextReviewAt else {
            Issue.record("No next review date")
            return
        }
        let hoursUntilReview = nextReview.timeIntervalSince(now) / 3600
        #expect(hoursUntilReview > 23 && hoursUntilReview < 25)
    }
}
