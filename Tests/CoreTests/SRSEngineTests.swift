import Testing
import Foundation
@testable import HallyuCore

@Suite("SRSEngine Tests")
struct SRSEngineTests {

    let engine = SRSEngine()

    private func makeItem(
        halfLife: Double = 1.0,
        lastReviewed: Date? = Date().addingTimeInterval(-86400),
        nextReview: Date = Date().addingTimeInterval(-3600)
    ) -> ReviewItem {
        let item = ReviewItem(
            userId: UUID(),
            itemType: "vocabulary",
            itemId: UUID(),
            halfLifeDays: halfLife,
            nextReviewAt: nextReview
        )
        item.lastReviewedAt = lastReviewed
        return item
    }

    // MARK: - Recall Probability

    @Test("Recall probability is 0 for never-reviewed items")
    func neverReviewedRecall() {
        let item = ReviewItem(userId: UUID(), itemType: "vocab", itemId: UUID())
        let probability = engine.predictRecallProbability(item: item, at: Date())
        #expect(probability == 0.0)
    }

    @Test("Recall probability is ~0.5 at half-life")
    func halfLifeRecall() {
        let item = makeItem(halfLife: 1.0, lastReviewed: Date().addingTimeInterval(-86400))
        let probability = engine.predictRecallProbability(item: item, at: Date())
        // At exactly one half-life, probability should be ~0.5
        #expect(abs(probability - 0.5) < 0.05)
    }

    @Test("Recall probability is ~1.0 immediately after review")
    func justReviewedRecall() {
        let item = makeItem(halfLife: 1.0, lastReviewed: Date())
        let probability = engine.predictRecallProbability(item: item, at: Date())
        #expect(probability > 0.95)
    }

    @Test("Recall probability decreases over time")
    func recallDecreases() {
        let item = makeItem(halfLife: 1.0, lastReviewed: Date().addingTimeInterval(-86400))
        let recent = engine.predictRecallProbability(item: item, at: Date().addingTimeInterval(-43200))
        let later = engine.predictRecallProbability(item: item, at: Date())
        #expect(recent > later)
    }

    // MARK: - Scheduling

    @Test("Correct answer increases interval")
    func correctIncreasesInterval() {
        let item = makeItem(halfLife: 1.0)
        let originalHalfLife = item.halfLifeDays
        _ = engine.scheduleNextReview(item: item, wasCorrect: true, responseTime: 5.0)
        #expect(item.halfLifeDays > originalHalfLife)
        #expect(item.correctCount == 1)
    }

    @Test("Incorrect answer decreases interval")
    func incorrectDecreasesInterval() {
        let item = makeItem(halfLife: 2.0)
        let originalHalfLife = item.halfLifeDays
        _ = engine.scheduleNextReview(item: item, wasCorrect: false, responseTime: 5.0)
        #expect(item.halfLifeDays < originalHalfLife)
        #expect(item.incorrectCount == 1)
    }

    @Test("Fast correct answer gets bonus")
    func fastCorrectBonus() {
        let item1 = makeItem(halfLife: 1.0)
        let item2 = makeItem(halfLife: 1.0)

        _ = engine.scheduleNextReview(item: item1, wasCorrect: true, responseTime: 1.0) // fast
        _ = engine.scheduleNextReview(item: item2, wasCorrect: true, responseTime: 10.0) // slow

        #expect(item1.halfLifeDays > item2.halfLifeDays)
    }

    @Test("Correct review schedules further in future than incorrect")
    func correctSchedulesFurther() {
        let item1 = makeItem(halfLife: 1.0)
        let item2 = makeItem(halfLife: 1.0)

        let correctDate = engine.scheduleNextReview(item: item1, wasCorrect: true, responseTime: 5.0)
        let incorrectDate = engine.scheduleNextReview(item: item2, wasCorrect: false, responseTime: 5.0)

        #expect(correctDate > incorrectDate)
    }

    @Test("Half-life has a minimum floor on failure")
    func halfLifeMinimum() {
        let item = makeItem(halfLife: 0.1) // already very short
        _ = engine.scheduleNextReview(item: item, wasCorrect: false, responseTime: 5.0)
        #expect(item.halfLifeDays >= 0.25) // minimum 6 hours
    }

    @Test("Repetitions count increases")
    func repetitionsCount() {
        let item = makeItem()
        #expect(item.repetitions == 0)
        _ = engine.scheduleNextReview(item: item, wasCorrect: true, responseTime: 3.0)
        #expect(item.repetitions == 1)
        _ = engine.scheduleNextReview(item: item, wasCorrect: true, responseTime: 3.0)
        #expect(item.repetitions == 2)
    }

    // MARK: - Due Items

    @Test("getDueItems returns only overdue items")
    func dueItemsFilter() {
        let userId = UUID()
        let due = makeItem(nextReview: Date().addingTimeInterval(-3600))
        due.userId = userId
        let notDue = makeItem(nextReview: Date().addingTimeInterval(86400))
        notDue.userId = userId

        let result = engine.getDueItems(for: userId, from: [due, notDue], limit: 10)
        #expect(result.count == 1)
    }

    @Test("getDueItems respects limit")
    func dueItemsLimit() {
        let userId = UUID()
        var items: [ReviewItem] = []
        for _ in 0..<10 {
            let item = makeItem(nextReview: Date().addingTimeInterval(-3600))
            item.userId = userId
            items.append(item)
        }

        let result = engine.getDueItems(for: userId, from: items, limit: 5)
        #expect(result.count == 5)
    }

    @Test("getDueItems prioritizes lower recall probability")
    func dueItemsPriority() {
        let userId = UUID()
        let moreOverdue = makeItem(halfLife: 1.0, lastReviewed: Date().addingTimeInterval(-172800), nextReview: Date().addingTimeInterval(-86400))
        moreOverdue.userId = userId
        let lessOverdue = makeItem(halfLife: 1.0, lastReviewed: Date().addingTimeInterval(-3600), nextReview: Date().addingTimeInterval(-1800))
        lessOverdue.userId = userId

        let result = engine.getDueItems(for: userId, from: [lessOverdue, moreOverdue], limit: 10)
        #expect(result.first?.id == moreOverdue.id)
    }

    @Test("getDueItems filters by userId")
    func dueItemsUserFilter() {
        let userId1 = UUID()
        let userId2 = UUID()
        let item1 = makeItem(nextReview: Date().addingTimeInterval(-3600))
        item1.userId = userId1
        let item2 = makeItem(nextReview: Date().addingTimeInterval(-3600))
        item2.userId = userId2

        let result = engine.getDueItems(for: userId1, from: [item1, item2], limit: 10)
        #expect(result.count == 1)
        #expect(result.first?.userId == userId1)
    }

    // MARK: - Session Retry

    @Test("getSessionRetryItems returns only incorrect items")
    func sessionRetry() {
        let correct = makeItem()
        let incorrect = makeItem()

        let retries = engine.getSessionRetryItems(from: [
            (item: correct, wasCorrect: true),
            (item: incorrect, wasCorrect: false),
        ])
        #expect(retries.count == 1)
        #expect(retries.first?.id == incorrect.id)
    }
}
