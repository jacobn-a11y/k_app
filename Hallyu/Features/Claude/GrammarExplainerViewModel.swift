import Foundation
import Observation

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

    // MARK: - Init

    init(
        claudeService: ClaudeServiceProtocol,
        learnerModel: LearnerModelServiceProtocol
    ) {
        self.claudeService = claudeService
        self.learnerModel = learnerModel
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
}
