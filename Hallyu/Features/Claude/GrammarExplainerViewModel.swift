import Foundation
import Observation

@MainActor
@Observable
final class GrammarExplainerViewModel {

    // MARK: - State

    enum Phase: Equatable {
        case idle
        case retrievalFirst     // Asking learner to identify the rule
        case awaitingAnswer     // Waiting for learner response
        case loading
        case showingExplanation
        case error(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var pattern: String = ""
    private(set) var mediaContext: String = ""
    private(set) var retrievalQuestion: String = ""
    private(set) var learnerAnswer: String = ""
    private(set) var explanation: GrammarExplanation?

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

    func presentGrammar(pattern: String, mediaContext: String) {
        self.pattern = pattern
        self.mediaContext = mediaContext
        self.explanation = nil
        self.learnerAnswer = ""

        // Retrieval-first: ask learner to identify the rule
        retrievalQuestion = "Can you identify what grammar rule is at work in \"\(pattern)\"?"
        phase = .retrievalFirst
    }

    func submitAnswer(_ answer: String) {
        learnerAnswer = answer
        phase = .awaitingAnswer
    }

    func requestExplanation() async {
        do {
            try await claudeService.checkTierAllowed(tier: subscriptionTier)
        } catch {
            phase = .error(claudeErrorMessage(for: error))
            return
        }

        phase = .loading

        do {
            let result = try await claudeService.getGrammarExplanation(
                pattern: pattern,
                context: mediaContext
            )
            explanation = result
            phase = .showingExplanation
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    func trackGrammarPattern(userId: UUID) async {
        guard explanation != nil else { return }
        try? await learnerModel.updateMastery(
            userId: userId,
            skillType: "grammar",
            skillId: pattern,
            wasCorrect: !learnerAnswer.isEmpty, // Credit for attempting
            responseTime: 0
        )
    }

    func dismiss() {
        phase = .idle
        pattern = ""
        mediaContext = ""
        explanation = nil
        learnerAnswer = ""
    }

    // MARK: - Computed

    var isActive: Bool {
        phase != .idle
    }

    var hasExplanation: Bool {
        explanation != nil
    }

    private func claudeErrorMessage(for error: Error) -> String {
        if case ClaudeServiceError.tierLimitReached = error {
            return "Daily interaction limit reached for your subscription tier. Upgrade to continue."
        }
        return error.localizedDescription
    }
}
