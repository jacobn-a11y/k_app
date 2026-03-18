import Testing
import Foundation
@testable import HallyuCore

@Suite("ReviewSessionViewModel Tests")
struct ReviewSessionViewModelTests {

    private let userId = UUID()

    private func makeItems(count: Int = 5) -> [ReviewItem] {
        (0..<count).map { _ in
            ReviewItem(
                userId: userId,
                itemType: "hangul_recognition",
                itemId: UUID(),
                halfLifeDays: 1.0,
                nextReviewAt: Date().addingTimeInterval(-3600)
            )
        }
    }

    private func makeViewModel(itemCount: Int = 5) -> ReviewSessionViewModel {
        ReviewSessionViewModel(
            items: makeItems(count: itemCount),
            srsEngine: MockSRSEngine(),
            learnerModel: MockLearnerModelService()
        )
    }

    // MARK: - Initialization

    @Test("ViewModel initializes with items and correct state")
    func initialization() {
        let vm = makeViewModel()
        #expect(vm.currentIndex == 0)
        #expect(vm.isShowingAnswer == false)
        #expect(vm.isSessionComplete == false)
        #expect(vm.sessionResults.isEmpty)
    }

    @Test("Current item returns first item initially")
    func currentItemInitial() {
        let vm = makeViewModel()
        #expect(vm.currentItem != nil)
        #expect(vm.currentItem?.id == vm.items[0].id)
    }

    @Test("Empty items results in nil current item")
    func emptyItems() {
        let vm = ReviewSessionViewModel(
            items: [],
            srsEngine: MockSRSEngine(),
            learnerModel: MockLearnerModelService()
        )
        #expect(vm.currentItem == nil)
    }

    // MARK: - Reveal & Submit

    @Test("revealAnswer sets isShowingAnswer to true")
    func revealAnswer() {
        let vm = makeViewModel()
        vm.revealAnswer()
        #expect(vm.isShowingAnswer == true)
    }

    @Test("submitAnswer advances to next item")
    func submitAdvances() {
        let vm = makeViewModel()
        let firstItem = vm.currentItem
        vm.submitAnswer(wasCorrect: true)
        #expect(vm.currentIndex == 1)
        #expect(vm.currentItem?.id != firstItem?.id)
        #expect(vm.isShowingAnswer == false)
    }

    @Test("submitAnswer records result")
    func submitRecordsResult() {
        let vm = makeViewModel()
        let itemId = vm.currentItem!.id
        vm.submitAnswer(wasCorrect: true)
        #expect(vm.sessionResults.count == 1)
        #expect(vm.sessionResults[0].itemId == itemId)
        #expect(vm.sessionResults[0].wasCorrect == true)
    }

    @Test("Correct and incorrect counts are tracked")
    func correctIncorrectCounts() {
        let vm = makeViewModel()
        vm.submitAnswer(wasCorrect: true)
        vm.submitAnswer(wasCorrect: false)
        vm.submitAnswer(wasCorrect: true)
        #expect(vm.correctCount == 2)
        #expect(vm.incorrectCount == 1)
    }

    // MARK: - Session Completion

    @Test("Session completes after all items reviewed correctly")
    func sessionCompletesAllCorrect() {
        let vm = makeViewModel(itemCount: 3)
        vm.submitAnswer(wasCorrect: true)
        vm.submitAnswer(wasCorrect: true)
        vm.submitAnswer(wasCorrect: true)
        #expect(vm.isSessionComplete == true)
    }

    // MARK: - Progress

    @Test("Progress starts at 0")
    func progressStart() {
        let vm = makeViewModel()
        #expect(vm.progress == 0.0)
    }

    @Test("Progress increases with each answer")
    func progressIncreases() {
        let vm = makeViewModel(itemCount: 4)
        vm.submitAnswer(wasCorrect: true)
        #expect(vm.progress == 0.25)
        vm.submitAnswer(wasCorrect: true)
        #expect(vm.progress == 0.5)
    }

    @Test("Remaining count decreases")
    func remainingCount() {
        let vm = makeViewModel(itemCount: 3)
        #expect(vm.remainingCount == 3)
        vm.submitAnswer(wasCorrect: true)
        #expect(vm.remainingCount == 2)
    }

    // MARK: - Streaks

    @Test("Current streak counts consecutive correct answers")
    func currentStreak() {
        let vm = makeViewModel(itemCount: 5)
        vm.submitAnswer(wasCorrect: false)
        vm.submitAnswer(wasCorrect: true)
        vm.submitAnswer(wasCorrect: true)
        vm.submitAnswer(wasCorrect: true)
        #expect(vm.currentStreak == 3)
    }

    @Test("Current streak resets on incorrect answer")
    func streakResets() {
        let vm = makeViewModel(itemCount: 5)
        vm.submitAnswer(wasCorrect: true)
        vm.submitAnswer(wasCorrect: true)
        vm.submitAnswer(wasCorrect: false)
        #expect(vm.currentStreak == 0)
    }

    @Test("Best streak tracks highest streak")
    func bestStreak() {
        let vm = makeViewModel(itemCount: 5)
        vm.submitAnswer(wasCorrect: true)
        vm.submitAnswer(wasCorrect: true)
        vm.submitAnswer(wasCorrect: false)
        vm.submitAnswer(wasCorrect: true)
        #expect(vm.bestStreak == 2)
    }

    // MARK: - Skip

    @Test("Skip advances without recording a result")
    func skipItem() {
        let vm = makeViewModel(itemCount: 3)
        vm.skipItem()
        #expect(vm.currentIndex == 1)
        #expect(vm.sessionResults.isEmpty)
    }

    @Test("Skip completes session when at last item")
    func skipCompletes() {
        let vm = makeViewModel(itemCount: 1)
        vm.skipItem()
        #expect(vm.isSessionComplete == true)
    }

    // MARK: - Stats

    @Test("computeStats returns correct values")
    func computeStats() {
        let vm = makeViewModel(itemCount: 3)
        vm.submitAnswer(wasCorrect: true)
        vm.submitAnswer(wasCorrect: false)
        vm.submitAnswer(wasCorrect: true)

        let stats = vm.computeStats()
        #expect(stats.totalItems == 3)
        #expect(stats.correctCount == 2)
        #expect(stats.incorrectCount == 1)
        #expect(abs(stats.accuracy - (2.0 / 3.0)) < 0.01)
        #expect(stats.streak == 1) // best streak is 1 (first correct, then fail resets)
    }

    @Test("Stats with no items returns zeros")
    func emptyStats() {
        let vm = makeViewModel(itemCount: 0)
        let stats = vm.computeStats()
        #expect(stats.totalItems == 0)
        #expect(stats.accuracy == 0)
        #expect(stats.averageResponseTime == 0)
    }
}

// MARK: - Mock SRS Engine for Review Tests

private final class MockSRSEngine: SRSEngineProtocol {
    func predictRecallProbability(item: ReviewItem, at date: Date) -> Double { 0.5 }

    func scheduleNextReview(item: ReviewItem, wasCorrect: Bool, responseTime: TimeInterval) -> Date {
        Date().addingTimeInterval(wasCorrect ? 86400 : 3600)
    }

    func getDueItems(for userId: UUID, from items: [ReviewItem], limit: Int) -> [ReviewItem] {
        Array(items.prefix(limit))
    }

    func getSessionRetryItems(from sessionItems: [(item: ReviewItem, wasCorrect: Bool)]) -> [ReviewItem] {
        sessionItems.filter { !$0.wasCorrect }.map { $0.item }
    }
}
