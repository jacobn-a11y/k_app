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
    /// Composite ranking weights for media selection
    static let coverageWeight: Double = 0.5
    static let difficultyWeight: Double = 0.3
    static let topicWeight: Double = 0.2
    /// Vocabulary accuracy threshold below which a word is considered "weak"
    static let weakVocabThreshold: Double = 0.65

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
        let weakDomainWeights = weakDomains(from: skillMasteries)

        let centerDifficulty = (Self.idealDifficultyLow + Self.idealDifficultyHigh) / 2.0

        // Find media matching the learner's level, compute coverage + topic relevance.
        let candidates = availableMedia
            .filter { !studiedMediaIds.contains($0.id) }
            .filter { media in
                media.cefrLevel == profile.cefrLevel ||
                isWithinDifficultyRange(media.difficultyScore)
            }
            .map { media -> (media: MediaContent, coverage: Double, topicScore: Double) in
                let coverage = hasKnownWords
                    ? KoreanTextAnalyzer.estimateCoverage(text: media.transcriptKr, knownWords: knownWords)
                    : Self.targetCoverageCenter
                let topicScore = topicRelevanceScore(media: media, weakDomainWeights: weakDomainWeights)
                return (media, coverage, topicScore)
            }

        let preferredBand = candidates.filter {
            $0.coverage >= Self.targetCoverageLow && $0.coverage <= Self.targetCoverageHigh
        }
        let rankingPool = preferredBand.isEmpty ? candidates : preferredBand

        // Composite score: lower is better (distances are penalties, topic is a bonus subtracted)
        let selectedCandidate = rankingPool.sorted { lhs, rhs in
            let coverageDistL = abs(lhs.coverage - Self.targetCoverageCenter)
            let coverageDistR = abs(rhs.coverage - Self.targetCoverageCenter)

            let difficultyDistL = abs(lhs.media.difficultyScore - centerDifficulty)
            let difficultyDistR = abs(rhs.media.difficultyScore - centerDifficulty)

            let scoreL = Self.coverageWeight * coverageDistL
                       + Self.difficultyWeight * difficultyDistL
                       - Self.topicWeight * lhs.topicScore
            let scoreR = Self.coverageWeight * coverageDistR
                       + Self.difficultyWeight * difficultyDistR
                       - Self.topicWeight * rhs.topicScore

            return scoreL < scoreR
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

    // MARK: - Topic-Aware Selection

    /// Identify the learner's weakest vocabulary domains from SkillMastery records.
    /// Returns a dictionary of domain → weakness weight (higher = more weak words in that domain).
    private func weakDomains(from skillMasteries: [SkillMastery]) -> [String: Double] {
        let weakSkills = skillMasteries.filter {
            ($0.skillType == "vocab_recognition" || $0.skillType == "vocab_production") &&
            $0.accuracy < Self.weakVocabThreshold &&
            HangulUtilities.containsKorean($0.skillId)
        }

        var domainWeights: [String: Double] = [:]
        for skill in weakSkills {
            let domains = Self.wordDomains[skill.skillId] ?? []
            // Weight by how weak: lower accuracy = higher weight
            let weight = 1.0 - skill.accuracy
            for domain in domains {
                domainWeights[domain, default: 0] += weight
            }
        }

        return domainWeights
    }

    /// Score how relevant a media item's tags are to the learner's weak domains.
    /// Returns 0.0 when no weak domains match, up to 1.0 for strong matches.
    private func topicRelevanceScore(media: MediaContent, weakDomainWeights: [String: Double]) -> Double {
        guard !weakDomainWeights.isEmpty else { return 0.0 }

        let totalWeight = media.tags.reduce(0.0) { sum, tag in
            sum + (weakDomainWeights[tag] ?? 0.0)
        }

        // Normalize: cap at reasonable max (3.0 total weight ≈ 3 weak words matching)
        return min(totalWeight / 3.0, 1.0)
    }

    // MARK: - Word-to-Domain Mapping

    /// Maps common Korean vocabulary to topic domains matching media tag vocabulary.
    /// Used to bridge SkillMastery (which tracks Korean words) to media tags.
    /// TODO: Replace with VocabularyItem.mediaDomains lookup when that data is populated via Supabase.
    static let wordDomains: [String: [String]] = [
        // Food & Dining
        "먹다": ["food"], "마시다": ["food", "cafe"], "밥": ["food"],
        "물": ["food"], "음식": ["food"], "김치": ["food", "culture"],
        "라면": ["food"], "커피": ["cafe", "food"], "식당": ["food"],
        "맛있다": ["food"], "맛있겠다": ["food"], "요리사": ["food", "workplace"],
        "주문하다": ["food", "shopping"], "배고프다": ["food"],

        // Shopping & Market
        "사다": ["shopping", "market"], "돈": ["shopping"],
        "가게": ["shopping", "market"], "마트": ["shopping", "market"],
        "비싸다": ["shopping"], "비싸요": ["shopping"],
        "싸다": ["shopping", "market"], "싸요": ["shopping", "market"],
        "원": ["shopping"], "계산하다": ["shopping"],
        "얼마예요": ["shopping", "market"], "깎다": ["shopping", "bargaining"],

        // Greetings & Social
        "안녕하세요": ["greeting", "greetings"], "감사합니다": ["greeting"],
        "죄송합니다": ["greeting"], "만나다": ["greeting", "romance"],
        "만나요": ["greeting"], "잘": ["greeting"],

        // Family
        "가족": ["family"], "엄마": ["family"], "아빠": ["family"],
        "형": ["family"], "동생": ["family"], "부모님": ["family"],
        "할머니": ["family"], "아들": ["family"], "딸": ["family"],

        // School & Education
        "학교": ["school", "education"], "학생": ["school", "education"],
        "선생님": ["school", "education"], "공부": ["school", "education"],
        "시험": ["school", "education"], "숙제": ["school"],
        "배우다": ["school", "education"], "교육": ["education"],

        // Workplace
        "회사": ["workplace"], "일하다": ["workplace"],
        "직업": ["workplace"], "회사원": ["workplace"],

        // Travel & Transportation
        "여행": ["travel"], "버스": ["travel", "transportation"],
        "지하철": ["travel", "transportation"], "택시": ["travel", "transportation"],
        "비행기": ["travel"], "역": ["travel", "transportation"],

        // Medical & Health
        "병원": ["medical", "health"], "의사": ["medical", "workplace"],
        "아프다": ["medical", "health"], "약": ["medical", "health"],
        "건강": ["health"],

        // Romance & Emotion
        "사랑": ["romance", "emotional"], "좋아하다": ["romance"],
        "행복": ["emotional"], "슬프다": ["emotional"],
        "결혼": ["romance", "family"],

        // Culture & Entertainment
        "노래": ["music", "culture"], "영화": ["culture"],
        "드라마": ["culture"], "음악": ["music", "culture"],
        "문화": ["culture"], "전통": ["culture"],
        "춤": ["music", "culture"],

        // Weather & Nature
        "날씨": ["weather"], "비": ["weather"], "눈": ["weather"],
        "바람": ["weather"], "봄": ["weather", "culture"],
        "하늘": ["weather"],

        // Daily Life
        "집": ["daily-life"], "오늘": ["daily-life"], "시간": ["daily-life"],
        "친구": ["friends"], "사람": ["daily-life"],
        "운동": ["health", "sports"],
        "환경": ["environment"], "기술": ["technology"], "경제": ["economy"],
    ]

    // MARK: - Private Helpers

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
