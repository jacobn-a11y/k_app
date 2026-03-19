import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class LearningFeedViewModel {

    // MARK: - State

    private(set) var cards: [FeedCard] = []
    private(set) var isLoading: Bool = false
    private(set) var totalXP: Int = 0
    private(set) var comboMultiplier: Int = 1
    private(set) var consecutiveCorrect: Int = 0
    private(set) var bestStreak: Int = 0
    private(set) var cardsCompleted: Int = 0
    private(set) var wordsEncountered: Int = 0
    private(set) var goalReached: Bool = false
    private(set) var sessionStartedAt: Date = Date()
    private(set) var isBonusRound: Bool = false

    var showPlanSheet: Bool = false
    var showSessionSummary: Bool = false

    // XP animation state
    private(set) var lastXPGain: Int = 0
    private(set) var showXPAnimation: Bool = false

    // Streak celebration state
    private(set) var streakCelebrationThreshold: Int?

    // "Almost done" overlay
    private(set) var almostDoneCount: Int?

    // MARK: - Dependencies

    private let cardGenerator = FeedCardGenerator()
    private let srsEngine: SRSEngineProtocol
    private let learnerModel: LearnerModelServiceProtocol

    // MARK: - Cached Data

    private var profile: LearnerProfile?
    private var dueReviewItems: [ReviewItem] = []
    private var availableMedia: [MediaContent] = []
    private var skillMasteries: [SkillMastery] = []

    // MARK: - Retry Scheduling

    /// Cards queued for retry: (original card content, insert-after-N-more-cards)
    private var retryQueue: [(content: FeedCardContent, countdown: Int)] = []

    // MARK: - Milestone Tracking

    /// Next milestone insertion point (variable interval: 4-7 cards apart)
    private var nextMilestoneAt: Int = 0
    private var totalCorrectAnswers: Int = 0

    // MARK: - Goal Tracking

    /// Number of cards that constitute the daily goal (estimated)
    private var dailyGoalCardCount: Int = 0

    // MARK: - XP Constants

    static let xpView = 5
    static let xpComplete = 10
    static let xpPerfect = 20
    static let maxCombo = 5

    // MARK: - Init

    init(srsEngine: SRSEngineProtocol, learnerModel: LearnerModelServiceProtocol) {
        self.srsEngine = srsEngine
        self.learnerModel = learnerModel
    }

    // MARK: - Loading

    func loadFeed(
        profile: LearnerProfile,
        reviewItems: [ReviewItem],
        mediaContent: [MediaContent],
        skillMasteries: [SkillMastery],
        currentStreakDays: Int = 0
    ) {
        isLoading = true
        self.profile = profile
        self.availableMedia = mediaContent
        self.skillMasteries = skillMasteries.filter { $0.userId == profile.userId }

        let userReviewItems = reviewItems.filter { $0.userId == profile.userId }
        self.dueReviewItems = srsEngine.getDueItems(
            for: profile.userId,
            from: userReviewItems,
            limit: 50
        )

        // Estimate daily goal card count (~20s per card)
        dailyGoalCardCount = max(1, profile.dailyGoalMinutes * 3)

        // Schedule first milestone at a variable interval
        nextMilestoneAt = Int.random(in: 4...7)

        // Insert streak card at position 0 if active streak
        if currentStreakDays > 0 {
            cards.append(FeedCard(content: .streak(days: currentStreakDays)))
        }

        let initialCards = cardGenerator.generateCards(
            profile: profile,
            dueReviewItems: dueReviewItems,
            availableMedia: mediaContent,
            skillMasteries: self.skillMasteries,
            existingCardCount: 0
        )

        cards.append(contentsOf: initialCards)
        sessionStartedAt = Date()
        isLoading = false
    }

    // MARK: - Card Completion

    /// Call when a card is completed by the user.
    /// - Parameters:
    ///   - cardId: The card that was completed
    ///   - score: Optional score (0-1) for interactive cards. nil for passive cards.
    func completeCard(id cardId: UUID, score: Double? = nil) {
        guard let index = cards.firstIndex(where: { $0.id == cardId }) else { return }
        guard !cards[index].isCompleted else { return }

        cards[index].isCompleted = true
        cardsCompleted += 1

        // Track words for vocab cards
        if case .vocab = cards[index].content {
            wordsEncountered += 1
        }

        // Calculate XP
        let isPerfect = (score ?? 0) >= 0.9
        let isInteractive = cards[index].isInteractive
        var xpGain: Int

        if isPerfect {
            xpGain = Self.xpPerfect
            consecutiveCorrect += 1
            totalCorrectAnswers += 1
            comboMultiplier = min(consecutiveCorrect + 1, Self.maxCombo)
        } else if isInteractive && (score ?? 0) > 0 {
            xpGain = Self.xpComplete
            consecutiveCorrect += 1
            totalCorrectAnswers += 1
            comboMultiplier = min(consecutiveCorrect + 1, Self.maxCombo)
        } else if isInteractive && score == 0 {
            xpGain = Self.xpView
            // Schedule retry for wrong answers
            scheduleRetry(for: cards[index])
            consecutiveCorrect = 0
            comboMultiplier = 1
        } else {
            // Passive card (view only)
            xpGain = Self.xpView
            // Don't break combo for passive cards
        }

        xpGain *= comboMultiplier
        cards[index].xpAwarded = xpGain
        totalXP += xpGain

        // Track best streak
        if consecutiveCorrect > bestStreak {
            bestStreak = consecutiveCorrect
        }

        // Trigger XP animation
        lastXPGain = xpGain
        showXPAnimation = true

        // Check streak celebration thresholds (3, 5, 10, 15, 20...)
        checkStreakCelebration()

        // Check milestone injection (variable interval)
        checkMilestoneInjection(afterIndex: index)

        // Process retry queue
        processRetryQueue(afterIndex: index)

        // Check daily goal
        checkGoalReached(afterIndex: index)

        // Check "almost done" overlay
        checkAlmostDone()

        // Load more cards if approaching the end
        loadMoreIfNeeded(currentIndex: index)

        // Update skill mastery for interactive cards
        if let score, let profile {
            updateMastery(for: cards[index], score: score, profile: profile)
        }
    }

    /// Mark a card as viewed (for passive cards that auto-advance)
    func markViewed(id cardId: UUID) {
        completeCard(id: cardId, score: nil)
    }

    /// Skip a card without completing it
    func skipCard(id cardId: UUID) {
        consecutiveCorrect = 0
        comboMultiplier = 1
        streakCelebrationThreshold = nil
    }

    func dismissXPAnimation() {
        showXPAnimation = false
    }

    func dismissStreakCelebration() {
        streakCelebrationThreshold = nil
    }

    func dismissAlmostDone() {
        almostDoneCount = nil
    }

    // MARK: - Session

    var sessionDurationSeconds: Int {
        Int(Date().timeIntervalSince(sessionStartedAt))
    }

    func createStudySession() -> StudySession? {
        guard let profile else { return nil }
        return StudySession(
            userId: profile.userId,
            sessionType: "feed",
            durationSeconds: sessionDurationSeconds,
            itemsStudied: cardsCompleted,
            itemsCorrect: totalCorrectAnswers,
            startedAt: sessionStartedAt,
            completedAt: Date()
        )
    }

    func requestSessionSummary() {
        showSessionSummary = true
    }

    // MARK: - Daily Goal

    /// Estimated minutes spent based on cards completed (assuming ~20s per card)
    var estimatedMinutesSpent: Double {
        Double(cardsCompleted) * 20.0 / 60.0
    }

    var goalProgress: Double {
        guard let profile, profile.dailyGoalMinutes > 0 else { return 0 }
        return min(1.0, estimatedMinutesSpent / Double(profile.dailyGoalMinutes))
    }

    // MARK: - Retry Scheduling

    private func scheduleRetry(for card: FeedCard) {
        // Don't retry non-interactive or meta cards
        switch card.content {
        case .goalReached, .milestone, .streak, .culturalMoment:
            return
        default:
            break
        }
        // Insert retry 3-5 cards later
        let delay = Int.random(in: 3...5)
        retryQueue.append((content: card.content, countdown: delay))
    }

    private func processRetryQueue(afterIndex: Int) {
        var toInsert: [FeedCardContent] = []
        retryQueue = retryQueue.compactMap { entry in
            var entry = entry
            entry.countdown -= 1
            if entry.countdown <= 0 {
                toInsert.append(entry.content)
                return nil
            }
            return entry
        }

        // Insert retry cards after the next uncompleted card
        for content in toInsert {
            let retryCard = FeedCard(content: content)
            if let insertIdx = cards[(afterIndex + 1)...].firstIndex(where: { !$0.isCompleted }) {
                cards.insert(retryCard, at: insertIdx + 1)
            } else {
                cards.append(retryCard)
            }
        }
    }

    // MARK: - Streak Celebrations

    private static let streakThresholds = [3, 5, 10, 15, 20, 30, 50]

    private func checkStreakCelebration() {
        if Self.streakThresholds.contains(consecutiveCorrect) {
            streakCelebrationThreshold = consecutiveCorrect

            // Also inject a milestone card for significant streaks
            if consecutiveCorrect >= 5 {
                let milestoneCard = FeedCard(content: .milestone(info: MilestoneInfo(
                    type: .streakInSession(consecutiveCorrect),
                    message: "\(consecutiveCorrect) correct in a row!"
                )))
                if let insertIdx = cards.firstIndex(where: { !$0.isCompleted }) {
                    cards.insert(milestoneCard, at: insertIdx + 1)
                } else {
                    cards.append(milestoneCard)
                }
            }
        }
    }

    // MARK: - Variable-Interval Milestones

    private func checkMilestoneInjection(afterIndex: Int) {
        guard cardsCompleted >= nextMilestoneAt else { return }

        // Determine what kind of milestone to show
        let milestoneInfo: MilestoneInfo
        if wordsEncountered > 0 && wordsEncountered % 5 == 0 {
            milestoneInfo = MilestoneInfo(
                type: .wordsLearned(wordsEncountered),
                message: "You've reviewed \(wordsEncountered) words!"
            )
        } else if cardsCompleted % 10 == 0 {
            milestoneInfo = MilestoneInfo(
                type: .cardsCompleted(cardsCompleted),
                message: "\(cardsCompleted) cards completed!"
            )
        } else {
            let minutes = Int(estimatedMinutesSpent)
            if minutes > 0 {
                milestoneInfo = MilestoneInfo(
                    type: .minutesStudied(minutes),
                    message: "\(minutes) minutes of study!"
                )
            } else {
                milestoneInfo = MilestoneInfo(
                    type: .cardsCompleted(cardsCompleted),
                    message: "\(cardsCompleted) cards done!"
                )
            }
        }

        let milestoneCard = FeedCard(content: .milestone(info: milestoneInfo))
        if let insertIdx = cards[(afterIndex + 1)...].firstIndex(where: { !$0.isCompleted }) {
            cards.insert(milestoneCard, at: insertIdx)
        } else {
            cards.append(milestoneCard)
        }

        // Schedule next milestone at variable interval (4-7 cards)
        nextMilestoneAt = cardsCompleted + Int.random(in: 4...7)
    }

    // MARK: - Goal Check + Bonus Round

    private func checkGoalReached(afterIndex: Int) {
        guard let profile else { return }
        if !goalReached && estimatedMinutesSpent >= Double(profile.dailyGoalMinutes) {
            goalReached = true
            // Insert celebration card
            let celebrationCard = FeedCard(
                content: .goalReached(xpEarned: totalXP, cardsCompleted: cardsCompleted)
            )
            if let insertIdx = cards[(afterIndex + 1)...].firstIndex(where: { !$0.isCompleted }) {
                cards.insert(celebrationCard, at: insertIdx)
            } else {
                cards.append(celebrationCard)
            }
            // Enter bonus round — feed continues seamlessly
            isBonusRound = true
        }
    }

    // MARK: - "Almost Done" Overlay

    private func checkAlmostDone() {
        guard !goalReached else {
            almostDoneCount = nil
            return
        }
        let remaining = dailyGoalCardCount - cardsCompleted
        if remaining > 0 && remaining <= 3 {
            almostDoneCount = remaining
        } else {
            almostDoneCount = nil
        }
    }

    // MARK: - Load More

    private func loadMoreIfNeeded(currentIndex: Int) {
        let remainingCards = cards[currentIndex...].filter { !$0.isCompleted }.count
        if remainingCards < 3, let profile {
            let moreCards = cardGenerator.generateCards(
                profile: profile,
                dueReviewItems: dueReviewItems,
                availableMedia: availableMedia,
                skillMasteries: skillMasteries,
                existingCardCount: cards.count
            )
            cards.append(contentsOf: moreCards)
        }
    }

    // MARK: - Mastery Updates

    private func updateMastery(for card: FeedCard, score: Double, profile: LearnerProfile) {
        Task {
            switch card.content {
            case .jamoWatch(let jamo), .jamoTrace(let jamo), .jamoSpeak(let jamo):
                try? await learnerModel.updateMastery(
                    userId: profile.userId,
                    skillType: "reading",
                    skillId: String(jamo.character),
                    wasCorrect: score >= 0.7,
                    responseTime: 0
                )
            case .vocab(let info):
                try? await learnerModel.updateMastery(
                    userId: profile.userId,
                    skillType: "vocab_recognition",
                    skillId: info.promptText,
                    wasCorrect: score >= 0.7,
                    responseTime: 0
                )
            case .pronunciation(let info):
                try? await learnerModel.updateMastery(
                    userId: profile.userId,
                    skillType: "pronunciation",
                    skillId: info.phrase,
                    wasCorrect: score >= 0.7,
                    responseTime: 0
                )
            case .grammarSnap(let info):
                try? await learnerModel.updateMastery(
                    userId: profile.userId,
                    skillType: "grammar",
                    skillId: info.pattern,
                    wasCorrect: score >= 0.7,
                    responseTime: 0
                )
            case .listenAndChoose(let info):
                try? await learnerModel.updateMastery(
                    userId: profile.userId,
                    skillType: "listening",
                    skillId: info.audioSegmentKr,
                    wasCorrect: score >= 0.7,
                    responseTime: 0
                )
            case .mediaClip, .goalReached, .culturalMoment, .milestone, .streak:
                break
            }
        }
    }
}
