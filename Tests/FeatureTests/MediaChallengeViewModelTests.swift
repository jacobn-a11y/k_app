import XCTest
@testable import HallyuCore

final class MediaChallengeViewModelTests: XCTestCase {

    private func makeViewModel() -> MediaChallengeViewModel {
        MediaChallengeViewModel(learnerModel: MockLearnerModelService())
    }

    private func makeMedia() -> MediaContent {
        MediaContent(title: "Test Drama", contentType: "drama", cefrLevel: "A2")
    }

    // MARK: - Start Challenge

    func testStartChallengeGeneratesQuestions() {
        let vm = makeViewModel()
        vm.startChallenge(media: makeMedia(), previousLevel: .a1)

        XCTAssertFalse(vm.questions.isEmpty)
        XCTAssertNotNil(vm.mediaContent)
        XCTAssertEqual(vm.previousLevel, .a1)
    }

    func testStartChallengeSetsStateToInProgress() {
        let vm = makeViewModel()
        vm.startChallenge(media: makeMedia(), previousLevel: .preA1)

        if case .inProgress(let index) = vm.state {
            XCTAssertEqual(index, 0)
        } else {
            XCTFail("Expected inProgress state")
        }
    }

    // MARK: - Answer Question

    func testAnswerQuestionSetsSelection() {
        let vm = makeViewModel()
        vm.startChallenge(media: makeMedia(), previousLevel: .preA1)

        vm.answerQuestion(selectedIndex: 2)

        XCTAssertEqual(vm.questions[0].selectedIndex, 2)
        XCTAssertTrue(vm.questions[0].isAnswered)
    }

    func testAnswerQuestionOnlyAffectsCurrentQuestion() {
        let vm = makeViewModel()
        vm.startChallenge(media: makeMedia(), previousLevel: .preA1)

        vm.answerQuestion(selectedIndex: 1)

        // Second question should be unanswered
        XCTAssertNil(vm.questions[1].selectedIndex)
    }

    // MARK: - Advance

    func testAdvanceMovesToNextQuestion() {
        let vm = makeViewModel()
        vm.startChallenge(media: makeMedia(), previousLevel: .preA1)

        vm.answerQuestion(selectedIndex: 0)
        vm.advance()

        if case .inProgress(let index) = vm.state {
            XCTAssertEqual(index, 1)
        } else {
            XCTFail("Expected inProgress state at index 1")
        }
    }

    func testAdvanceOnLastQuestionCompletesChallenge() {
        let vm = makeViewModel()
        vm.startChallenge(media: makeMedia(), previousLevel: .preA1)

        // Answer all questions
        for i in 0..<vm.questions.count {
            vm.answerQuestion(selectedIndex: vm.questions[i].correctIndex)
            vm.advance()
        }

        if case .completed(let result) = vm.state {
            XCTAssertEqual(result.totalQuestions, vm.questions.count)
        } else {
            XCTFail("Expected completed state")
        }
    }

    // MARK: - Progress

    func testProgressReflectsAnsweredQuestions() {
        let vm = makeViewModel()
        vm.startChallenge(media: makeMedia(), previousLevel: .preA1)

        XCTAssertEqual(vm.progress, 0.0)

        vm.answerQuestion(selectedIndex: 0)
        let expectedProgress = 1.0 / Double(vm.questions.count)
        XCTAssertEqual(vm.progress, expectedProgress, accuracy: 0.01)
    }

    // MARK: - Compute Result

    func testComputeResultAllCorrect() {
        let vm = makeViewModel()
        vm.startChallenge(media: makeMedia(), previousLevel: .a1)

        // Answer all correctly
        for i in 0..<vm.questions.count {
            vm.questions[i].selectedIndex = vm.questions[i].correctIndex
        }

        let result = vm.computeResult()
        XCTAssertEqual(result.correctCount, vm.questions.count)
        XCTAssertEqual(result.accuracy, 1.0)
        XCTAssertEqual(result.estimatedLevel, .b2) // 100% = B2
    }

    func testComputeResultAllIncorrect() {
        let vm = makeViewModel()
        vm.startChallenge(media: makeMedia(), previousLevel: .a1)

        // Answer all incorrectly
        for i in 0..<vm.questions.count {
            let wrong = (vm.questions[i].correctIndex + 1) % vm.questions[i].options.count
            vm.questions[i].selectedIndex = wrong
        }

        let result = vm.computeResult()
        XCTAssertEqual(result.correctCount, 0)
        XCTAssertEqual(result.estimatedLevel, .preA1) // 0% = pre-A1
    }

    func testComputeResultIdentifiesStrengthsAndWeaknesses() {
        let vm = makeViewModel()
        vm.startChallenge(media: makeMedia(), previousLevel: .preA1)

        // Answer listening questions correctly, vocab incorrectly
        for i in 0..<vm.questions.count {
            if vm.questions[i].skillType == "listening" || vm.questions[i].skillType == "grammar" {
                vm.questions[i].selectedIndex = vm.questions[i].correctIndex
            } else {
                let wrong = (vm.questions[i].correctIndex + 1) % vm.questions[i].options.count
                vm.questions[i].selectedIndex = wrong
            }
        }

        let result = vm.computeResult()
        // Should have some strengths and weaknesses
        XCTAssertFalse(result.strengths.isEmpty || result.weaknesses.isEmpty || result.recommendations.isEmpty,
                       "Result should identify strengths, weaknesses, or recommendations")
    }

    // MARK: - Level Estimation

    func testLevelEstimation() {
        let vm = makeViewModel()

        XCTAssertEqual(vm.estimateLevel(accuracy: 1.0), .b2)
        XCTAssertEqual(vm.estimateLevel(accuracy: 0.9), .b2)
        XCTAssertEqual(vm.estimateLevel(accuracy: 0.75), .b1)
        XCTAssertEqual(vm.estimateLevel(accuracy: 0.55), .a2)
        XCTAssertEqual(vm.estimateLevel(accuracy: 0.3), .a1)
        XCTAssertEqual(vm.estimateLevel(accuracy: 0.1), .preA1)
        XCTAssertEqual(vm.estimateLevel(accuracy: 0.0), .preA1)
    }

    // MARK: - Level Change Detection

    func testLevelChangeDetected() {
        let vm = makeViewModel()
        vm.startChallenge(media: makeMedia(), previousLevel: .a1)

        // Answer all correctly to get B2
        for i in 0..<vm.questions.count {
            vm.questions[i].selectedIndex = vm.questions[i].correctIndex
        }

        let result = vm.computeResult()
        XCTAssertTrue(result.levelChanged)
        XCTAssertEqual(result.previousLevel, .a1)
        XCTAssertEqual(result.estimatedLevel, .b2)
    }

    // MARK: - Question Generation

    func testGeneratedQuestionsHaveMultipleSkillTypes() {
        let vm = makeViewModel()
        let questions = vm.generateQuestions(from: makeMedia())

        let skillTypes = Set(questions.map { $0.skillType })
        XCTAssertTrue(skillTypes.count >= 3, "Should cover at least 3 skill types")
    }

    func testGeneratedQuestionsHaveValidCorrectIndex() {
        let vm = makeViewModel()
        let questions = vm.generateQuestions(from: makeMedia())

        for q in questions {
            XCTAssertTrue(q.correctIndex >= 0 && q.correctIndex < q.options.count,
                          "Correct index should be within options range for question: \(q.prompt)")
        }
    }

    func testGeneratedQuestionsHaveAtLeast2Options() {
        let vm = makeViewModel()
        let questions = vm.generateQuestions(from: makeMedia())

        for q in questions {
            XCTAssertTrue(q.options.count >= 2, "Each question should have at least 2 options")
        }
    }

    // MARK: - isLastQuestion

    func testIsLastQuestion() {
        let vm = makeViewModel()
        vm.startChallenge(media: makeMedia(), previousLevel: .preA1)

        XCTAssertFalse(vm.isLastQuestion)

        // Advance to last question
        for i in 0..<(vm.questions.count - 1) {
            vm.answerQuestion(selectedIndex: 0)
            vm.advance()
        }

        XCTAssertTrue(vm.isLastQuestion)
    }

    // MARK: - ChallengeQuestion

    func testChallengeQuestionCorrectness() {
        let q = ChallengeQuestion(prompt: "Test?", options: ["A", "B", "C"], correctIndex: 1, skillType: "test", selectedIndex: 1)
        XCTAssertTrue(q.isCorrect)
        XCTAssertTrue(q.isAnswered)

        let q2 = ChallengeQuestion(prompt: "Test?", options: ["A", "B", "C"], correctIndex: 1, skillType: "test", selectedIndex: 0)
        XCTAssertFalse(q2.isCorrect)
    }

    func testChallengeQuestionUnanswered() {
        let q = ChallengeQuestion(prompt: "Test?", options: ["A", "B"], correctIndex: 0, skillType: "test")
        XCTAssertFalse(q.isAnswered)
        XCTAssertFalse(q.isCorrect)
    }
}
