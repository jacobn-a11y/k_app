import XCTest
@testable import Hallyu

final class MediaLessonViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeContent(
        contentType: String = "drama",
        transcript: String = "사랑 친구 가족 엄마 아빠 학교 회사 집",
        segments: [MediaContent.TranscriptSegment] = []
    ) -> MediaContent {
        let defaultSegments = segments.isEmpty ? [
            MediaContent.TranscriptSegment(startMs: 0, endMs: 3000, textKr: "사랑하는 친구야", textEn: "Dear friend"),
            MediaContent.TranscriptSegment(startMs: 3000, endMs: 6000, textKr: "오늘 학교에서 뭐 했어?", textEn: "What did you do at school today?"),
            MediaContent.TranscriptSegment(startMs: 6000, endMs: 9000, textKr: "집에 가고 싶어", textEn: "I want to go home"),
            MediaContent.TranscriptSegment(startMs: 9000, endMs: 12000, textKr: "엄마가 밥 만들었어", textEn: "Mom made food"),
            MediaContent.TranscriptSegment(startMs: 12000, endMs: 15000, textKr: "내일 회사에 가야 해", textEn: "I have to go to work tomorrow"),
        ] : segments

        return MediaContent(
            title: "Test Drama Episode",
            contentType: contentType,
            source: "Test Source",
            difficultyScore: 0.5,
            cefrLevel: "A1",
            durationSeconds: 180,
            transcriptKr: transcript,
            transcriptSegments: defaultSegments,
            vocabularyIds: [UUID(), UUID(), UUID()],
            grammarPatternIds: [UUID()],
            mediaUrl: "https://example.com/media.mp4",
            thumbnailUrl: "https://example.com/thumb.jpg",
            culturalNotes: "Test cultural note",
            tags: ["drama", "beginner"]
        )
    }

    private func makeViewModel(
        contentType: String = "drama",
        transcript: String = "사랑 친구 가족 엄마 아빠 학교 회사 집"
    ) -> MediaLessonViewModel {
        let content = makeContent(contentType: contentType, transcript: transcript)
        return MediaLessonViewModel(
            content: content,
            claudeService: MockClaudeService(),
            srsEngine: MockSRSEngine(),
            learnerModel: MockLearnerModelService(),
            audioService: MockAudioService(),
            speechRecognition: MockSpeechRecognitionService(),
            userId: UUID(),
            learnerLevel: "A1"
        )
    }

    // MARK: - Initialization Tests

    func testInitialStepIsPreTask() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.currentStep, .preTask)
    }

    func testInitialProgressIsZero() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.progress, 0, accuracy: 0.01)
    }

    func testPreTaskWordsArePopulated() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.preTaskWords.isEmpty, "Pre-task words should be populated from transcript")
        XCTAssertLessThanOrEqual(vm.preTaskWords.count, 8, "Should have at most 8 pre-task words")
    }

    func testExtractedWordsArePopulated() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.extractedWords.isEmpty, "Extracted words should be populated")
        XCTAssertLessThanOrEqual(vm.extractedWords.count, 15)
    }

    func testShadowingSentencesPopulatedForVideoContent() {
        let vm = makeViewModel(contentType: "drama")
        XCTAssertFalse(vm.shadowingSentences.isEmpty, "Shadowing sentences should exist for drama content")
        XCTAssertLessThanOrEqual(vm.shadowingSentences.count, 3)
    }

    func testShadowingSentencesEmptyForTextContent() {
        let vm = makeViewModel(contentType: "webtoon")
        XCTAssertTrue(vm.shadowingSentences.isEmpty, "Shadowing should be empty for text content")
    }

    func testShadowingSentencesEmptyForNewsContent() {
        let vm = makeViewModel(contentType: "news")
        XCTAssertTrue(vm.shadowingSentences.isEmpty)
    }

    // MARK: - Available Steps Tests

    func testVideoContentHasAllSteps() {
        let vm = makeViewModel(contentType: "drama")
        XCTAssertEqual(vm.availableSteps.count, 7)
        XCTAssertTrue(vm.availableSteps.contains(.shadowingPractice))
    }

    func testTextContentSkipsShadowing() {
        let vm = makeViewModel(contentType: "webtoon")
        XCTAssertEqual(vm.availableSteps.count, 6)
        XCTAssertFalse(vm.availableSteps.contains(.shadowingPractice))
    }

    func testNewsContentSkipsShadowing() {
        let vm = makeViewModel(contentType: "news")
        XCTAssertFalse(vm.availableSteps.contains(.shadowingPractice))
    }

    // MARK: - Navigation Tests

    func testAdvanceFromPreTask() {
        let vm = makeViewModel()
        // Complete all pre-task words first
        for _ in vm.preTaskWords {
            vm.revealPreTaskAnswer()
            vm.submitPreTaskAnswer(knewIt: true)
        }
        XCTAssertTrue(vm.canAdvance)
        vm.advanceToNextStep()
        XCTAssertEqual(vm.currentStep, .firstListen)
    }

    func testCannotAdvanceWithoutCompletingPreTask() {
        let vm = makeViewModel()
        guard !vm.preTaskWords.isEmpty else { return }
        XCTAssertFalse(vm.canAdvance, "Should not advance with pre-task words remaining")
    }

    func testAdvanceFromFirstListen() {
        let vm = makeViewModel()
        vm.goToStep(.firstListen)
        XCTAssertFalse(vm.canAdvance)
        vm.completeFirstListen()
        XCTAssertTrue(vm.canAdvance)
        vm.advanceToNextStep()
        XCTAssertEqual(vm.currentStep, .secondListen)
    }

    func testAdvanceFromSecondListen() {
        let vm = makeViewModel()
        vm.goToStep(.secondListen)
        XCTAssertFalse(vm.canAdvance)
        vm.completeSecondListen()
        XCTAssertTrue(vm.canAdvance)
        vm.advanceToNextStep()
        XCTAssertEqual(vm.currentStep, .comprehensionCheck)
    }

    func testAdvanceFromVocabularyExtraction() {
        let vm = makeViewModel()
        vm.goToStep(.vocabularyExtraction)
        // Can always advance from vocab extraction (optional step)
        XCTAssertTrue(vm.canAdvance)
    }

    func testCannotAdvancePastSummary() {
        let vm = makeViewModel()
        vm.goToStep(.summary)
        XCTAssertFalse(vm.canAdvance)
    }

    func testGoToStepDirectly() {
        let vm = makeViewModel()
        vm.goToStep(.comprehensionCheck)
        XCTAssertEqual(vm.currentStep, .comprehensionCheck)
    }

    func testProgressIncreasesWithSteps() {
        let vm = makeViewModel(contentType: "webtoon") // 6 steps
        XCTAssertEqual(vm.progress, 0, accuracy: 0.01)
        vm.goToStep(.firstListen)
        XCTAssertGreaterThan(vm.progress, 0)
        vm.goToStep(.summary)
        XCTAssertEqual(vm.progress, 1.0, accuracy: 0.01)
    }

    // MARK: - Pre-Task Tests

    func testRevealPreTaskAnswer() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.preTaskShowingAnswer)
        vm.revealPreTaskAnswer()
        XCTAssertTrue(vm.preTaskShowingAnswer)
    }

    func testSubmitPreTaskAnswerKnown() {
        let vm = makeViewModel()
        guard !vm.preTaskWords.isEmpty else { return }
        let initialIndex = vm.preTaskCurrentIndex
        vm.revealPreTaskAnswer()
        vm.submitPreTaskAnswer(knewIt: true)
        XCTAssertEqual(vm.preTaskCurrentIndex, initialIndex + 1)
        XCTAssertEqual(vm.preTaskResults.count, 1)
        XCTAssertTrue(vm.preTaskResults.first?.knewIt ?? false)
        XCTAssertFalse(vm.preTaskShowingAnswer, "Answer should be hidden after submission")
    }

    func testSubmitPreTaskAnswerUnknown() {
        let vm = makeViewModel()
        guard !vm.preTaskWords.isEmpty else { return }
        vm.revealPreTaskAnswer()
        vm.submitPreTaskAnswer(knewIt: false)
        XCTAssertEqual(vm.preTaskResults.count, 1)
        XCTAssertFalse(vm.preTaskResults.first?.knewIt ?? true)
    }

    func testPreTaskProgressUpdates() {
        let vm = makeViewModel()
        guard vm.preTaskWords.count > 1 else { return }
        XCTAssertEqual(vm.preTaskProgress, 0, accuracy: 0.01)
        vm.revealPreTaskAnswer()
        vm.submitPreTaskAnswer(knewIt: true)
        XCTAssertGreaterThan(vm.preTaskProgress, 0)
    }

    func testCurrentPreTaskWordAdvances() {
        let vm = makeViewModel()
        guard vm.preTaskWords.count > 1 else { return }
        let firstWord = vm.currentPreTaskWord
        vm.revealPreTaskAnswer()
        vm.submitPreTaskAnswer(knewIt: true)
        let secondWord = vm.currentPreTaskWord
        XCTAssertNotEqual(firstWord?.id, secondWord?.id)
    }

    func testCurrentPreTaskWordNilWhenComplete() {
        let vm = makeViewModel()
        for _ in vm.preTaskWords {
            vm.revealPreTaskAnswer()
            vm.submitPreTaskAnswer(knewIt: true)
        }
        XCTAssertNil(vm.currentPreTaskWord)
    }

    // MARK: - Media Playback Tests

    func testFirstListenInitiallyNotCompleted() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.firstListenCompleted)
    }

    func testCompleteFirstListen() {
        let vm = makeViewModel()
        vm.completeFirstListen()
        XCTAssertTrue(vm.firstListenCompleted)
    }

    func testSecondListenInitiallyNotCompleted() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.secondListenCompleted)
    }

    func testCompleteSecondListen() {
        let vm = makeViewModel()
        vm.completeSecondListen()
        XCTAssertTrue(vm.secondListenCompleted)
    }

    // MARK: - Comprehension Tests

    func testComprehensionInitialState() {
        let vm = makeViewModel()
        XCTAssertTrue(vm.comprehensionQuestions.isEmpty)
        XCTAssertEqual(vm.comprehensionCurrentIndex, 0)
        XCTAssertTrue(vm.comprehensionAnswers.isEmpty)
    }

    func testGenerateComprehensionQuestions() async {
        let vm = makeViewModel()
        await vm.generateComprehensionQuestions()
        XCTAssertFalse(vm.comprehensionQuestions.isEmpty, "Mock should generate questions")
        XCTAssertFalse(vm.isGeneratingQuestions)
    }

    func testSubmitComprehensionCorrectAnswer() async {
        let vm = makeViewModel()
        await vm.generateComprehensionQuestions()
        guard let question = vm.currentComprehensionQuestion else {
            XCTFail("Should have a question")
            return
        }
        vm.submitComprehensionAnswer(question.correctAnswer)
        XCTAssertEqual(vm.comprehensionAnswers.count, 1)
        XCTAssertTrue(vm.comprehensionAnswers.first?.wasCorrect ?? false)
        XCTAssertTrue(vm.comprehensionShowingFeedback)
    }

    func testSubmitComprehensionWrongAnswer() async {
        let vm = makeViewModel()
        await vm.generateComprehensionQuestions()
        guard vm.currentComprehensionQuestion != nil else { return }
        vm.submitComprehensionAnswer("definitely wrong answer")
        XCTAssertEqual(vm.comprehensionAnswers.count, 1)
        XCTAssertFalse(vm.comprehensionAnswers.first?.wasCorrect ?? true)
    }

    func testNextComprehensionQuestion() async {
        let vm = makeViewModel()
        await vm.generateComprehensionQuestions()
        guard vm.currentComprehensionQuestion != nil else { return }
        vm.submitComprehensionAnswer("answer")
        vm.nextComprehensionQuestion()
        XCTAssertEqual(vm.comprehensionCurrentIndex, 1)
        XCTAssertFalse(vm.comprehensionShowingFeedback)
    }

    func testComprehensionScoreCalculation() async {
        let vm = makeViewModel()
        await vm.generateComprehensionQuestions()
        guard let q = vm.currentComprehensionQuestion else { return }

        // Answer correctly
        vm.submitComprehensionAnswer(q.correctAnswer)
        XCTAssertEqual(vm.comprehensionScore, 1.0, accuracy: 0.01)

        vm.nextComprehensionQuestion()
        // Answer incorrectly
        vm.submitComprehensionAnswer("wrong")
        XCTAssertEqual(vm.comprehensionScore, 0.5, accuracy: 0.01)
    }

    func testComprehensionProgressUpdates() async {
        let vm = makeViewModel()
        await vm.generateComprehensionQuestions()
        XCTAssertEqual(vm.comprehensionProgress, 0, accuracy: 0.01)
    }

    // MARK: - Vocabulary Extraction Tests

    func testToggleWordSelection() {
        let vm = makeViewModel()
        guard let word = vm.extractedWords.first else { return }
        XCTAssertFalse(vm.selectedWordIds.contains(word.id))
        vm.toggleWordSelection(word.id)
        XCTAssertTrue(vm.selectedWordIds.contains(word.id))
        vm.toggleWordSelection(word.id)
        XCTAssertFalse(vm.selectedWordIds.contains(word.id))
    }

    func testSelectAllWords() {
        let vm = makeViewModel()
        vm.selectAllWords()
        XCTAssertEqual(vm.selectedWordIds.count, vm.extractedWords.count)
    }

    func testDeselectAllWords() {
        let vm = makeViewModel()
        vm.selectAllWords()
        vm.deselectAllWords()
        XCTAssertTrue(vm.selectedWordIds.isEmpty)
    }

    func testSelectedWordCount() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.selectedWordCount, 0)
        vm.selectAllWords()
        XCTAssertEqual(vm.selectedWordCount, vm.extractedWords.count)
    }

    func testAddSelectedWordsToSRS() {
        let vm = makeViewModel()
        vm.selectAllWords()
        // Should not crash
        vm.addSelectedWordsToSRS()
    }

    // MARK: - Shadowing Tests

    func testShadowingInitialState() {
        let vm = makeViewModel(contentType: "drama")
        XCTAssertEqual(vm.shadowingCurrentIndex, 0)
        XCTAssertNotNil(vm.currentShadowingSentence)
    }

    func testRecordShadowingAttempt() {
        let vm = makeViewModel(contentType: "drama")
        guard !vm.shadowingSentences.isEmpty else { return }
        vm.recordShadowingAttempt(transcript: "test", confidence: 0.8)
        XCTAssertEqual(vm.shadowingSentences[0].attempts, 1)
        XCTAssertEqual(vm.shadowingSentences[0].bestConfidence, 0.8)
        XCTAssertEqual(vm.shadowingSentences[0].bestTranscript, "test")
    }

    func testRecordShadowingBetterAttemptUpdatesBest() {
        let vm = makeViewModel(contentType: "drama")
        guard !vm.shadowingSentences.isEmpty else { return }
        vm.recordShadowingAttempt(transcript: "first", confidence: 0.5)
        vm.recordShadowingAttempt(transcript: "second", confidence: 0.9)
        XCTAssertEqual(vm.shadowingSentences[0].attempts, 2)
        XCTAssertEqual(vm.shadowingSentences[0].bestConfidence, 0.9)
        XCTAssertEqual(vm.shadowingSentences[0].bestTranscript, "second")
    }

    func testRecordShadowingWorseAttemptDoesNotUpdateBest() {
        let vm = makeViewModel(contentType: "drama")
        guard !vm.shadowingSentences.isEmpty else { return }
        vm.recordShadowingAttempt(transcript: "good", confidence: 0.9)
        vm.recordShadowingAttempt(transcript: "worse", confidence: 0.3)
        XCTAssertEqual(vm.shadowingSentences[0].bestConfidence, 0.9)
        XCTAssertEqual(vm.shadowingSentences[0].bestTranscript, "good")
    }

    func testNextShadowingSentence() {
        let vm = makeViewModel(contentType: "drama")
        guard vm.shadowingSentences.count > 1 else { return }
        vm.nextShadowingSentence()
        XCTAssertEqual(vm.shadowingCurrentIndex, 1)
    }

    func testShadowingProgressUpdates() {
        let vm = makeViewModel(contentType: "drama")
        guard vm.shadowingSentences.count > 1 else { return }
        XCTAssertEqual(vm.shadowingProgress, 0, accuracy: 0.01)
        vm.nextShadowingSentence()
        XCTAssertGreaterThan(vm.shadowingProgress, 0)
    }

    func testCurrentShadowingSentenceNilWhenComplete() {
        let vm = makeViewModel(contentType: "drama")
        for _ in vm.shadowingSentences {
            vm.nextShadowingSentence()
        }
        XCTAssertNil(vm.currentShadowingSentence)
    }

    // MARK: - Summary Tests

    func testBuildSummary() {
        let vm = makeViewModel()
        // Simulate some lesson activity
        for _ in vm.preTaskWords {
            vm.revealPreTaskAnswer()
            vm.submitPreTaskAnswer(knewIt: true)
        }
        vm.selectAllWords()
        vm.addSelectedWordsToSRS()
        vm.buildSummary()

        XCTAssertNotNil(vm.sessionSummary)
        XCTAssertEqual(vm.sessionSummary?.wordsPreTaught, vm.preTaskWords.count)
        XCTAssertEqual(vm.sessionSummary?.wordsKnown, vm.preTaskWords.count)
        XCTAssertEqual(vm.sessionSummary?.wordsAddedToSRS, vm.extractedWords.count)
        XCTAssertEqual(vm.sessionSummary?.contentTitle, "Test Drama Episode")
    }

    func testBuildSummaryWithMixedPreTaskResults() {
        let vm = makeViewModel()
        guard vm.preTaskWords.count >= 2 else { return }
        vm.revealPreTaskAnswer()
        vm.submitPreTaskAnswer(knewIt: true)
        vm.revealPreTaskAnswer()
        vm.submitPreTaskAnswer(knewIt: false)
        // Skip remaining
        while vm.preTaskCurrentIndex < vm.preTaskWords.count {
            vm.revealPreTaskAnswer()
            vm.submitPreTaskAnswer(knewIt: false)
        }
        vm.buildSummary()

        XCTAssertNotNil(vm.sessionSummary)
        XCTAssertEqual(vm.sessionSummary?.wordsKnown, 1)
    }

    func testCreateStudySession() {
        let vm = makeViewModel()
        let session = vm.createStudySession()
        XCTAssertEqual(session.sessionType, "media")
        XCTAssertEqual(session.mediaContentId, vm.content.id)
        XCTAssertNotNil(session.completedAt)
        XCTAssertEqual(session.sessionData["contentType"], "drama")
    }

    // MARK: - Full Flow Test

    func testFullLessonFlow() async {
        let vm = makeViewModel(contentType: "drama")

        // Step 1: Pre-task
        XCTAssertEqual(vm.currentStep, .preTask)
        for _ in vm.preTaskWords {
            vm.revealPreTaskAnswer()
            vm.submitPreTaskAnswer(knewIt: true)
        }
        XCTAssertTrue(vm.canAdvance)
        vm.advanceToNextStep()

        // Step 2: First listen
        XCTAssertEqual(vm.currentStep, .firstListen)
        vm.completeFirstListen()
        vm.advanceToNextStep()

        // Step 3: Second listen
        XCTAssertEqual(vm.currentStep, .secondListen)
        vm.completeSecondListen()
        vm.advanceToNextStep()

        // Step 4: Comprehension check
        XCTAssertEqual(vm.currentStep, .comprehensionCheck)
        // Wait for questions to generate
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        // Complete comprehension (may be empty from mock)
        vm.advanceToNextStep()

        // Step 5: Vocabulary extraction
        XCTAssertEqual(vm.currentStep, .vocabularyExtraction)
        vm.selectAllWords()
        vm.addSelectedWordsToSRS()
        vm.advanceToNextStep()

        // Step 6: Shadowing
        XCTAssertEqual(vm.currentStep, .shadowingPractice)
        for _ in vm.shadowingSentences {
            vm.recordShadowingAttempt(transcript: "test", confidence: 0.8)
            vm.nextShadowingSentence()
        }
        vm.advanceToNextStep()

        // Step 7: Summary
        XCTAssertEqual(vm.currentStep, .summary)
        XCTAssertNotNil(vm.sessionSummary)
        XCTAssertFalse(vm.canAdvance)
    }

    func testFullLessonFlowForTextContent() async {
        let vm = makeViewModel(contentType: "news")

        // Pre-task
        for _ in vm.preTaskWords {
            vm.revealPreTaskAnswer()
            vm.submitPreTaskAnswer(knewIt: false)
        }
        vm.advanceToNextStep()

        // First listen
        vm.completeFirstListen()
        vm.advanceToNextStep()

        // Second listen
        vm.completeSecondListen()
        vm.advanceToNextStep()

        // Comprehension
        vm.advanceToNextStep()

        // Vocabulary extraction
        vm.advanceToNextStep()

        // Should skip shadowing and go to summary
        XCTAssertEqual(vm.currentStep, .summary)
        XCTAssertNotNil(vm.sessionSummary)
    }

    // MARK: - Edge Cases

    func testEmptyTranscriptHandled() {
        let content = MediaContent(
            title: "Empty Content",
            contentType: "drama",
            transcriptKr: "",
            transcriptSegments: []
        )
        let vm = MediaLessonViewModel(
            content: content,
            claudeService: MockClaudeService(),
            srsEngine: MockSRSEngine(),
            learnerModel: MockLearnerModelService(),
            audioService: MockAudioService(),
            speechRecognition: MockSpeechRecognitionService(),
            userId: UUID(),
            learnerLevel: "A1"
        )
        XCTAssertTrue(vm.preTaskWords.isEmpty)
        XCTAssertTrue(vm.extractedWords.isEmpty)
        XCTAssertTrue(vm.canAdvance, "Empty pre-task should allow advance")
    }

    func testGoToInvalidStep() {
        let vm = makeViewModel(contentType: "news")
        vm.goToStep(.shadowingPractice) // Not available for news
        XCTAssertNotEqual(vm.currentStep, .shadowingPractice)
    }
}
