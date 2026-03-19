import XCTest
@testable import Hallyu

final class ShadowingViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeViewModel(contentType: String = "drama") -> MediaLessonViewModel {
        let content = MediaContent(
            title: "Shadowing Test",
            contentType: contentType,
            transcriptKr: "사랑하는 친구야 오늘 학교에서 뭐 했어",
            transcriptSegments: [
                MediaContent.TranscriptSegment(startMs: 0, endMs: 3000, textKr: "사랑하는 친구야", textEn: "Dear friend"),
                MediaContent.TranscriptSegment(startMs: 3000, endMs: 6000, textKr: "오늘 학교에서 뭐 했어?", textEn: "What did you do at school today?"),
                MediaContent.TranscriptSegment(startMs: 6000, endMs: 9000, textKr: "집에 가고 싶어", textEn: "I want to go home"),
                MediaContent.TranscriptSegment(startMs: 9000, endMs: 12000, textKr: "엄마가 밥 만들었어", textEn: "Mom made food"),
                MediaContent.TranscriptSegment(startMs: 12000, endMs: 15000, textKr: "내일 회사에 가야 해", textEn: "I have to go to work tomorrow"),
                MediaContent.TranscriptSegment(startMs: 15000, endMs: 18000, textKr: "지금 뭐 하고 있어?", textEn: "What are you doing now?"),
            ]
        )
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

    // MARK: - Initialization

    func testShadowingSentencesForDrama() {
        let vm = makeViewModel(contentType: "drama")
        XCTAssertFalse(vm.shadowingSentences.isEmpty)
        XCTAssertLessThanOrEqual(vm.shadowingSentences.count, 3, "Should select at most 3 sentences")
    }

    func testShadowingSentencesForShortVideo() {
        let vm = makeViewModel(contentType: "short_video")
        XCTAssertFalse(vm.shadowingSentences.isEmpty)
    }

    func testNoShadowingSentencesForWebtoon() {
        let vm = makeViewModel(contentType: "webtoon")
        XCTAssertTrue(vm.shadowingSentences.isEmpty)
    }

    func testNoShadowingSentencesForNews() {
        let vm = makeViewModel(contentType: "news")
        XCTAssertTrue(vm.shadowingSentences.isEmpty)
    }

    func testShadowingSentencesHaveKoreanText() {
        let vm = makeViewModel()
        for sentence in vm.shadowingSentences {
            XCTAssertFalse(sentence.korean.isEmpty)
        }
    }

    func testShadowingSentencesHaveEnglishTranslation() {
        let vm = makeViewModel()
        for sentence in vm.shadowingSentences {
            XCTAssertFalse(sentence.english.isEmpty)
        }
    }

    func testShadowingSentencesHaveTimestamps() {
        let vm = makeViewModel()
        for sentence in vm.shadowingSentences {
            XCTAssertGreaterThanOrEqual(sentence.endMs, sentence.startMs)
        }
    }

    func testShadowingSentencesInitialAttempts() {
        let vm = makeViewModel()
        for sentence in vm.shadowingSentences {
            XCTAssertEqual(sentence.attempts, 0)
            XCTAssertEqual(sentence.bestConfidence, 0)
            XCTAssertTrue(sentence.bestTranscript.isEmpty)
        }
    }

    // MARK: - Recording Attempts

    func testRecordFirstAttempt() {
        let vm = makeViewModel()
        guard !vm.shadowingSentences.isEmpty else { return }
        vm.recordShadowingAttempt(transcript: "사랑하는 친구야", confidence: 0.85)
        XCTAssertEqual(vm.shadowingSentences[0].attempts, 1)
        XCTAssertEqual(vm.shadowingSentences[0].bestConfidence, 0.85)
        XCTAssertEqual(vm.shadowingSentences[0].bestTranscript, "사랑하는 친구야")
    }

    func testMultipleAttemptsTrackBest() {
        let vm = makeViewModel()
        guard !vm.shadowingSentences.isEmpty else { return }

        vm.recordShadowingAttempt(transcript: "first", confidence: 0.4)
        vm.recordShadowingAttempt(transcript: "second", confidence: 0.9)
        vm.recordShadowingAttempt(transcript: "third", confidence: 0.6)

        XCTAssertEqual(vm.shadowingSentences[0].attempts, 3)
        XCTAssertEqual(vm.shadowingSentences[0].bestConfidence, 0.9)
        XCTAssertEqual(vm.shadowingSentences[0].bestTranscript, "second")
    }

    func testRecordZeroConfidence() {
        let vm = makeViewModel()
        guard !vm.shadowingSentences.isEmpty else { return }
        vm.recordShadowingAttempt(transcript: "", confidence: 0.0)
        XCTAssertEqual(vm.shadowingSentences[0].attempts, 1)
        XCTAssertEqual(vm.shadowingSentences[0].bestConfidence, 0.0)
    }

    func testRecordPerfectConfidence() {
        let vm = makeViewModel()
        guard !vm.shadowingSentences.isEmpty else { return }
        vm.recordShadowingAttempt(transcript: "사랑하는 친구야", confidence: 1.0)
        XCTAssertEqual(vm.shadowingSentences[0].bestConfidence, 1.0)
    }

    // MARK: - Navigation

    func testNextShadowingSentence() {
        let vm = makeViewModel()
        guard vm.shadowingSentences.count > 1 else { return }
        XCTAssertEqual(vm.shadowingCurrentIndex, 0)
        vm.nextShadowingSentence()
        XCTAssertEqual(vm.shadowingCurrentIndex, 1)
    }

    func testCurrentSentenceChangesOnNext() {
        let vm = makeViewModel()
        guard vm.shadowingSentences.count > 1 else { return }
        let first = vm.currentShadowingSentence
        vm.nextShadowingSentence()
        let second = vm.currentShadowingSentence
        XCTAssertNotEqual(first?.id, second?.id)
    }

    func testNavigatePastEnd() {
        let vm = makeViewModel()
        for _ in vm.shadowingSentences {
            vm.nextShadowingSentence()
        }
        XCTAssertNil(vm.currentShadowingSentence)
        XCTAssertEqual(vm.shadowingCurrentIndex, vm.shadowingSentences.count)
    }

    func testShadowingProgressUpdates() {
        let vm = makeViewModel()
        guard vm.shadowingSentences.count > 1 else { return }
        let initialProgress = vm.shadowingProgress
        vm.nextShadowingSentence()
        XCTAssertGreaterThan(vm.shadowingProgress, initialProgress)
    }

    func testShadowingProgressComplete() {
        let vm = makeViewModel()
        for _ in vm.shadowingSentences {
            vm.nextShadowingSentence()
        }
        XCTAssertEqual(vm.shadowingProgress, 1.0, accuracy: 0.01)
    }

    // MARK: - Can Advance

    func testCanAdvanceWhenAllSentencesPracticed() {
        let vm = makeViewModel()
        vm.goToStep(.shadowingPractice)
        for _ in vm.shadowingSentences {
            vm.recordShadowingAttempt(transcript: "test", confidence: 0.8)
            vm.nextShadowingSentence()
        }
        XCTAssertTrue(vm.canAdvance)
    }

    func testCannotAdvanceWithSentencesRemaining() {
        let vm = makeViewModel()
        vm.goToStep(.shadowingPractice)
        guard !vm.shadowingSentences.isEmpty else { return }
        // Don't practice any
        XCTAssertFalse(vm.canAdvance)
    }

    // MARK: - Recording Only Affects Current Sentence

    func testRecordingDoesNotAffectOtherSentences() {
        let vm = makeViewModel()
        guard vm.shadowingSentences.count > 1 else { return }
        vm.recordShadowingAttempt(transcript: "test", confidence: 0.9)
        XCTAssertEqual(vm.shadowingSentences[0].attempts, 1)
        XCTAssertEqual(vm.shadowingSentences[1].attempts, 0, "Second sentence should be unaffected")
    }

    func testRecordingSecondSentence() {
        let vm = makeViewModel()
        guard vm.shadowingSentences.count > 1 else { return }
        vm.nextShadowingSentence()
        vm.recordShadowingAttempt(transcript: "second test", confidence: 0.7)
        XCTAssertEqual(vm.shadowingSentences[0].attempts, 0, "First sentence should be unaffected")
        XCTAssertEqual(vm.shadowingSentences[1].attempts, 1)
        XCTAssertEqual(vm.shadowingSentences[1].bestTranscript, "second test")
    }

    // MARK: - Empty Shadowing

    func testEmptyShadowingProgress() {
        let vm = makeViewModel(contentType: "news") // No shadowing
        XCTAssertEqual(vm.shadowingProgress, 1.0, accuracy: 0.01)
    }

    func testEmptyShadowingCanAdvance() {
        let vm = makeViewModel(contentType: "news")
        vm.goToStep(.vocabularyExtraction) // Skip to before shadowing
        // Shadowing should not be in available steps for news
        XCTAssertFalse(vm.availableSteps.contains(.shadowingPractice))
    }
}
