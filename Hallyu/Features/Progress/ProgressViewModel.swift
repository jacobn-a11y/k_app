import Foundation
import Observation

// MARK: - Sub-Skill Breakdown

struct SkillBreakdown: Identifiable, Equatable, Sendable {
    let id: String
    let skillType: String
    let displayName: String
    let accuracy: Double
    let attempts: Int

    init(skillType: String, displayName: String, accuracy: Double, attempts: Int) {
        self.id = skillType
        self.skillType = skillType
        self.displayName = displayName
        self.accuracy = accuracy
        self.attempts = attempts
    }
}

// MARK: - Vocabulary Growth Data Point

struct VocabularyGrowthPoint: Identifiable, Equatable, Sendable {
    let id: Date
    let date: Date
    let count: Int
}

// MARK: - Daily Study Data Point

struct DailyStudyPoint: Identifiable, Equatable, Sendable {
    let id: Date
    let date: Date
    let minutes: Int
}

// MARK: - Accuracy Trend Data Point

struct AccuracyTrendPoint: Identifiable, Equatable, Sendable {
    let id: Date
    let date: Date
    let accuracy: Double
}

// MARK: - Progress View Model

@Observable
final class ProgressViewModel {

    // MARK: - State

    private(set) var cefrLevel: AppState.CEFRLevel = .preA1
    private(set) var skillBreakdowns: [SkillBreakdown] = []
    private(set) var vocabularyGrowth: [VocabularyGrowthPoint] = []
    private(set) var dailyStudyMinutes: [DailyStudyPoint] = []
    private(set) var accuracyTrends: [AccuracyTrendPoint] = []
    private(set) var totalStudyMinutes: Int = 0
    private(set) var streak: Int = 0
    private(set) var totalVocabularyCount: Int = 0
    private(set) var totalReviewItems: Int = 0
    private(set) var isLoading: Bool = false

    // MARK: - Skill Display Names

    static let skillDisplayNames: [String: String] = [
        "hangul_recognition": "Reading",
        "hangul_production": "Writing",
        "vocab_recognition": "Vocabulary",
        "vocab_production": "Production",
        "grammar": "Grammar",
        "listening": "Listening",
        "reading": "Reading Comp.",
        "pronunciation": "Pronunciation"
    ]

    // MARK: - Load Data

    func loadProgress(
        profile: LearnerProfile,
        skillMasteries: [SkillMastery],
        studySessions: [StudySession],
        reviewItems: [ReviewItem]
    ) {
        isLoading = true

        cefrLevel = AppState.CEFRLevel(rawValue: profile.cefrLevel) ?? .preA1
        totalReviewItems = reviewItems.filter { $0.userId == profile.userId }.count

        computeSkillBreakdowns(masteries: skillMasteries, userId: profile.userId)
        computeVocabularyGrowth(reviewItems: reviewItems, userId: profile.userId)
        computeDailyStudyMinutes(sessions: studySessions, userId: profile.userId)
        computeAccuracyTrends(sessions: studySessions, userId: profile.userId)
        computeTotalStudyTime(sessions: studySessions, userId: profile.userId)
        streak = computeStreak(from: studySessions, userId: profile.userId)

        isLoading = false
    }

    // MARK: - Skill Breakdowns

    func computeSkillBreakdowns(masteries: [SkillMastery], userId: UUID) {
        let userMasteries = masteries.filter { $0.userId == userId }

        // Group by skill type
        var grouped: [String: [SkillMastery]] = [:]
        for mastery in userMasteries {
            grouped[mastery.skillType, default: []].append(mastery)
        }

        // Build breakdowns for all skill types (show zeros for unpracticed)
        let allSkillTypes = [
            "listening", "reading", "vocab_recognition",
            "grammar", "pronunciation", "hangul_recognition",
            "hangul_production", "vocab_production"
        ]

        skillBreakdowns = allSkillTypes.compactMap { skillType in
            let entries = grouped[skillType] ?? []
            let displayName = Self.skillDisplayNames[skillType] ?? skillType.capitalized
            let avgAccuracy: Double
            let totalAttempts: Int

            if entries.isEmpty {
                avgAccuracy = 0.0
                totalAttempts = 0
            } else {
                avgAccuracy = entries.reduce(0.0) { $0 + $1.accuracy } / Double(entries.count)
                totalAttempts = entries.reduce(0) { $0 + $1.attempts }
            }

            return SkillBreakdown(
                skillType: skillType,
                displayName: displayName,
                accuracy: avgAccuracy,
                attempts: totalAttempts
            )
        }
    }

    // MARK: - Vocabulary Growth (over last 30 days)

    func computeVocabularyGrowth(reviewItems: [ReviewItem], userId: UUID) {
        let calendar = Calendar.current
        let userItems = reviewItems
            .filter { $0.userId == userId && $0.itemType == "vocabulary" }
            .sorted { $0.createdAt < $1.createdAt }

        guard !userItems.isEmpty else {
            vocabularyGrowth = []
            totalVocabularyCount = 0
            return
        }

        totalVocabularyCount = userItems.count

        // Build cumulative count per day for last 30 days
        let today = calendar.startOfDay(for: Date())
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: today)!

        var points: [VocabularyGrowthPoint] = []
        for dayOffset in 0..<30 {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: thirtyDaysAgo)!
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: date)!
            let count = userItems.filter { $0.createdAt < endOfDay }.count
            points.append(VocabularyGrowthPoint(id: date, date: date, count: count))
        }

        vocabularyGrowth = points
    }

    // MARK: - Daily Study Minutes (last 14 days)

    func computeDailyStudyMinutes(sessions: [StudySession], userId: UUID) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -13, to: today)!

        let userSessions = sessions.filter { $0.userId == userId && $0.completedAt != nil }

        var points: [DailyStudyPoint] = []
        for dayOffset in 0..<14 {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: fourteenDaysAgo)!
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date)!

            let dayMinutes = userSessions
                .filter { $0.startedAt >= date && $0.startedAt < nextDay }
                .reduce(0) { $0 + ($1.durationSeconds / 60) }

            points.append(DailyStudyPoint(id: date, date: date, minutes: dayMinutes))
        }

        dailyStudyMinutes = points
    }

    // MARK: - Accuracy Trends (last 14 days)

    func computeAccuracyTrends(sessions: [StudySession], userId: UUID) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -13, to: today)!

        let userSessions = sessions.filter {
            $0.userId == userId && $0.completedAt != nil && $0.itemsStudied > 0
        }

        var points: [AccuracyTrendPoint] = []
        for dayOffset in 0..<14 {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: fourteenDaysAgo)!
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date)!

            let daySessions = userSessions.filter { $0.startedAt >= date && $0.startedAt < nextDay }

            let totalStudied = daySessions.reduce(0) { $0 + $1.itemsStudied }
            let totalCorrect = daySessions.reduce(0) { $0 + $1.itemsCorrect }
            let accuracy = totalStudied > 0 ? Double(totalCorrect) / Double(totalStudied) : 0.0

            points.append(AccuracyTrendPoint(id: date, date: date, accuracy: accuracy))
        }

        accuracyTrends = points
    }

    // MARK: - Total Study Time

    func computeTotalStudyTime(sessions: [StudySession], userId: UUID) {
        let totalSeconds = sessions
            .filter { $0.userId == userId && $0.completedAt != nil }
            .reduce(0) { $0 + $1.durationSeconds }
        totalStudyMinutes = totalSeconds / 60
    }

    // MARK: - Streak

    func computeStreak(from sessions: [StudySession], userId: UUID) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let completedDays = Set(
            sessions
                .filter { $0.userId == userId && $0.completedAt != nil }
                .map { calendar.startOfDay(for: $0.startedAt) }
        )
        .sorted(by: >)

        guard !completedDays.isEmpty else { return 0 }

        var streak = 0
        var checkDate = today

        if !completedDays.contains(today) {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if completedDays.contains(yesterday) {
                checkDate = yesterday
            } else {
                return 0
            }
        }

        while completedDays.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        return streak
    }
}
