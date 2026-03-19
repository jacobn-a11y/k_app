import Foundation
import Observation
import SwiftData

@Observable
final class DailyPlanViewModel {

    // MARK: - State

    private(set) var plan: DailyPlan?
    private(set) var streak: Int = 0
    private(set) var isLoading: Bool = false
    private(set) var overdueReviewCount: Int = 0

    let planGenerator: PlanGeneratorServiceProtocol
    let srsEngine: SRSEngineProtocol
    let learnerModel: LearnerModelServiceProtocol

    // MARK: - Computed Properties

    var completionProgress: Double {
        plan?.completionProgress ?? 0
    }

    var completedActivities: Int {
        plan?.activities.filter { $0.isCompleted }.count ?? 0
    }

    var totalActivities: Int {
        plan?.activities.count ?? 0
    }

    var nextActivity: PlanActivity? {
        plan?.activities.first { !$0.isCompleted }
    }

    var isPlanComplete: Bool {
        plan?.isComplete ?? false
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    // MARK: - Init

    init(
        planGenerator: PlanGeneratorServiceProtocol,
        srsEngine: SRSEngineProtocol,
        learnerModel: LearnerModelServiceProtocol
    ) {
        self.planGenerator = planGenerator
        self.srsEngine = srsEngine
        self.learnerModel = learnerModel
    }

    // MARK: - Actions

    func loadPlan(
        profile: LearnerProfile,
        reviewItems: [ReviewItem],
        mediaContent: [MediaContent],
        skillMasteries: [SkillMastery],
        studySessions: [StudySession]
    ) {
        isLoading = true

        let dueItems = srsEngine.getDueItems(
            for: profile.userId,
            from: reviewItems,
            limit: 50
        )
        overdueReviewCount = dueItems.count

        let todaySessions = filterTodaySessions(studySessions)

        plan = planGenerator.generatePlan(
            profile: profile,
            dueReviewItems: dueItems,
            availableMedia: mediaContent,
            skillMasteries: skillMasteries,
            todaySessions: todaySessions
        )

        streak = computeStreak(from: studySessions, userId: profile.userId)

        isLoading = false
    }

    func completeActivity(id: UUID) {
        guard var currentPlan = plan else { return }
        var updatedActivities = currentPlan.activities
        guard let index = updatedActivities.firstIndex(where: { $0.id == id }) else { return }
        updatedActivities[index].isCompleted = true

        plan = DailyPlan(
            activities: updatedActivities,
            totalMinutes: currentPlan.totalMinutes,
            goalMinutes: currentPlan.goalMinutes,
            date: currentPlan.date
        )
    }

    // MARK: - Streak Calculation

    func computeStreak(from sessions: [StudySession], userId: UUID) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get unique days with completed sessions, sorted descending
        let completedDays = Set(
            sessions
                .filter { $0.userId == userId && $0.completedAt != nil }
                .map { calendar.startOfDay(for: $0.startedAt) }
        )
        .sorted(by: >)

        guard !completedDays.isEmpty else { return 0 }

        var streak = 0
        // Start checking from today or yesterday
        var checkDate = today

        // If today has no sessions yet, start from yesterday
        if !completedDays.contains(today) {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if completedDays.contains(yesterday) {
                checkDate = yesterday
            } else {
                return 0
            }
        }

        // Count consecutive days
        while completedDays.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        return streak
    }

    // MARK: - Helpers

    private func filterTodaySessions(_ sessions: [StudySession]) -> [StudySession] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return sessions.filter { $0.startedAt >= startOfToday }
    }
}
