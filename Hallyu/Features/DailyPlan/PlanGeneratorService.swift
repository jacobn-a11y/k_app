import Foundation

/// Activity types that can appear in a daily plan.
enum PlanActivityType: String, Codable, Sendable, CaseIterable {
    case srsReview = "srs_review"
    case mediaLesson = "media_lesson"
    case hangulLesson = "hangul_lesson"
    case pronunciationPractice = "pronunciation_practice"
    case vocabularyBuilding = "vocabulary_building"
    case grammarReview = "grammar_review"
}

/// A single activity in the daily plan.
struct PlanActivity: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let type: PlanActivityType
    let title: String
    let subtitle: String
    let estimatedMinutes: Int
    let mediaContentId: UUID?
    let reviewItemCount: Int
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        type: PlanActivityType,
        title: String,
        subtitle: String,
        estimatedMinutes: Int,
        mediaContentId: UUID? = nil,
        reviewItemCount: Int = 0,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.estimatedMinutes = estimatedMinutes
        self.mediaContentId = mediaContentId
        self.reviewItemCount = reviewItemCount
        self.isCompleted = isCompleted
    }
}

/// The complete daily learning plan.
struct DailyPlan: Equatable, Sendable {
    let activities: [PlanActivity]
    let totalMinutes: Int
    let goalMinutes: Int
    let date: Date

    var completedMinutes: Int {
        activities.filter { $0.isCompleted }.reduce(0) { $0 + $1.estimatedMinutes }
    }

    var completionProgress: Double {
        guard totalMinutes > 0 else { return 0 }
        return Double(completedMinutes) / Double(totalMinutes)
    }

    var isComplete: Bool {
        activities.allSatisfy { $0.isCompleted }
    }
}

/// Protocol for plan generation, enabling testability.
protocol PlanGeneratorServiceProtocol: Sendable {
    func generatePlan(
        profile: LearnerProfile,
        dueReviewItems: [ReviewItem],
        availableMedia: [MediaContent],
        skillMasteries: [SkillMastery],
        todaySessions: [StudySession]
    ) -> DailyPlan
}

/// Generates a personalized daily learning plan based on learner state.
///
/// Algorithm:
/// 1. Schedule overdue SRS reviews first (high priority)
/// 2. Select 1 media lesson matching learner's level (85-95% vocabulary coverage by difficulty)
/// 3. Add pronunciation practice if pronunciation mastery is lagging
/// 4. Fill remaining time with vocabulary building or grammar review
/// 5. Respect daily time goal
final class PlanGeneratorService: PlanGeneratorServiceProtocol, @unchecked Sendable {

    // MARK: - Configuration

    /// Minutes allocated per review item batch
    static let minutesPerReviewBatch = 5
    /// Maximum review items per batch
    static let reviewBatchSize = 10
    /// Default media lesson duration in minutes
    static let mediaLessonMinutes = 8
    /// Pronunciation practice duration in minutes
    static let pronunciationMinutes = 5
    /// Vocabulary building duration in minutes
    static let vocabularyMinutes = 5
    /// Grammar review duration in minutes
    static let grammarMinutes = 5
    /// Hangul lesson duration in minutes
    static let hangulLessonMinutes = 7
    /// Pronunciation mastery threshold below which practice is recommended
    static let pronunciationLagThreshold: Double = 0.4
    /// Ideal difficulty range for media content (lower bound)
    static let idealDifficultyLow: Double = 0.3
    /// Ideal difficulty range for media content (upper bound)
    static let idealDifficultyHigh: Double = 0.7
    /// i+1 comprehensible-input target range
    static let targetCoverageLow: Double = 0.85
    static let targetCoverageHigh: Double = 0.95
    static let targetCoverageCenter: Double = 0.90

    // MARK: - Plan Generation

    func generatePlan(
        profile: LearnerProfile,
        dueReviewItems: [ReviewItem],
        availableMedia: [MediaContent],
        skillMasteries: [SkillMastery],
        todaySessions: [StudySession]
    ) -> DailyPlan {
        let goalMinutes = profile.dailyGoalMinutes
        var activities: [PlanActivity] = []
        var remainingMinutes = goalMinutes

        // Already completed activities today reduce available time
        // Sum total seconds first, then convert to minutes to avoid losing
        // fractional minutes from per-session integer division.
        let completedSecondsToday = todaySessions
            .filter { $0.completedAt != nil }
            .reduce(0) { $0 + $1.durationSeconds }
        let completedMinutesToday = completedSecondsToday / 60
        remainingMinutes = max(0, remainingMinutes - completedMinutesToday)

        // Step 1: Schedule overdue SRS reviews (highest priority)
        if !dueReviewItems.isEmpty && remainingMinutes > 0 {
            let activity = makeReviewActivity(dueItems: dueReviewItems, remainingMinutes: &remainingMinutes)
            activities.append(activity)
        }

        // Step 2: Hangul lesson for beginners who haven't completed Hangul
        if !profile.hangulCompleted && remainingMinutes >= Self.hangulLessonMinutes {
            let activity = PlanActivity(
                type: .hangulLesson,
                title: "Hangul Practice",
                subtitle: "Continue learning Korean characters",
                estimatedMinutes: Self.hangulLessonMinutes
            )
            activities.append(activity)
            remainingMinutes -= Self.hangulLessonMinutes
        }

        // Step 3: Select a media lesson matching learner's level
        if remainingMinutes >= Self.mediaLessonMinutes {
            if let mediaActivity = makeMediaActivity(
                profile: profile,
                availableMedia: availableMedia,
                skillMasteries: skillMasteries,
                todaySessions: todaySessions
            ) {
                activities.append(mediaActivity)
                remainingMinutes -= Self.mediaLessonMinutes
            }
        }

        // Step 4: Add pronunciation practice if mastery is lagging
        if remainingMinutes >= Self.pronunciationMinutes {
            let pronunciationMastery = averageMastery(for: "pronunciation", in: skillMasteries)
            if pronunciationMastery < Self.pronunciationLagThreshold {
                let activity = PlanActivity(
                    type: .pronunciationPractice,
                    title: "Pronunciation Drill",
                    subtitle: "Practice sounds you find challenging",
                    estimatedMinutes: Self.pronunciationMinutes
                )
                activities.append(activity)
                remainingMinutes -= Self.pronunciationMinutes
            }
        }

        // Step 5: Fill remaining time with vocabulary or grammar
        if remainingMinutes >= Self.vocabularyMinutes {
            let vocabMastery = averageMastery(for: "vocab_recognition", in: skillMasteries)
            let grammarMastery = averageMastery(for: "grammar", in: skillMasteries)

            if grammarMastery < vocabMastery && remainingMinutes >= Self.grammarMinutes {
                let activity = PlanActivity(
                    type: .grammarReview,
                    title: "Grammar Practice",
                    subtitle: "Review grammar patterns",
                    estimatedMinutes: Self.grammarMinutes
                )
                activities.append(activity)
                remainingMinutes -= Self.grammarMinutes
            } else {
                let activity = PlanActivity(
                    type: .vocabularyBuilding,
                    title: "Vocabulary Builder",
                    subtitle: "Learn new words from media",
                    estimatedMinutes: Self.vocabularyMinutes
                )
                activities.append(activity)
                remainingMinutes -= Self.vocabularyMinutes
            }
        }

        let totalMinutes = activities.reduce(0) { $0 + $1.estimatedMinutes }

        return DailyPlan(
            activities: activities,
            totalMinutes: totalMinutes,
            goalMinutes: goalMinutes,
            date: Date()
        )
    }

    // MARK: - Private Helpers

    private func makeReviewActivity(dueItems: [ReviewItem], remainingMinutes: inout Int) -> PlanActivity {
        let itemCount = min(dueItems.count, Self.reviewBatchSize)
        let batchCount = (itemCount + Self.reviewBatchSize - 1) / Self.reviewBatchSize
        let minutes = min(batchCount * Self.minutesPerReviewBatch, remainingMinutes)
        remainingMinutes -= minutes

        return PlanActivity(
            type: .srsReview,
            title: "Review Due Items",
            subtitle: "\(itemCount) item\(itemCount == 1 ? "" : "s") ready for review",
            estimatedMinutes: minutes,
            reviewItemCount: itemCount
        )
    }

    private func makeMediaActivity(
        profile: LearnerProfile,
        availableMedia: [MediaContent],
        skillMasteries: [SkillMastery],
        todaySessions: [StudySession]
    ) -> PlanActivity? {
        // Filter out media already studied today
        let studiedMediaIds = Set(todaySessions.compactMap { $0.mediaContentId })
        let knownWords = knownVocabulary(from: skillMasteries)
        let hasKnownWords = !knownWords.isEmpty

        // Find media matching the learner's level and compute vocabulary coverage fit.
        let candidatesWithCoverage = availableMedia
            .filter { !studiedMediaIds.contains($0.id) }
            .filter { media in
                media.cefrLevel == profile.cefrLevel ||
                isWithinDifficultyRange(media.difficultyScore)
            }
            .map { media -> (media: MediaContent, coverage: Double) in
                let coverage = hasKnownWords
                    ? KoreanTextAnalyzer.estimateCoverage(text: media.transcriptKr, knownWords: knownWords)
                    : Self.targetCoverageCenter
                return (media, coverage)
            }

        let preferredBand = candidatesWithCoverage.filter {
            $0.coverage >= Self.targetCoverageLow && $0.coverage <= Self.targetCoverageHigh
        }
        let rankingPool = preferredBand.isEmpty ? candidatesWithCoverage : preferredBand

        let selectedCandidate = rankingPool.sorted { lhs, rhs in
            let coverageDistanceL = abs(lhs.coverage - Self.targetCoverageCenter)
            let coverageDistanceR = abs(rhs.coverage - Self.targetCoverageCenter)
            if coverageDistanceL != coverageDistanceR {
                return coverageDistanceL < coverageDistanceR
            }

            let centerDifficulty = (Self.idealDifficultyLow + Self.idealDifficultyHigh) / 2.0
            let difficultyDistanceL = abs(lhs.media.difficultyScore - centerDifficulty)
            let difficultyDistanceR = abs(rhs.media.difficultyScore - centerDifficulty)
            return difficultyDistanceL < difficultyDistanceR
        }.first

        guard let selectedCandidate else { return nil }
        let selected = selectedCandidate.media
        let coveragePercent = Int((selectedCandidate.coverage * 100).rounded())

        return PlanActivity(
            type: .mediaLesson,
            title: selected.title,
            subtitle: "\(selected.contentType.capitalized) lesson • \(coveragePercent)% known vocab",
            estimatedMinutes: Self.mediaLessonMinutes,
            mediaContentId: selected.id
        )
    }

    private func isWithinDifficultyRange(_ score: Double) -> Bool {
        score >= Self.idealDifficultyLow && score <= Self.idealDifficultyHigh
    }

    private func averageMastery(for skillType: String, in masteries: [SkillMastery]) -> Double {
        let matching = masteries.filter { $0.skillType == skillType }
        guard !matching.isEmpty else { return 0.0 }
        return matching.reduce(0.0) { $0 + $1.accuracy } / Double(matching.count)
    }

    private func knownVocabulary(from masteries: [SkillMastery]) -> Set<String> {
        let learned = masteries.filter {
            ($0.skillType == "vocab_recognition" || $0.skillType == "vocab_production") &&
            $0.accuracy >= 0.65 &&
            HangulUtilities.containsKorean($0.skillId)
        }

        return Set(learned.map(\.skillId))
    }
}
