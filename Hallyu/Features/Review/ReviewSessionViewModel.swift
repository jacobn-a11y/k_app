import Foundation
import Observation

@MainActor
@Observable
final class ReviewSessionViewModel {

    // MARK: - State

    private(set) var items: [ReviewItem]
    private let originalItemCount: Int
    private(set) var currentIndex: Int = 0
    private(set) var isShowingAnswer: Bool = false
    private(set) var isSessionComplete: Bool = false
    private(set) var sessionResults: [SessionResult] = []
    private(set) var startTime: Date = Date()
    private(set) var currentItemStartTime: Date = Date()

    let srsEngine: SRSEngineProtocol
    let learnerModel: LearnerModelServiceProtocol

    // MARK: - Types

    struct SessionResult: Equatable {
        let itemId: UUID
        let wasCorrect: Bool
        let responseTime: TimeInterval
    }

    struct SessionStats: Equatable {
        let totalItems: Int
        let correctCount: Int
        let incorrectCount: Int
        let averageResponseTime: TimeInterval
        let accuracy: Double
        let streak: Int
        let totalDuration: TimeInterval
    }

    // MARK: - Computed Properties

    var currentItem: ReviewItem? {
        guard currentIndex < items.count else { return nil }
        return items[currentIndex]
    }

    var progress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(currentIndex) / Double(items.count)
    }

    var remainingCount: Int {
        max(0, items.count - currentIndex)
    }

    var correctCount: Int {
        sessionResults.filter { $0.wasCorrect }.count
    }

    var incorrectCount: Int {
        sessionResults.filter { !$0.wasCorrect }.count
    }

    var currentStreak: Int {
        var streak = 0
        for result in sessionResults.reversed() {
            if result.wasCorrect {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    var bestStreak: Int {
        var best = 0
        var current = 0
        for result in sessionResults {
            if result.wasCorrect {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }

    // MARK: - Init

    init(items: [ReviewItem], srsEngine: SRSEngineProtocol, learnerModel: LearnerModelServiceProtocol) {
        self.items = items
        self.originalItemCount = items.count
        self.srsEngine = srsEngine
        self.learnerModel = learnerModel
        self.startTime = Date()
        self.currentItemStartTime = Date()
    }

    // MARK: - Actions

    func revealAnswer() {
        isShowingAnswer = true
    }

    func submitAnswer(wasCorrect: Bool) {
        guard let item = currentItem else { return }

        let responseTime = Date().timeIntervalSince(currentItemStartTime)

        // Record result
        let result = SessionResult(
            itemId: item.id,
            wasCorrect: wasCorrect,
            responseTime: responseTime
        )
        sessionResults.append(result)

        // Update SRS scheduling
        _ = srsEngine.scheduleNextReview(item: item, wasCorrect: wasCorrect, responseTime: responseTime)

        // Update learner model
        // Note: item.userId is trusted here as items are filtered per-user at query time
        Task {
            do {
                try await learnerModel.updateMastery(
                    userId: item.userId,
                    skillType: item.itemType,
                    skillId: item.itemId.uuidString,
                    wasCorrect: wasCorrect,
                    responseTime: responseTime
                )
            } catch {
                // Log but don't crash — mastery update is non-blocking
                print("[ReviewSession] Failed to update mastery: \(error.localizedDescription)")
            }
        }

        // Advance
        isShowingAnswer = false
        currentIndex += 1
        currentItemStartTime = Date()

        if currentIndex >= items.count {
            // Check for retry items (items answered incorrectly)
            let retryItems = srsEngine.getSessionRetryItems(
                from: sessionResults.enumerated().compactMap { index, result in
                    guard index < items.count else { return nil }
                    return (item: items[index], wasCorrect: result.wasCorrect)
                }
            )

            if !retryItems.isEmpty && sessionResults.count < originalItemCount * 2 {
                // Add retry items to the end (capped at 2x original to avoid infinite loops)
                items.append(contentsOf: retryItems)
            } else {
                isSessionComplete = true
            }
        }
    }

    func computeStats() -> SessionStats {
        let totalDuration = Date().timeIntervalSince(startTime)
        let avgResponseTime = sessionResults.isEmpty
            ? 0
            : sessionResults.reduce(0.0) { $0 + $1.responseTime } / Double(sessionResults.count)

        return SessionStats(
            totalItems: sessionResults.count,
            correctCount: correctCount,
            incorrectCount: incorrectCount,
            averageResponseTime: avgResponseTime,
            accuracy: sessionResults.isEmpty ? 0 : Double(correctCount) / Double(sessionResults.count),
            streak: bestStreak,
            totalDuration: totalDuration
        )
    }

    func skipItem() {
        guard currentIndex < items.count else { return }
        isShowingAnswer = false
        currentIndex += 1
        currentItemStartTime = Date()

        if currentIndex >= items.count {
            isSessionComplete = true
        }
    }
}
