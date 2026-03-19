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
    private(set) var cardsCompleted: Int = 0
    private(set) var goalReached: Bool = false
    private(set) var sessionStartedAt: Date = Date()

    var showPlanSheet: Bool = false

    // XP animation state
    private(set) var lastXPGain: Int = 0
    private(set) var showXPAnimation: Bool = false

    // MARK: - Dependencies

    private let cardGenerator = FeedCardGenerator()
    private let srsEngine: SRSEngineProtocol
    private let learnerModel: LearnerModelServiceProtocol

    // MARK: - Cached Data

    private var profile: LearnerProfile?
    private var dueReviewItems: [ReviewItem] = []
    private var availableMedia: [MediaContent] = []
    private var skillMasteries: [SkillMastery] = []

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
        skillMasteries: [SkillMastery]
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

        let initialCards = cardGenerator.generateCards(
            profile: profile,
            dueReviewItems: dueReviewItems,
            availableMedia: mediaContent,
            skillMasteries: self.skillMasteries,
            existingCardCount: 0
        )

        cards = initialCards
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

        // Calculate XP
        let isPerfect = (score ?? 0) >= 0.9
        let isInteractive = cards[index].isInteractive
        var xpGain: Int

        if isPerfect {
            xpGain = Self.xpPerfect
            consecutiveCorrect += 1
            comboMultiplier = min(consecutiveCorrect + 1, Self.maxCombo)
        } else if isInteractive && (score ?? 0) > 0 {
            xpGain = Self.xpComplete
            consecutiveCorrect += 1
            comboMultiplier = min(consecutiveCorrect + 1, Self.maxCombo)
        } else if isInteractive && score == 0 {
            xpGain = Self.xpView
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

        // Trigger XP animation
        lastXPGain = xpGain
        showXPAnimation = true

        // Check daily goal
        checkGoalReached()

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
        // Don't mark as completed, just let the user scroll past
        consecutiveCorrect = 0
        comboMultiplier = 1
    }

    func dismissXPAnimation() {
        showXPAnimation = false
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
            itemsCorrect: consecutiveCorrect, // approximation
            startedAt: sessionStartedAt,
            completedAt: Date()
        )
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

    // MARK: - Private

    private func checkGoalReached() {
        guard let profile else { return }
        if !goalReached && estimatedMinutesSpent >= Double(profile.dailyGoalMinutes) {
            goalReached = true
            // Insert celebration card after the current position
            let celebrationCard = FeedCard(
                content: .goalReached(xpEarned: totalXP, cardsCompleted: cardsCompleted)
            )
            // Find first uncompleted card and insert before it
            if let insertIndex = cards.firstIndex(where: { !$0.isCompleted }) {
                cards.insert(celebrationCard, at: insertIndex + 1)
            } else {
                cards.append(celebrationCard)
            }
        }
    }

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
            case .mediaClip, .goalReached:
                break
            }
        }
    }
}
