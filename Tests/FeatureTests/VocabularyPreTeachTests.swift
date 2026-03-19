import XCTest
@testable import Hallyu

final class VocabularyPreTeachTests: XCTestCase {

    // MARK: - Helpers

    private func makeViewModel(transcript: String = "사랑 친구 가족 엄마 아빠 학교 회사 집") -> MediaLessonViewModel {
        let content = MediaContent(
            title: "Test Content",
            contentType: "drama",
            transcriptKr: transcript,
            transcriptSegments: [
                MediaContent.TranscriptSegment(startMs: 0, endMs: 3000, textKr: "사랑하는 친구야", textEn: "Dear friend"),
                MediaContent.TranscriptSegment(startMs: 3000, endMs: 6000, textKr: "학교에서 뭐 했어?", textEn: "What did you do at school?"),
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

    // MARK: - Word Selection Logic

    func testPreTaskWordCountWithinRange() {
        let vm = makeViewModel()
        XCTAssertGreaterThanOrEqual(vm.preTaskWords.count, 0)
        XCTAssertLessThanOrEqual(vm.preTaskWords.count, 8, "Max 8 pre-task words")
    }

    func testPreTaskWordsHaveKoreanText() {
        let vm = makeViewModel()
        for word in vm.preTaskWords {
            XCTAssertFalse(word.korean.isEmpty, "Each word should have Korean text")
        }
    }

    func testPreTaskWordsHaveUniqueIds() {
        let vm = makeViewModel()
        let ids = vm.preTaskWords.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count, "All IDs should be unique")
    }

    // MARK: - Card Flip State

    func testInitiallyAnswerHidden() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.preTaskShowingAnswer)
    }

    func testRevealAnswer() {
        let vm = makeViewModel()
        vm.revealPreTaskAnswer()
        XCTAssertTrue(vm.preTaskShowingAnswer)
    }

    func testAnswerHiddenAfterSubmission() {
        let vm = makeViewModel()
        guard !vm.preTaskWords.isEmpty else { return }
        vm.revealPreTaskAnswer()
        vm.submitPreTaskAnswer(knewIt: true)
        XCTAssertFalse(vm.preTaskShowingAnswer)
    }

    // MARK: - Scoring

    func testAllKnownResults() {
        let vm = makeViewModel()
        for _ in vm.preTaskWords {
            vm.revealPreTaskAnswer()
            vm.submitPreTaskAnswer(knewIt: true)
        }
        let known = vm.preTaskResults.filter { $0.knewIt }.count
        XCTAssertEqual(known, vm.preTaskResults.count)
    }

    func testAllUnknownResults() {
        let vm = makeViewModel()
        for _ in vm.preTaskWords {
            vm.revealPreTaskAnswer()
            vm.submitPreTaskAnswer(knewIt: false)
        }
        let known = vm.preTaskResults.filter { $0.knewIt }.count
        XCTAssertEqual(known, 0)
    }

    func testMixedResults() {
        let vm = makeViewModel()
        guard vm.preTaskWords.count >= 2 else { return }
        vm.revealPreTaskAnswer()
        vm.submitPreTaskAnswer(knewIt: true)
        vm.revealPreTaskAnswer()
        vm.submitPreTaskAnswer(knewIt: false)
        XCTAssertEqual(vm.preTaskResults.count, 2)
        XCTAssertEqual(vm.preTaskResults.filter { $0.knewIt }.count, 1)
        XCTAssertEqual(vm.preTaskResults.filter { !$0.knewIt }.count, 1)
    }

    // MARK: - Progression

    func testAdvancesThroughAllWords() {
        let vm = makeViewModel()
        let wordCount = vm.preTaskWords.count
        for i in 0..<wordCount {
            XCTAssertEqual(vm.preTaskCurrentIndex, i)
            vm.revealPreTaskAnswer()
            vm.submitPreTaskAnswer(knewIt: true)
        }
        XCTAssertEqual(vm.preTaskCurrentIndex, wordCount)
        XCTAssertNil(vm.currentPreTaskWord)
    }

    func testProgressUpdatesLinearly() {
        let vm = makeViewModel()
        guard vm.preTaskWords.count >= 4 else { return }
        let progressValues: [Double] = (0..<vm.preTaskWords.count).map { i in
            let progress = vm.preTaskProgress
            vm.revealPreTaskAnswer()
            vm.submitPreTaskAnswer(knewIt: true)
            return progress
        }
        // Progress should be non-decreasing
        for i in 1..<progressValues.count {
            XCTAssertGreaterThanOrEqual(progressValues[i], progressValues[i - 1])
        }
    }

    // MARK: - Empty Transcript

    func testEmptyTranscriptProducesNoWords() {
        let vm = makeViewModel(transcript: "")
        XCTAssertTrue(vm.preTaskWords.isEmpty)
        XCTAssertEqual(vm.preTaskProgress, 1.0, accuracy: 0.01)
        XCTAssertTrue(vm.canAdvance, "Empty pre-task should be skippable")
    }

    // MARK: - Response Time Tracking

    func testResponseTimeRecorded() {
        let vm = makeViewModel()
        guard !vm.preTaskWords.isEmpty else { return }
        vm.revealPreTaskAnswer()
        vm.submitPreTaskAnswer(knewIt: true)
        XCTAssertGreaterThanOrEqual(vm.preTaskResults.first?.responseTime ?? -1, 0)
    }
}
