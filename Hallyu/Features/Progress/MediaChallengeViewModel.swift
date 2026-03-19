import Foundation
import Observation

// MARK: - Challenge Question

struct ChallengeQuestion: Identifiable, Equatable, Sendable {
    let id: UUID
    let prompt: String
    let options: [String]
    let correctIndex: Int
    let skillType: String
    var selectedIndex: Int?

    var isAnswered: Bool { selectedIndex != nil }
    var isCorrect: Bool { selectedIndex == correctIndex }

    init(
        id: UUID = UUID(),
        prompt: String,
        options: [String],
        correctIndex: Int,
        skillType: String,
        selectedIndex: Int? = nil
    ) {
        self.id = id
        self.prompt = prompt
        self.options = options
        self.correctIndex = correctIndex
        self.skillType = skillType
        self.selectedIndex = selectedIndex
    }
}

// MARK: - Challenge Result

struct ChallengeResult: Equatable, Sendable {
    let totalQuestions: Int
    let correctCount: Int
    let skillResults: [String: SkillResult]
    let estimatedLevel: AppState.CEFRLevel
    let previousLevel: AppState.CEFRLevel
    let strengths: [String]
    let weaknesses: [String]
    let recommendations: [String]

    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctCount) / Double(totalQuestions)
    }

    var levelChanged: Bool { estimatedLevel != previousLevel }
}

struct SkillResult: Equatable, Sendable {
    let skillType: String
    let correct: Int
    let total: Int

    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }
}

// MARK: - Challenge State

enum ChallengeState: Equatable {
    case notStarted
    case inProgress(questionIndex: Int)
    case completed(ChallengeResult)
}

// MARK: - View Model

@Observable
final class MediaChallengeViewModel {

    // MARK: - State

    var state: ChallengeState = .notStarted
    var questions: [ChallengeQuestion] = []
    private(set) var mediaContent: MediaContent?
    private(set) var previousLevel: AppState.CEFRLevel = .preA1

    var currentQuestionIndex: Int {
        if case .inProgress(let index) = state { return index }
        return 0
    }

    var currentQuestion: ChallengeQuestion? {
        guard case .inProgress(let index) = state,
              index < questions.count else { return nil }
        return questions[index]
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        let answered = questions.filter { $0.isAnswered }.count
        return Double(answered) / Double(questions.count)
    }

    var isLastQuestion: Bool {
        if case .inProgress(let index) = state {
            return index == questions.count - 1
        }
        return false
    }

    let learnerModel: LearnerModelServiceProtocol

    // MARK: - Init

    init(learnerModel: LearnerModelServiceProtocol) {
        self.learnerModel = learnerModel
    }

    // MARK: - Start Challenge

    func startChallenge(media: MediaContent, previousLevel: AppState.CEFRLevel) {
        self.mediaContent = media
        self.previousLevel = previousLevel
        self.questions = generateQuestions(from: media)
        self.state = questions.isEmpty ? .notStarted : .inProgress(questionIndex: 0)
    }

    // MARK: - Answer Question

    func answerQuestion(selectedIndex: Int) {
        guard case .inProgress(let index) = state, index < questions.count else { return }
        questions[index].selectedIndex = selectedIndex
    }

    // MARK: - Next Question or Finish

    func advance() {
        guard case .inProgress(let index) = state else { return }

        if index < questions.count - 1 {
            state = .inProgress(questionIndex: index + 1)
        } else {
            finishChallenge()
        }
    }

    // MARK: - Finish

    func finishChallenge() {
        let result = computeResult()
        state = .completed(result)
    }

    // MARK: - Generate Questions

    func generateQuestions(from media: MediaContent) -> [ChallengeQuestion] {
        var questions: [ChallengeQuestion] = []

        // Listening comprehension questions
        questions.append(ChallengeQuestion(
            prompt: "After watching this \(media.contentType), what is the main topic being discussed?",
            options: ["Daily life and routines", "Historical events", "Food and cooking", "Travel and directions"],
            correctIndex: 0,
            skillType: "listening"
        ))

        questions.append(ChallengeQuestion(
            prompt: "Which emotion best describes the speaker's tone?",
            options: ["Happy and excited", "Sad and reflective", "Angry and frustrated", "Calm and neutral"],
            correctIndex: 3,
            skillType: "listening"
        ))

        // Vocabulary recognition
        questions.append(ChallengeQuestion(
            prompt: "What does '감사합니다' (gamsahamnida) mean in this context?",
            options: ["I'm sorry", "Thank you", "Goodbye", "Hello"],
            correctIndex: 1,
            skillType: "vocab_recognition"
        ))

        questions.append(ChallengeQuestion(
            prompt: "Select the correct meaning of '학교' (hakgyo):",
            options: ["Hospital", "Restaurant", "School", "Library"],
            correctIndex: 2,
            skillType: "vocab_recognition"
        ))

        // Grammar
        questions.append(ChallengeQuestion(
            prompt: "Which particle correctly completes: '나__ 학생이에요' (I am a student)?",
            options: ["-은/는", "-이/가", "-을/를", "-에서"],
            correctIndex: 0,
            skillType: "grammar"
        ))

        questions.append(ChallengeQuestion(
            prompt: "What is the correct honorific form of '먹다' (to eat)?",
            options: ["먹어요", "드세요", "먹습니다", "드십니다"],
            correctIndex: 1,
            skillType: "grammar"
        ))

        // Reading comprehension
        questions.append(ChallengeQuestion(
            prompt: "Based on the transcript, what happened first in the scene?",
            options: ["Characters had a meal", "Characters greeted each other", "Characters had an argument", "Characters went shopping"],
            correctIndex: 1,
            skillType: "reading"
        ))

        // Pronunciation awareness
        questions.append(ChallengeQuestion(
            prompt: "Which word has the same vowel sound as '아' (a)?",
            options: ["오 (o)", "이 (i)", "바 (ba)", "우 (u)"],
            correctIndex: 2,
            skillType: "pronunciation"
        ))

        return questions
    }

    // MARK: - Compute Result

    func computeResult() -> ChallengeResult {
        let totalQuestions = questions.count
        let correctCount = questions.filter { $0.isCorrect }.count

        // Group by skill type
        var skillGroups: [String: (correct: Int, total: Int)] = [:]
        for q in questions {
            var entry = skillGroups[q.skillType] ?? (correct: 0, total: 0)
            entry.total += 1
            if q.isCorrect { entry.correct += 1 }
            skillGroups[q.skillType] = entry
        }

        let skillResults = Dictionary(uniqueKeysWithValues: skillGroups.map { key, value in
            (key, SkillResult(skillType: key, correct: value.correct, total: value.total))
        })

        // Estimate level based on overall accuracy
        let accuracy = totalQuestions > 0 ? Double(correctCount) / Double(totalQuestions) : 0
        let estimatedLevel = estimateLevel(accuracy: accuracy)

        // Determine strengths and weaknesses
        let sortedSkills = skillGroups.sorted { $0.value.correct > $1.value.correct }
        let strengths = sortedSkills
            .filter { $0.value.total > 0 && Double($0.value.correct) / Double($0.value.total) >= 0.7 }
            .map { displayName(for: $0.key) }
        let weaknesses = sortedSkills
            .filter { $0.value.total > 0 && Double($0.value.correct) / Double($0.value.total) < 0.5 }
            .map { displayName(for: $0.key) }

        // Recommendations
        var recommendations: [String] = []
        if weaknesses.contains("Listening") {
            recommendations.append("Practice with more audio content at a slower speed")
        }
        if weaknesses.contains("Grammar") {
            recommendations.append("Review grammar patterns with the Grammar Explainer")
        }
        if weaknesses.contains("Vocabulary") {
            recommendations.append("Add more vocabulary to your daily review sessions")
        }
        if recommendations.isEmpty {
            recommendations.append("Keep up the great work! Try challenging yourself with harder content")
        }

        return ChallengeResult(
            totalQuestions: totalQuestions,
            correctCount: correctCount,
            skillResults: skillResults,
            estimatedLevel: estimatedLevel,
            previousLevel: previousLevel,
            strengths: strengths,
            weaknesses: weaknesses,
            recommendations: recommendations
        )
    }

    // MARK: - Level Estimation

    func estimateLevel(accuracy: Double) -> AppState.CEFRLevel {
        if accuracy >= 0.9 { return .b2 }
        if accuracy >= 0.75 { return .b1 }
        if accuracy >= 0.55 { return .a2 }
        if accuracy >= 0.3 { return .a1 }
        return .preA1
    }

    // MARK: - Helpers

    private func displayName(for skillType: String) -> String {
        ProgressViewModel.skillDisplayNames[skillType] ?? skillType.capitalized
    }
}
