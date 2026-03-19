import Foundation
import Observation
import SwiftData

/// Orchestrates the end-to-end scaffolded media lesson flow.
/// Steps: preTask -> firstListen -> secondListen -> comprehensionCheck -> vocabularyExtraction -> shadowing -> summary
@MainActor
@Observable
final class MediaLessonViewModel {

    // MARK: - Lesson Step

    enum LessonStep: Int, CaseIterable, Comparable {
        case preTask = 0
        case firstListen = 1
        case secondListen = 2
        case comprehensionCheck = 3
        case vocabularyExtraction = 4
        case shadowingPractice = 5
        case summary = 6

        var title: String {
            switch self {
            case .preTask: return "Vocabulary Preview"
            case .firstListen: return "First Listen"
            case .secondListen: return "Guided Listen"
            case .comprehensionCheck: return "Comprehension"
            case .vocabularyExtraction: return "New Words"
            case .shadowingPractice: return "Shadowing"
            case .summary: return "Summary"
            }
        }

        var subtitle: String {
            switch self {
            case .preTask: return "Learn key words before watching"
            case .firstListen: return "Listen without subtitles"
            case .secondListen: return "Listen with Korean subtitles"
            case .comprehensionCheck: return "Test your understanding"
            case .vocabularyExtraction: return "Save new words to review"
            case .shadowingPractice: return "Practice speaking like a native"
            case .summary: return "See how you did"
            }
        }

        static func < (lhs: LessonStep, rhs: LessonStep) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - State

    let content: MediaContent
    private(set) var currentStep: LessonStep = .preTask
    private(set) var startTime: Date = Date()
    private(set) var stepStartTime: Date = Date()

    // Pre-task state
    private(set) var preTaskWords: [PreTaskWord] = []
    private(set) var preTaskCurrentIndex: Int = 0
    private(set) var preTaskShowingAnswer: Bool = false
    private(set) var preTaskResults: [PreTaskResult] = []

    // Media playback state (managed by MediaPlayerView externally)
    private(set) var firstListenCompleted: Bool = false
    private(set) var secondListenCompleted: Bool = false

    // Comprehension state
    private(set) var comprehensionQuestions: [PracticeItem] = []
    private(set) var comprehensionCurrentIndex: Int = 0
    private(set) var comprehensionAnswers: [ComprehensionAnswer] = []
    private(set) var comprehensionShowingFeedback: Bool = false
    private(set) var isGeneratingQuestions: Bool = false

    // Vocabulary extraction state
    private(set) var extractedWords: [ExtractedWord] = []
    private(set) var selectedWordIds: Set<UUID> = []
    private(set) var persistedWordIds: Set<UUID> = []

    // Shadowing state
    private(set) var shadowingSentences: [ShadowingSentence] = []
    private(set) var shadowingCurrentIndex: Int = 0

    // Summary state
    private(set) var sessionSummary: LessonSummary?
    private(set) var didPersistStudySession: Bool = false

    // Services
    let claudeService: ClaudeServiceProtocol
    let srsEngine: SRSEngineProtocol
    let learnerModel: LearnerModelServiceProtocol
    let audioService: AudioServiceProtocol
    let speechRecognition: SpeechRecognitionServiceProtocol
    let userId: UUID
    let learnerLevel: String

    // MARK: - Types

    struct PreTaskWord: Identifiable, Equatable {
        let id: UUID
        let korean: String
        let romanization: String
        let english: String
        let partOfSpeech: String
    }

    struct PreTaskResult: Equatable {
        let wordId: UUID
        let knewIt: Bool
        let responseTime: TimeInterval
    }

    struct ComprehensionAnswer: Equatable {
        let questionIndex: Int
        let selectedAnswer: String
        let wasCorrect: Bool
    }

    struct ExtractedWord: Identifiable, Equatable {
        let id: UUID
        let korean: String
        let english: String
        let romanization: String
        let frequencyRank: Int?
    }

    struct ShadowingSentence: Identifiable, Equatable {
        let id: UUID
        let korean: String
        let english: String
        let startMs: Int
        let endMs: Int
        var attempts: Int = 0
        var bestTranscript: String = ""
        var bestConfidence: Double = 0
    }

    struct LessonSummary: Equatable {
        let totalDurationSeconds: Int
        let wordsPreTaught: Int
        let wordsKnown: Int
        let comprehensionScore: Double
        let wordsAddedToSRS: Int
        let sentencesShadowed: Int
        let contentTitle: String
    }

    // MARK: - Init

    init(
        content: MediaContent,
        claudeService: ClaudeServiceProtocol,
        srsEngine: SRSEngineProtocol,
        learnerModel: LearnerModelServiceProtocol,
        audioService: AudioServiceProtocol,
        speechRecognition: SpeechRecognitionServiceProtocol,
        userId: UUID,
        learnerLevel: String
    ) {
        self.content = content
        self.claudeService = claudeService
        self.srsEngine = srsEngine
        self.learnerModel = learnerModel
        self.audioService = audioService
        self.speechRecognition = speechRecognition
        self.userId = userId
        self.learnerLevel = learnerLevel

        setupPreTaskWords()
        setupExtractedWords()
        setupShadowingSentences()
    }

    // MARK: - Navigation

    var availableSteps: [LessonStep] {
        if content.contentType == "webtoon" || content.contentType == "news" {
            // Text content skips shadowing
            return LessonStep.allCases.filter { $0 != .shadowingPractice }
        }
        return LessonStep.allCases
    }

    var currentStepIndex: Int {
        availableSteps.firstIndex(of: currentStep) ?? 0
    }

    var totalSteps: Int {
        availableSteps.count
    }

    var progress: Double {
        guard totalSteps > 1 else { return 0 }
        return Double(currentStepIndex) / Double(totalSteps - 1)
    }

    var canAdvance: Bool {
        switch currentStep {
        case .preTask:
            return preTaskCurrentIndex >= preTaskWords.count || preTaskWords.isEmpty
        case .firstListen:
            return firstListenCompleted
        case .secondListen:
            return secondListenCompleted
        case .comprehensionCheck:
            return comprehensionCurrentIndex >= comprehensionQuestions.count || comprehensionQuestions.isEmpty
        case .vocabularyExtraction:
            return true // User can skip or select words
        case .shadowingPractice:
            return shadowingCurrentIndex >= shadowingSentences.count || shadowingSentences.isEmpty
        case .summary:
            return false // End state
        }
    }

    func advanceToNextStep() {
        guard let nextIndex = availableSteps.firstIndex(of: currentStep).map({ $0 + 1 }),
              nextIndex < availableSteps.count else { return }

        let nextStep = availableSteps[nextIndex]
        currentStep = nextStep
        stepStartTime = Date()

        if nextStep == .comprehensionCheck && comprehensionQuestions.isEmpty {
            Task { await generateComprehensionQuestions() }
        }

        if nextStep == .summary {
            buildSummary()
        }
    }

    func goToStep(_ step: LessonStep) {
        guard availableSteps.contains(step) else { return }
        currentStep = step
        stepStartTime = Date()
    }

    // MARK: - Pre-Task Actions

    var currentPreTaskWord: PreTaskWord? {
        guard preTaskCurrentIndex < preTaskWords.count else { return nil }
        return preTaskWords[preTaskCurrentIndex]
    }

    var preTaskProgress: Double {
        guard !preTaskWords.isEmpty else { return 1.0 }
        return Double(preTaskCurrentIndex) / Double(preTaskWords.count)
    }

    func revealPreTaskAnswer() {
        preTaskShowingAnswer = true
    }

    func submitPreTaskAnswer(knewIt: Bool) {
        guard preTaskCurrentIndex < preTaskWords.count else { return }
        let word = preTaskWords[preTaskCurrentIndex]
        let responseTime = Date().timeIntervalSince(stepStartTime)

        let result = PreTaskResult(wordId: word.id, knewIt: knewIt, responseTime: responseTime)
        preTaskResults.append(result)

        // Update learner model
        Task {
            do {
                try await learnerModel.updateMastery(
                    userId: userId,
                    skillType: "vocab_recognition",
                    skillId: word.id.uuidString,
                    wasCorrect: knewIt,
                    responseTime: responseTime
                )
            } catch {
                print("[MediaLesson] Failed to update mastery: \(error.localizedDescription)")
            }
        }

        preTaskShowingAnswer = false
        preTaskCurrentIndex += 1
        stepStartTime = Date()
    }

    // MARK: - Media Playback Actions

    func completeFirstListen() {
        firstListenCompleted = true
    }

    func completeSecondListen() {
        secondListenCompleted = true
    }

    // MARK: - Comprehension Actions

    var currentComprehensionQuestion: PracticeItem? {
        guard comprehensionCurrentIndex < comprehensionQuestions.count else { return nil }
        return comprehensionQuestions[comprehensionCurrentIndex]
    }

    var comprehensionProgress: Double {
        guard !comprehensionQuestions.isEmpty else { return 1.0 }
        return Double(comprehensionCurrentIndex) / Double(comprehensionQuestions.count)
    }

    var comprehensionScore: Double {
        guard !comprehensionAnswers.isEmpty else { return 0 }
        return Double(comprehensionAnswers.filter { $0.wasCorrect }.count) / Double(comprehensionAnswers.count)
    }

    func generateComprehensionQuestions() async {
        isGeneratingQuestions = true
        do {
            let items = try await claudeService.generatePracticeItems(
                mediaContentId: content.id,
                learnerLevel: learnerLevel
            )
            comprehensionQuestions = items
        } catch {
            // Fallback: empty questions means step can be skipped
            comprehensionQuestions = []
        }
        isGeneratingQuestions = false
    }

    func submitComprehensionAnswer(_ answer: String) {
        guard comprehensionCurrentIndex < comprehensionQuestions.count else { return }
        let question = comprehensionQuestions[comprehensionCurrentIndex]
        let isCorrect = answer.lowercased().trimmingCharacters(in: .whitespaces)
            == question.correctAnswer.lowercased().trimmingCharacters(in: .whitespaces)

        let result = ComprehensionAnswer(
            questionIndex: comprehensionCurrentIndex,
            selectedAnswer: answer,
            wasCorrect: isCorrect
        )
        comprehensionAnswers.append(result)
        comprehensionShowingFeedback = true

        // Update learner model
        let skillType = question.type == "comprehension" ? "listening" : "vocab_recognition"
        let responseTime = Date().timeIntervalSince(stepStartTime)
        Task {
            do {
                try await learnerModel.updateMastery(
                    userId: userId,
                    skillType: skillType,
                    skillId: "\(content.id)_q\(comprehensionCurrentIndex)",
                    wasCorrect: isCorrect,
                    responseTime: responseTime
                )
            } catch {
                print("[MediaLesson] Failed to update comprehension mastery: \(error.localizedDescription)")
            }
        }
    }

    func nextComprehensionQuestion() {
        comprehensionShowingFeedback = false
        comprehensionCurrentIndex += 1
    }

    // MARK: - Vocabulary Extraction Actions

    func toggleWordSelection(_ wordId: UUID) {
        if selectedWordIds.contains(wordId) {
            selectedWordIds.remove(wordId)
        } else {
            selectedWordIds.insert(wordId)
        }
    }

    func selectAllWords() {
        selectedWordIds = Set(extractedWords.map { $0.id })
    }

    func deselectAllWords() {
        selectedWordIds.removeAll()
    }

    @discardableResult
    func addSelectedWordsToSRS(modelContext: ModelContext?) -> Int {
        guard let modelContext else {
            persistedWordIds.formUnion(selectedWordIds)
            buildSummary()
            return selectedWordIds.count
        }

        var addedCount = 0
        let existingItems = (try? modelContext.fetch(FetchDescriptor<ReviewItem>())) ?? []
        var existingWordIds = Set(
            existingItems
                .filter { $0.userId == userId && $0.itemType == "vocabulary" }
                .map(\.itemId)
        )

        for word in extractedWords where selectedWordIds.contains(word.id) {
            if existingWordIds.contains(word.id) {
                persistedWordIds.insert(word.id)
                continue
            }

            let reviewItem = ReviewItem(
                userId: userId,
                itemType: "vocabulary",
                itemId: word.id,
                promptText: word.korean,
                answerText: word.english,
                sourceContext: content.title
            )
            modelContext.insert(reviewItem)
            persistedWordIds.insert(word.id)
            existingWordIds.insert(word.id)
            addedCount += 1
        }

        try? modelContext.save()
        buildSummary()
        return addedCount
    }

    var selectedWordCount: Int {
        selectedWordIds.count
    }

    // MARK: - Shadowing Actions

    var currentShadowingSentence: ShadowingSentence? {
        guard shadowingCurrentIndex < shadowingSentences.count else { return nil }
        return shadowingSentences[shadowingCurrentIndex]
    }

    var shadowingProgress: Double {
        guard !shadowingSentences.isEmpty else { return 1.0 }
        return Double(shadowingCurrentIndex) / Double(shadowingSentences.count)
    }

    func recordShadowingAttempt(transcript: String, confidence: Double) {
        let attemptIndex = shadowingCurrentIndex
        guard attemptIndex < shadowingSentences.count else { return }

        shadowingSentences[attemptIndex].attempts += 1
        if confidence > shadowingSentences[attemptIndex].bestConfidence {
            shadowingSentences[attemptIndex].bestTranscript = transcript
            shadowingSentences[attemptIndex].bestConfidence = confidence
        }

        let sentenceId = shadowingSentences[attemptIndex].id

        // Update learner model for pronunciation
        Task {
            do {
                try await learnerModel.updateMastery(
                    userId: userId,
                    skillType: "pronunciation",
                    skillId: sentenceId.uuidString,
                    wasCorrect: confidence >= 0.7,
                    responseTime: 0
                )
            } catch {
                print("[MediaLesson] Failed to update pronunciation mastery: \(error.localizedDescription)")
            }
        }
    }

    func getPronunciationFeedback(transcript: String, target: String) async -> PronunciationFeedback? {
        try? await claudeService.getPronunciationFeedback(transcript: transcript, target: target)
    }

    func nextShadowingSentence() {
        shadowingCurrentIndex += 1
    }

    // MARK: - Summary

    func buildSummary() {
        let totalDuration = Int(Date().timeIntervalSince(startTime))
        let wordsKnown = preTaskResults.filter { $0.knewIt }.count

        sessionSummary = LessonSummary(
            totalDurationSeconds: totalDuration,
            wordsPreTaught: preTaskWords.count,
            wordsKnown: wordsKnown,
            comprehensionScore: comprehensionScore,
            wordsAddedToSRS: persistedWordIds.count,
            sentencesShadowed: shadowingSentences.prefix(shadowingCurrentIndex).count,
            contentTitle: content.title
        )
    }

    func createStudySession() -> StudySession {
        let totalDuration = Int(Date().timeIntervalSince(startTime))
        return StudySession(
            userId: userId,
            sessionType: "media",
            durationSeconds: totalDuration,
            itemsStudied: preTaskWords.count + comprehensionQuestions.count + shadowingSentences.count,
            itemsCorrect: preTaskResults.filter { $0.knewIt }.count + comprehensionAnswers.filter { $0.wasCorrect }.count,
            mediaContentId: content.id,
            sessionData: [
                "contentType": content.contentType,
                "cefrLevel": content.cefrLevel,
                "wordsAddedToSRS": "\(persistedWordIds.count)",
                "comprehensionScore": String(format: "%.2f", comprehensionScore),
                "sentencesShadowed": "\(shadowingCurrentIndex)"
            ],
            startedAt: startTime,
            completedAt: Date()
        )
    }

    func saveStudySessionIfNeeded(modelContext: ModelContext?) {
        guard !didPersistStudySession, let modelContext else { return }
        let session = createStudySession()
        modelContext.insert(session)
        try? modelContext.save()
        didPersistStudySession = true
    }

    // MARK: - Setup Helpers

    private func setupPreTaskWords() {
        // Extract vocabulary from content's vocabulary IDs
        // For now, derive from transcript using KoreanTextAnalyzer
        let tokens = KoreanTextAnalyzer.tokenize(content.transcriptKr)
        let uniqueTokens = Array(Set(tokens)).sorted { a, b in
            (KoreanTextAnalyzer.frequencyRank(for: a) ?? Int.max) <
            (KoreanTextAnalyzer.frequencyRank(for: b) ?? Int.max)
        }

        // Pick 5-8 key words (high frequency, likely unknown)
        preTaskWords = Array(uniqueTokens.prefix(8)).map { token in
            PreTaskWord(
                id: deterministicUUID(for: "pretask_\(token)"),
                korean: token,
                romanization: "",
                english: gloss(for: token),
                partOfSpeech: "noun"
            )
        }
    }

    private func setupExtractedWords() {
        let tokens = KoreanTextAnalyzer.tokenize(content.transcriptKr)
        let uniqueTokens = Array(Set(tokens))

        extractedWords = uniqueTokens.prefix(15).map { token in
            ExtractedWord(
                id: deterministicUUID(for: "extracted_\(token)"),
                korean: token,
                english: gloss(for: token),
                romanization: "",
                frequencyRank: KoreanTextAnalyzer.frequencyRank(for: token)
            )
        }
    }

    private func setupShadowingSentences() {
        guard content.contentType != "webtoon" && content.contentType != "news" else { return }

        // Pick 2-3 key sentences from transcript segments
        let segments = content.transcriptSegments
        let selectedSegments = selectKeySegments(from: segments, count: 3)

        shadowingSentences = selectedSegments.map { segment in
            ShadowingSentence(
                id: UUID(),
                korean: segment.textKr,
                english: segment.textEn,
                startMs: segment.startMs,
                endMs: segment.endMs
            )
        }
    }

    private func selectKeySegments(from segments: [MediaContent.TranscriptSegment], count: Int) -> [MediaContent.TranscriptSegment] {
        guard !segments.isEmpty else { return [] }
        // Select evenly spaced segments for variety
        let step = max(1, segments.count / max(count, 1))
        var selected: [MediaContent.TranscriptSegment] = []
        var index = 0
        while selected.count < count && index < segments.count {
            selected.append(segments[index])
            index += step
        }
        return selected
    }

    private func deterministicUUID(for value: String) -> UUID {
        var hash: UInt64 = 1469598103934665603
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }

        let bytes = withUnsafeBytes(of: hash.bigEndian) { Array($0) }
        var uuidBytes = [UInt8](repeating: 0, count: 16)
        for i in 0..<8 {
            uuidBytes[i] = bytes[i]
            uuidBytes[i + 8] = bytes[i] ^ 0xA5
        }
        uuidBytes[6] = (uuidBytes[6] & 0x0F) | 0x40
        uuidBytes[8] = (uuidBytes[8] & 0x3F) | 0x80

        return UUID(uuid: (
            uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
            uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
            uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
            uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]
        ))
    }

    private func gloss(for token: String) -> String {
        let glossary: [String: String] = [
            "안녕하세요": "hello",
            "감사합니다": "thank you",
            "미안": "sorry",
            "오늘": "today",
            "내일": "tomorrow",
            "어제": "yesterday",
            "시간": "time",
            "사람": "person",
            "친구": "friend",
            "가족": "family",
            "학교": "school",
            "회사": "company",
            "집": "home",
            "물": "water",
            "밥": "rice/meal",
            "커피": "coffee",
            "영화": "movie",
            "드라마": "drama",
            "노래": "song",
            "날씨": "weather",
            "좋다": "to be good",
            "하다": "to do",
            "먹다": "to eat",
            "가다": "to go",
            "오다": "to come",
            "보다": "to see/watch",
            "듣다": "to listen",
            "읽다": "to read",
        ]

        return glossary[token] ?? "Use Claude Coach for context-aware meaning"
    }
}
