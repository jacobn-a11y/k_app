import XCTest
@testable import HallyuCore

final class ProgressViewModelTests: XCTestCase {

    private let userId = UUID()

    // MARK: - Skill Breakdowns

    func testSkillBreakdownsGroupsByType() {
        let vm = ProgressViewModel()
        let masteries = [
            SkillMastery(userId: userId, skillType: "listening", skillId: "s1", accuracy: 0.8, attempts: 10),
            SkillMastery(userId: userId, skillType: "listening", skillId: "s2", accuracy: 0.6, attempts: 5),
            SkillMastery(userId: userId, skillType: "grammar", skillId: "g1", accuracy: 0.9, attempts: 20),
        ]

        vm.computeSkillBreakdowns(masteries: masteries, userId: userId)

        let listening = vm.skillBreakdowns.first { $0.skillType == "listening" }
        XCTAssertNotNil(listening)
        XCTAssertEqual(listening!.accuracy, 0.7, accuracy: 0.01) // (0.8 + 0.6) / 2
        XCTAssertEqual(listening!.attempts, 15)

        let grammar = vm.skillBreakdowns.first { $0.skillType == "grammar" }
        XCTAssertNotNil(grammar)
        XCTAssertEqual(grammar!.accuracy, 0.9, accuracy: 0.01)
    }

    func testSkillBreakdownsShowsZeroForUnpracticed() {
        let vm = ProgressViewModel()
        vm.computeSkillBreakdowns(masteries: [], userId: userId)

        XCTAssertFalse(vm.skillBreakdowns.isEmpty)
        for skill in vm.skillBreakdowns {
            XCTAssertEqual(skill.accuracy, 0.0)
            XCTAssertEqual(skill.attempts, 0)
        }
    }

    func testSkillBreakdownsFiltersToUser() {
        let vm = ProgressViewModel()
        let otherUser = UUID()
        let masteries = [
            SkillMastery(userId: userId, skillType: "listening", skillId: "s1", accuracy: 0.8, attempts: 10),
            SkillMastery(userId: otherUser, skillType: "listening", skillId: "s2", accuracy: 0.2, attempts: 5),
        ]

        vm.computeSkillBreakdowns(masteries: masteries, userId: userId)

        let listening = vm.skillBreakdowns.first { $0.skillType == "listening" }
        XCTAssertEqual(listening!.accuracy, 0.8, accuracy: 0.01)
    }

    // MARK: - Vocabulary Growth

    func testVocabularyGrowthCumulativeCount() {
        let vm = ProgressViewModel()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let items = [
            ReviewItem(userId: userId, itemType: "vocabulary", itemId: UUID(), createdAt: calendar.date(byAdding: .day, value: -10, to: today)!),
            ReviewItem(userId: userId, itemType: "vocabulary", itemId: UUID(), createdAt: calendar.date(byAdding: .day, value: -5, to: today)!),
            ReviewItem(userId: userId, itemType: "vocabulary", itemId: UUID(), createdAt: calendar.date(byAdding: .day, value: -1, to: today)!),
        ]

        vm.computeVocabularyGrowth(reviewItems: items, userId: userId)

        XCTAssertEqual(vm.totalVocabularyCount, 3)
        XCTAssertEqual(vm.vocabularyGrowth.count, 30)
        // Last point should have all 3
        XCTAssertEqual(vm.vocabularyGrowth.last?.count, 3)
    }

    func testVocabularyGrowthEmptyWhenNoItems() {
        let vm = ProgressViewModel()
        vm.computeVocabularyGrowth(reviewItems: [], userId: userId)

        XCTAssertEqual(vm.totalVocabularyCount, 0)
        XCTAssertTrue(vm.vocabularyGrowth.isEmpty)
    }

    func testVocabularyGrowthIgnoresNonVocabItems() {
        let vm = ProgressViewModel()
        let items = [
            ReviewItem(userId: userId, itemType: "grammar", itemId: UUID()),
            ReviewItem(userId: userId, itemType: "hangul", itemId: UUID()),
        ]

        vm.computeVocabularyGrowth(reviewItems: items, userId: userId)
        XCTAssertEqual(vm.totalVocabularyCount, 0)
    }

    // MARK: - Daily Study Minutes

    func testDailyStudyMinutesAggregates() {
        let vm = ProgressViewModel()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let sessions = [
            StudySession(userId: userId, sessionType: "review", durationSeconds: 600, startedAt: today, completedAt: Date()),
            StudySession(userId: userId, sessionType: "media", durationSeconds: 900, startedAt: today, completedAt: Date()),
        ]

        vm.computeDailyStudyMinutes(sessions: sessions, userId: userId)

        XCTAssertEqual(vm.dailyStudyMinutes.count, 14)
        // Today should have 25 minutes (600 + 900 = 1500s = 25min)
        let todayPoint = vm.dailyStudyMinutes.last!
        XCTAssertEqual(todayPoint.minutes, 25)
    }

    func testDailyStudyMinutesIgnoresIncompleteSessions() {
        let vm = ProgressViewModel()
        let sessions = [
            StudySession(userId: userId, sessionType: "review", durationSeconds: 600, startedAt: Date(), completedAt: nil),
        ]

        vm.computeDailyStudyMinutes(sessions: sessions, userId: userId)
        XCTAssertEqual(vm.dailyStudyMinutes.last!.minutes, 0)
    }

    // MARK: - Accuracy Trends

    func testAccuracyTrendsCalculatesCorrectly() {
        let vm = ProgressViewModel()
        let today = Calendar.current.startOfDay(for: Date())

        let sessions = [
            StudySession(userId: userId, sessionType: "review", durationSeconds: 300, itemsStudied: 10, itemsCorrect: 8, startedAt: today, completedAt: Date()),
            StudySession(userId: userId, sessionType: "review", durationSeconds: 300, itemsStudied: 10, itemsCorrect: 6, startedAt: today, completedAt: Date()),
        ]

        vm.computeAccuracyTrends(sessions: sessions, userId: userId)

        XCTAssertEqual(vm.accuracyTrends.count, 14)
        // Today: 14 correct / 20 studied = 0.7
        let todayAccuracy = vm.accuracyTrends.last!.accuracy
        XCTAssertEqual(todayAccuracy, 0.7, accuracy: 0.01)
    }

    func testAccuracyTrendsZeroWhenNoItems() {
        let vm = ProgressViewModel()
        let today = Calendar.current.startOfDay(for: Date())

        let sessions = [
            StudySession(userId: userId, sessionType: "review", durationSeconds: 300, itemsStudied: 0, itemsCorrect: 0, startedAt: today, completedAt: Date()),
        ]

        vm.computeAccuracyTrends(sessions: sessions, userId: userId)
        XCTAssertEqual(vm.accuracyTrends.last!.accuracy, 0.0)
    }

    // MARK: - Total Study Time

    func testTotalStudyTimeAggregates() {
        let vm = ProgressViewModel()
        let sessions = [
            StudySession(userId: userId, sessionType: "review", durationSeconds: 600, completedAt: Date()),
            StudySession(userId: userId, sessionType: "media", durationSeconds: 1200, completedAt: Date()),
            StudySession(userId: userId, sessionType: "hangul", durationSeconds: 300, completedAt: nil), // incomplete
        ]

        vm.computeTotalStudyTime(sessions: sessions, userId: userId)
        XCTAssertEqual(vm.totalStudyMinutes, 30) // (600 + 1200) / 60
    }

    // MARK: - Streak

    func testStreakCountsConsecutiveDays() {
        let vm = ProgressViewModel()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let sessions = (0..<5).map { dayOffset -> StudySession in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            return StudySession(userId: userId, sessionType: "review", durationSeconds: 300, startedAt: date, completedAt: date)
        }

        let streak = vm.computeStreak(from: sessions, userId: userId)
        XCTAssertEqual(streak, 5)
    }

    func testStreakBreaksOnMissedDay() {
        let vm = ProgressViewModel()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let sessions = [
            StudySession(userId: userId, sessionType: "review", durationSeconds: 300, startedAt: today, completedAt: today),
            // Skip yesterday
            StudySession(userId: userId, sessionType: "review", durationSeconds: 300,
                         startedAt: calendar.date(byAdding: .day, value: -2, to: today)!,
                         completedAt: calendar.date(byAdding: .day, value: -2, to: today)!),
        ]

        let streak = vm.computeStreak(from: sessions, userId: userId)
        XCTAssertEqual(streak, 1)
    }

    func testStreakZeroWhenNoSessions() {
        let vm = ProgressViewModel()
        let streak = vm.computeStreak(from: [], userId: userId)
        XCTAssertEqual(streak, 0)
    }

    // MARK: - Full Load

    func testLoadProgressSetsAllFields() {
        let vm = ProgressViewModel()
        let profile = LearnerProfile(userId: userId, cefrLevel: "A2", dailyGoalMinutes: 20)

        let masteries = [
            SkillMastery(userId: userId, skillType: "listening", skillId: "s1", accuracy: 0.7, attempts: 5),
        ]
        let sessions = [
            StudySession(userId: userId, sessionType: "review", durationSeconds: 600, itemsStudied: 10, itemsCorrect: 8, startedAt: Date(), completedAt: Date()),
        ]
        let reviewItems = [
            ReviewItem(userId: userId, itemType: "vocabulary", itemId: UUID()),
        ]

        vm.loadProgress(profile: profile, skillMasteries: masteries, studySessions: sessions, reviewItems: reviewItems)

        XCTAssertEqual(vm.cefrLevel, .a2)
        XCTAssertFalse(vm.skillBreakdowns.isEmpty)
        XCTAssertEqual(vm.totalReviewItems, 1)
        XCTAssertFalse(vm.isLoading)
    }
}
