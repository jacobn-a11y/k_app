import Foundation
import Observation

@MainActor
@Observable
final class ComprehensionCoachViewModel {

    // MARK: - State

    enum Phase: Equatable {
        case idle
        case retrievalPrompt  // Asking learner to guess first
        case awaitingGuess    // Waiting for learner's guess
        case loading          // Fetching from Claude
        case showingResult    // Displaying explanation
        case error(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var targetWord: String = ""
    private(set) var mediaTitle: String = ""
    private(set) var retrievalPromptText: String = ""
    private(set) var learnerGuess: String = ""
    private(set) var response: ComprehensionResponse?
    private(set) var addedToReview: Bool = false

    let claudeService: ClaudeServiceProtocol
    let learnerModel: LearnerModelServiceProtocol
    private let subscriptionTier: AppState.SubscriptionTier

    // MARK: - Init

    init(
        claudeService: ClaudeServiceProtocol,
        learnerModel: LearnerModelServiceProtocol,
        subscriptionTier: AppState.SubscriptionTier = .core
    ) {
        self.claudeService = claudeService
        self.learnerModel = learnerModel
        self.subscriptionTier = subscriptionTier
    }

    // MARK: - Actions

    func onWordTapped(
        word: String,
        mediaTitle: String,
        transcript: String,
        learnerLevel: String,
        knownVocabulary: [String]
    ) {
        self.targetWord = word
        self.mediaTitle = mediaTitle
        self.response = nil
        self.addedToReview = false
        self.learnerGuess = ""

        // Retrieval-first: ask learner to guess
        retrievalPromptText = "What do you think \"\(word)\" means in this context?"
        phase = .retrievalPrompt
    }

    func submitGuess(_ guess: String) {
        learnerGuess = guess
        phase = .awaitingGuess
    }

    func requestExplanation(
        transcript: String,
        learnerLevel: String,
        knownVocabulary: [String]
    ) async {
        // Check tier before making API call
        do {
            try await claudeService.checkTierAllowed(tier: subscriptionTier)
        } catch {
            phase = .error("Daily interaction limit reached for your subscription tier. Upgrade to continue.")
            return
        }

        // Resets to .loading regardless of current phase (including .error),
        // so retrying from the error state works without extra cleanup.
        phase = .loading

        let context = ComprehensionContext(
            mediaTitle: mediaTitle,
            transcript: transcript,
            targetWord: targetWord,
            learnerLevel: learnerLevel,
            knownVocabulary: knownVocabulary
        )

        let query = learnerGuess.isEmpty
            ? "What does this mean?"
            : "I think it means: \(learnerGuess). Am I right?"

        do {
            let result = try await claudeService.getComprehensionHelp(context: context, query: query)
            response = result
            phase = .showingResult
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    func addToReview(userId: UUID) async {
        guard response != nil else { return }
        do {
            try await learnerModel.updateMastery(
                userId: userId,
                skillType: "vocab_recognition",
                skillId: targetWord,
                wasCorrect: false, // New item, not yet mastered
                responseTime: 0
            )
            addedToReview = true
        } catch {
            // Silently fail for review add — non-critical
        }
    }

    func dismiss() {
        phase = .idle
        response = nil
        targetWord = ""
        learnerGuess = ""
    }

    // MARK: - Computed Properties

    var isActive: Bool {
        phase != .idle
    }

    var hasResponse: Bool {
        response != nil
    }

    var guessWasClose: Bool {
        guard let response = response, !learnerGuess.isEmpty else { return false }
        let guess = learnerGuess.lowercased()
        let meaning = response.literalMeaning.lowercased()
        let contextMeaning = response.contextualMeaning.lowercased()
        return meaning.contains(guess) || contextMeaning.contains(guess) ||
               guess.contains(meaning) || guess.contains(contextMeaning)
    }
}
