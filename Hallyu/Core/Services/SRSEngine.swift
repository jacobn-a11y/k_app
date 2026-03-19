import Foundation

/// Exponential decay SRS engine with half-life scheduling.
///
/// Uses P(recall) = 2^(-elapsed / halfLife) to predict memory strength.
/// The half-life grows on correct answers (multiplied by `growthFactor`) and
/// shrinks on incorrect answers (multiplied by `decayFactor`). Fast correct
/// responses receive an additional bonus, nudging the next review further out.
final class SRSEngine: SRSEngineProtocol, @unchecked Sendable {
    // Configuration
    let initialHalfLife: Double = 1.0  // days
    let growthFactor: Double = 2.0     // half-life multiplier on correct answer
    let decayFactor: Double = 0.5      // half-life multiplier on incorrect answer
    let speedBonus: Double = 1.1       // multiplier for fast correct answers
    let speedThreshold: TimeInterval = 3.0 // seconds — responses faster than this are "fast"

    /// Predict the probability that the learner still remembers this item.
    /// Uses exponential decay: P(recall) = 2^(-elapsed / halfLife)
    func predictRecallProbability(item: ReviewItem, at date: Date) -> Double {
        guard let lastReviewed = item.lastReviewedAt else {
            // Never reviewed — treat as due
            return 0.0
        }

        let elapsedDays = date.timeIntervalSince(lastReviewed) / 86400.0
        guard elapsedDays > 0, item.halfLifeDays > 0 else { return 1.0 }

        return pow(2.0, -elapsedDays / item.halfLifeDays)
    }

    /// Schedule the next review based on whether the answer was correct and how fast.
    func scheduleNextReview(item: ReviewItem, wasCorrect: Bool, responseTime: TimeInterval) -> Date {
        var newHalfLife: Double

        if wasCorrect {
            newHalfLife = item.halfLifeDays * growthFactor
            // Apply speed bonus for fast correct answers
            if responseTime < speedThreshold {
                newHalfLife *= speedBonus
            }
        } else {
            newHalfLife = max(item.halfLifeDays * decayFactor, 0.25) // minimum 6 hours
        }

        // Update the item's properties
        item.halfLifeDays = newHalfLife
        item.repetitions += 1
        item.lastReviewedAt = Date()

        if wasCorrect {
            item.correctCount += 1
            item.intervalDays = newHalfLife
        } else {
            item.incorrectCount += 1
            item.intervalDays = max(newHalfLife * 0.5, 0.04) // re-present sooner on failure (~1hr min)
        }

        let nextReview = Date().addingTimeInterval(item.intervalDays * 86400.0)
        item.nextReviewAt = nextReview
        return nextReview
    }

    /// Get items due for review, sorted by priority (most overdue first).
    func getDueItems(for userId: UUID, from items: [ReviewItem], limit: Int) -> [ReviewItem] {
        let now = Date()

        let dueItems = items
            .filter { $0.userId == userId && $0.nextReviewAt <= now }
            .sorted { a, b in
                // Priority: lower recall probability = more urgent
                let recallA = predictRecallProbability(item: a, at: now)
                let recallB = predictRecallProbability(item: b, at: now)
                return recallA < recallB
            }

        return Array(dueItems.prefix(limit))
    }

    /// Get items that were answered incorrectly in the current session (for within-session re-presentation).
    func getSessionRetryItems(from sessionItems: [(item: ReviewItem, wasCorrect: Bool)]) -> [ReviewItem] {
        sessionItems
            .filter { !$0.wasCorrect }
            .map { $0.item }
    }
}
