import Testing
import Foundation
@testable import HallyuCore

@Suite("DailyPlanViewModel Tests")
struct DailyPlanViewModelTests {

    private let userId = UUID()

    private func makeViewModel(
        planGenerator: PlanGeneratorServiceProtocol = MockPlanGenerator()
    ) -> DailyPlanViewModel {
        DailyPlanViewModel(
            planGenerator: planGenerator,
            srsEngine: MockSRSEngine(),
            learnerModel: MockLearnerModelService()
        )
    }

    private func makeProfile(userId: UUID? = nil, dailyGoalMinutes: Int = 15) -> LearnerProfile {
        let resolvedUserId = userId ?? self.userId
        LearnerProfile(
            userId: resolvedUserId,
            cefrLevel: "A1",
            hangulCompleted: true,
            dailyGoalMinutes: dailyGoalMinutes
        )
    }

    // MARK: - Initialization

    @Test("ViewModel starts with nil plan")
    func initialState() {
        let vm = makeViewModel()
        #expect(vm.plan == nil)
        #expect(vm.streak == 0)
        #expect(vm.isLoading == false)
        #expect(vm.completionProgress == 0)
    }

    // MARK: - Load Plan

    @Test("loadPlan generates a plan")
    func loadPlan() {
        let vm = makeViewModel()
        vm.loadPlan(
            profile: makeProfile(),
            reviewItems: [],
            mediaContent: [],
            skillMasteries: [],
            studySessions: []
        )
        #expect(vm.plan != nil)
        #expect(vm.isLoading == false)
    }

    @Test("loadPlan counts overdue review items")
    func overdueCount() {
        let vm = makeViewModel()
        let dueItems = (0..<3).map { _ in
            ReviewItem(
                userId: userId,
                itemType: "vocabulary",
                itemId: UUID(),
                nextReviewAt: Date().addingTimeInterval(-3600)
            )
        }
        vm.loadPlan(
            profile: makeProfile(),
            reviewItems: dueItems,
            mediaContent: [],
            skillMasteries: [],
            studySessions: []
        )
        #expect(vm.overdueReviewCount == 3)
    }

    @Test("loadPlan scopes inputs to the active user")
    func loadPlanScopesInputs() {
        let generator = RecordingPlanGenerator()
        let vm = makeViewModel(planGenerator: generator)
        let otherUser = UUID()

        let currentProfile = makeProfile(userId: userId)
        let mixedReviewItems = [
            ReviewItem(userId: userId, itemType: "vocabulary", itemId: UUID(), nextReviewAt: Date().addingTimeInterval(-3600)),
            ReviewItem(userId: otherUser, itemType: "vocabulary", itemId: UUID(), nextReviewAt: Date().addingTimeInterval(-3600)),
        ]
        let mixedMasteries = [
            SkillMastery(userId: userId, skillType: "reading", skillId: "reading_1", accuracy: 0.8),
            SkillMastery(userId: otherUser, skillType: "reading", skillId: "reading_2", accuracy: 0.1),
        ]
        let mixedSessions = [
            StudySession(userId: userId, sessionType: "review", durationSeconds: 600, startedAt: Date(), completedAt: Date()),
            StudySession(userId: otherUser, sessionType: "review", durationSeconds: 600, startedAt: Date(), completedAt: Date()),
        ]

        vm.loadPlan(
            profile: currentProfile,
            reviewItems: mixedReviewItems,
            mediaContent: [],
            skillMasteries: mixedMasteries,
            studySessions: mixedSessions
        )

        #expect(generator.lastDueReviewCount == 1)
        #expect(generator.lastSkillMasteryCount == 1)
        #expect(generator.lastSessionCount == 1)
        #expect(vm.overdueReviewCount == 1)
        #expect(vm.streak == 1)
    }

    // MARK: - Complete Activity

    @Test("completeActivity marks activity as done")
    func completeActivity() {
        let vm = makeViewModel()
        vm.loadPlan(
            profile: makeProfile(),
            reviewItems: [],
            mediaContent: [],
            skillMasteries: [],
            studySessions: []
        )

        guard let firstId = vm.plan?.activities.first?.id else {
            Issue.record("Plan should have activities")
            return
        }

        vm.completeActivity(id: firstId)

        let completed = vm.plan?.activities.first { $0.id == firstId }
        #expect(completed?.isCompleted == true)
    }

    @Test("Completion progress updates after completing activity")
    func progressUpdates() {
        let vm = makeViewModel()
        vm.loadPlan(
            profile: makeProfile(),
            reviewItems: [],
            mediaContent: [],
            skillMasteries: [],
            studySessions: []
        )

        let initialProgress = vm.completionProgress

        if let firstId = vm.plan?.activities.first?.id {
            vm.completeActivity(id: firstId)
            #expect(vm.completionProgress > initialProgress)
        }
    }

    @Test("isPlanComplete returns true when all activities done")
    func planComplete() {
        let vm = makeViewModel()
        vm.loadPlan(
            profile: makeProfile(),
            reviewItems: [],
            mediaContent: [],
            skillMasteries: [],
            studySessions: []
        )

        guard let plan = vm.plan else {
            Issue.record("Plan should exist")
            return
        }

        for activity in plan.activities {
            vm.completeActivity(id: activity.id)
        }

        #expect(vm.isPlanComplete == true)
    }

    // MARK: - Next Activity

    @Test("nextActivity returns first incomplete activity")
    func nextActivity() {
        let vm = makeViewModel()
        vm.loadPlan(
            profile: makeProfile(),
            reviewItems: [],
            mediaContent: [],
            skillMasteries: [],
            studySessions: []
        )

        let first = vm.plan?.activities.first
        #expect(vm.nextActivity?.id == first?.id)

        if let firstId = first?.id {
            vm.completeActivity(id: firstId)
            let second = vm.plan?.activities.dropFirst().first
            #expect(vm.nextActivity?.id == second?.id)
        }
    }

    // MARK: - Streak Calculation

    @Test("Streak is 0 with no sessions")
    func emptyStreak() {
        let vm = makeViewModel()
        let streak = vm.computeStreak(from: [], userId: userId)
        #expect(streak == 0)
    }

    @Test("Streak counts consecutive days including today")
    func consecutiveStreakWithToday() {
        let vm = makeViewModel()
        let calendar = Calendar.current
        let today = Date()
        let sessions = (0..<3).map { i in
            StudySession(
                userId: userId,
                sessionType: "review",
                startedAt: calendar.date(byAdding: .day, value: -i, to: today)!,
                completedAt: calendar.date(byAdding: .day, value: -i, to: today)!
            )
        }
        let streak = vm.computeStreak(from: sessions, userId: userId)
        #expect(streak == 3)
    }

    @Test("Streak counts from yesterday if no session today")
    func streakFromYesterday() {
        let vm = makeViewModel()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let sessions = (0..<2).map { i in
            StudySession(
                userId: userId,
                sessionType: "review",
                startedAt: calendar.date(byAdding: .day, value: -i, to: yesterday)!,
                completedAt: calendar.date(byAdding: .day, value: -i, to: yesterday)!
            )
        }
        let streak = vm.computeStreak(from: sessions, userId: userId)
        #expect(streak == 2)
    }

    @Test("Streak breaks when a day is missed")
    func streakBreaks() {
        let vm = makeViewModel()
        let calendar = Calendar.current
        let today = Date()
        let sessions = [
            StudySession(
                userId: userId,
                sessionType: "review",
                startedAt: today,
                completedAt: today
            ),
            // Skip yesterday
            StudySession(
                userId: userId,
                sessionType: "review",
                startedAt: calendar.date(byAdding: .day, value: -2, to: today)!,
                completedAt: calendar.date(byAdding: .day, value: -2, to: today)!
            ),
        ]
        let streak = vm.computeStreak(from: sessions, userId: userId)
        #expect(streak == 1)
    }

    @Test("Streak ignores other users' sessions")
    func streakPerUser() {
        let vm = makeViewModel()
        let otherUser = UUID()
        let sessions = [
            StudySession(
                userId: otherUser,
                sessionType: "review",
                startedAt: Date(),
                completedAt: Date()
            ),
        ]
        let streak = vm.computeStreak(from: sessions, userId: userId)
        #expect(streak == 0)
    }

    // MARK: - Greeting

    @Test("Greeting varies by time of day")
    func greetingExists() {
        let vm = makeViewModel()
        let greeting = vm.greeting
        #expect(
            greeting == "Good morning" ||
            greeting == "Good afternoon" ||
            greeting == "Good evening"
        )
    }

    // MARK: - Computed Properties with No Plan

    @Test("Computed properties handle nil plan gracefully")
    func nilPlanDefaults() {
        let vm = makeViewModel()
        #expect(vm.completionProgress == 0)
        #expect(vm.completedActivities == 0)
        #expect(vm.totalActivities == 0)
        #expect(vm.nextActivity == nil)
        #expect(vm.isPlanComplete == false)
    }
}

// MARK: - Mocks

private final class MockPlanGenerator: PlanGeneratorServiceProtocol, @unchecked Sendable {
    func generatePlan(
        profile: LearnerProfile,
        dueReviewItems: [ReviewItem],
        availableMedia: [MediaContent],
        skillMasteries: [SkillMastery],
        todaySessions: [StudySession]
    ) -> DailyPlan {
        let activities = [
            PlanActivity(
                type: .srsReview,
                title: "Review",
                subtitle: "Review items",
                estimatedMinutes: 5,
                reviewItemCount: 3
            ),
            PlanActivity(
                type: .mediaLesson,
                title: "Media Lesson",
                subtitle: "Watch a clip",
                estimatedMinutes: 8
            ),
        ]
        return DailyPlan(
            activities: activities,
            totalMinutes: 13,
            goalMinutes: profile.dailyGoalMinutes,
            date: Date()
        )
    }
}

private final class MockSRSEngine: SRSEngineProtocol, @unchecked Sendable {
    func predictRecallProbability(item: ReviewItem, at date: Date) -> Double { 0.5 }
    func scheduleNextReview(item: ReviewItem, wasCorrect: Bool, responseTime: TimeInterval) -> Date {
        Date().addingTimeInterval(86400)
    }
    func getDueItems(for userId: UUID, from items: [ReviewItem], limit: Int) -> [ReviewItem] {
        Array(items.filter { $0.nextReviewAt <= Date() }.prefix(limit))
    }
    func getSessionRetryItems(from sessionItems: [(item: ReviewItem, wasCorrect: Bool)]) -> [ReviewItem] {
        sessionItems.filter { !$0.wasCorrect }.map { $0.item }
    }
}

private final class RecordingPlanGenerator: PlanGeneratorServiceProtocol, @unchecked Sendable {
    private(set) var lastDueReviewCount: Int?
    private(set) var lastSkillMasteryCount: Int?
    private(set) var lastSessionCount: Int?

    func generatePlan(
        profile: LearnerProfile,
        dueReviewItems: [ReviewItem],
        availableMedia: [MediaContent],
        skillMasteries: [SkillMastery],
        todaySessions: [StudySession]
    ) -> DailyPlan {
        lastDueReviewCount = dueReviewItems.count
        lastSkillMasteryCount = skillMasteries.count
        lastSessionCount = todaySessions.count

        let activities = [
            PlanActivity(
                type: .srsReview,
                title: "Review",
                subtitle: "Review items",
                estimatedMinutes: 5,
                reviewItemCount: dueReviewItems.count
            )
        ]

        return DailyPlan(
            activities: activities,
            totalMinutes: 5,
            goalMinutes: profile.dailyGoalMinutes,
            date: Date()
        )
    }
}
