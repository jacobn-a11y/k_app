import Foundation
import Observation

@MainActor
@Observable
final class ContentAdapterViewModel {

    // MARK: - State

    enum Phase: Equatable {
        case idle
        case generating
        case showingExercises
        case completed
        case error(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var exercises: [PracticeItem] = []
    private(set) var currentExerciseIndex: Int = 0
    private(set) var answers: [ExerciseAnswer] = []
    private(set) var isShowingAnswer: Bool = false

    let claudeService: ClaudeServiceProtocol
    let learnerModel: LearnerModelServiceProtocol
    private let subscriptionTier: AppState.SubscriptionTier

    // MARK: - Types

    struct ExerciseAnswer: Equatable {
        let exerciseIndex: Int
        let userAnswer: String
        let wasCorrect: Bool
    }

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

    func generateExercises(mediaContentId: UUID, learnerLevel: String) async {
        do {
            try await claudeService.checkTierAllowed(tier: subscriptionTier)
        } catch {
            phase = .error(claudeErrorMessage(for: error))
            return
        }

        phase = .generating
        exercises = []
        currentExerciseIndex = 0
        answers = []

        do {
            let items = try await claudeService.generatePracticeItems(
                mediaContentId: mediaContentId,
                learnerLevel: learnerLevel
            )
            exercises = items
            phase = items.isEmpty ? .error("No exercises generated") : .showingExercises
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    func submitAnswer(_ userAnswer: String) {
        guard currentExerciseIndex < exercises.count else { return }
        let exercise = exercises[currentExerciseIndex]
        let isCorrect = userAnswer.lowercased().trimmingCharacters(in: .whitespaces)
            == exercise.correctAnswer.lowercased().trimmingCharacters(in: .whitespaces)

        let answer = ExerciseAnswer(
            exerciseIndex: currentExerciseIndex,
            userAnswer: userAnswer,
            wasCorrect: isCorrect
        )
        answers.append(answer)
        isShowingAnswer = true
    }

    func nextExercise() {
        isShowingAnswer = false
        currentExerciseIndex += 1
        if currentExerciseIndex >= exercises.count {
            phase = .completed
        }
    }

    func updateLearnerModel(userId: UUID) async {
        for answer in answers {
            guard answer.exerciseIndex < exercises.count else { continue }
            let exercise = exercises[answer.exerciseIndex]
            try? await learnerModel.updateMastery(
                userId: userId,
                skillType: exercise.type == "production" ? "vocab_production" : "vocab_recognition",
                skillId: exercise.prompt,
                wasCorrect: answer.wasCorrect,
                responseTime: 0
            )
        }
    }

    func reset() {
        phase = .idle
        exercises = []
        currentExerciseIndex = 0
        answers = []
        isShowingAnswer = false
    }

    private func claudeErrorMessage(for error: Error) -> String {
        if case ClaudeServiceError.tierLimitReached = error {
            return "Daily interaction limit reached for your subscription tier. Upgrade to continue."
        }
        return error.localizedDescription
    }

    // MARK: - Computed

    var currentExercise: PracticeItem? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }

    var progress: Double {
        guard !exercises.isEmpty else { return 0 }
        return Double(currentExerciseIndex) / Double(exercises.count)
    }

    var correctCount: Int {
        answers.filter { $0.wasCorrect }.count
    }

    var accuracy: Double {
        guard !answers.isEmpty else { return 0 }
        return Double(correctCount) / Double(answers.count)
    }

    var totalExercises: Int {
        exercises.count
    }
}
