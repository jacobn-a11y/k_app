import Foundation
import Observation

@MainActor
@Observable
final class OnboardingViewModel {

    // MARK: - Types

    enum Step: Int, CaseIterable {
        case hook = 0
        case promise
        case firstSound
        case firstConsonant
        case firstWord
        case journeyAhead
        case personalize
    }

    enum KoreanExperience: String, CaseIterable {
        case none = "No, I'm starting fresh"
        case some = "I know some Korean"
        case hangulOnly = "I can read Hangul but that's it"
    }

    enum MediaInterest: String, CaseIterable, Identifiable {
        case drama = "K-Dramas"
        case music = "K-Pop"
        case webtoon = "Webtoons"
        case news = "News"
        case variety = "Variety Shows"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .drama: return "play.rectangle.fill"
            case .music: return "music.note"
            case .webtoon: return "book.fill"
            case .news: return "newspaper.fill"
            case .variety: return "tv.fill"
            }
        }

        var teaser: String {
            switch self {
            case .drama: return "Understand what your favorite characters are really saying"
            case .music: return "Sing along and know every word"
            case .webtoon: return "Read the originals, not the translations"
            case .news: return "Get the story straight from the source"
            case .variety: return "Catch every joke and reaction"
            }
        }
    }

    enum DailyGoal: Int, CaseIterable {
        case light = 15
        case moderate = 20
        case committed = 30

        var label: String {
            switch self {
            case .light: return "15 min"
            case .moderate: return "20 min"
            case .committed: return "30 min"
            }
        }

        var description: String {
            switch self {
            case .light: return "Light"
            case .moderate: return "Moderate"
            case .committed: return "Committed"
            }
        }

        var emoji: String {
            switch self {
            case .light: return "15"
            case .moderate: return "20"
            case .committed: return "30"
            }
        }

        var subtitle: String {
            switch self {
            case .light: return "A few minutes a day adds up fast"
            case .moderate: return "The sweet spot for steady progress"
            case .committed: return "You'll be reading subtitles in no time"
            }
        }
    }

    // MARK: - State

    private(set) var currentStep: Step = .hook
    var selectedMediaInterests: Set<MediaInterest> = []
    var selectedExperience: KoreanExperience?
    var selectedGoal: DailyGoal = .light
    private(set) var hasSpokenFirstJamo: Bool = false
    private(set) var hasLearnedConsonant: Bool = false
    private(set) var hasBuiltFirstWord: Bool = false
    private(set) var firstLessonMicState: FirstLessonMicState = .idle
    private(set) var firstLessonTranscript: String = ""
    private(set) var firstLessonConfidence: Double = 0
    private(set) var isComplete: Bool = false
    private(set) var shouldShowPlacementTest: Bool = false
    private(set) var placedCEFRLevel: String?

    // Animation state for the hook step
    var hookAnimationPhase: Int = 0
    var promiseAnimationPhase: Int = 0
    var firstWordRevealed: Bool = false

    private static let firstLessonConfidenceThreshold: Double = 0.7
    private static let acceptedFirstLessonTranscripts: Set<String> = [
        "a",
        "ah",
        "아",
        "ㅏ",
        "아!",
        "아아",
    ]

    private static let acceptedConsonantTranscripts: Set<String> = [
        "g",
        "k",
        "ga",
        "guh",
        "그",
        "ㄱ",
        "기역",
    ]

    private static let acceptedFirstWordTranscripts: Set<String> = [
        "ga",
        "ka",
        "gah",
        "가",
        "가!",
    ]

    enum FirstLessonMicState: Equatable {
        case idle
        case recording
        case processing
        case success(String)
        case error(String)
    }

    // MARK: - Computed

    var canProceed: Bool {
        switch currentStep {
        case .hook:
            return hookAnimationPhase >= 2
        case .promise:
            return promiseAnimationPhase >= 1
        case .firstSound:
            return hasSpokenFirstJamo
        case .firstConsonant:
            return hasLearnedConsonant
        case .firstWord:
            return hasBuiltFirstWord
        case .journeyAhead:
            return !selectedMediaInterests.isEmpty
        case .personalize:
            return selectedExperience != nil
        }
    }

    var isFirstStep: Bool {
        currentStep == .hook
    }

    var isLastStep: Bool {
        currentStep == .personalize
    }

    var progressFraction: Double {
        Double(currentStep.rawValue + 1) / Double(Step.allCases.count)
    }

    // MARK: - Hook & Promise Content

    static let hookKoreanLine = "사랑해"
    static let hookEnglishLine = "I love you"
    static let hookContextLine = "You've heard this a hundred times in K-dramas."

    static let promiseTitle = "In 10 minutes, you'll\nread your first Korean word."
    static let promiseSubtitle = "Korean has an alphabet, just like English.\nEach letter is a building block."

    // MARK: - First Sound Content

    static let firstSoundCharacter = "ㅏ"
    static let firstSoundLabel = "ah"
    static let firstSoundHint = "Like the 'a' in 'father'"

    // MARK: - First Consonant Content

    static let firstConsonantCharacter = "ㄱ"
    static let firstConsonantLabel = "g"
    static let firstConsonantHint = "Like the 'g' in 'go'"

    // MARK: - First Word Content

    static let firstWordCharacter = "가"
    static let firstWordMeaning = "go"
    static let firstWordBreakdown = "ㄱ + ㅏ"

    // MARK: - Journey Milestones

    struct JourneyMilestone: Identifiable {
        let id = UUID()
        let timeframe: String
        let headline: String
        let detail: String
        let icon: String
    }

    static let journeyMilestones: [JourneyMilestone] = [
        JourneyMilestone(timeframe: "Today", headline: "Read your first word", detail: "You just did this", icon: "checkmark.circle.fill"),
        JourneyMilestone(timeframe: "This week", headline: "Read all of Hangul", detail: "40 letters, one building block at a time", icon: "character.book.closed.fill"),
        JourneyMilestone(timeframe: "Week 2", headline: "Your first K-drama clip", detail: "Watch a real scene with scaffolded support", icon: "play.rectangle.fill"),
        JourneyMilestone(timeframe: "Month 1", headline: "Follow conversations", detail: "Understand basic dialogue without subtitles", icon: "bubble.left.and.bubble.right.fill"),
        JourneyMilestone(timeframe: "Month 3", headline: "Consume real media", detail: "News, webtoons, music — in Korean", icon: "star.fill"),
    ]

    // MARK: - Actions

    func advance() {
        guard canProceed else { return }

        if currentStep == .personalize, selectedExperience == .some {
            shouldShowPlacementTest = true
            return
        }

        if let next = Step(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }

    func goBack() {
        if let prev = Step(rawValue: currentStep.rawValue - 1) {
            currentStep = prev
        }
    }

    // MARK: - Hook / Promise

    func advanceHookAnimation() {
        hookAnimationPhase += 1
    }

    func advancePromiseAnimation() {
        promiseAnimationPhase += 1
    }

    // MARK: - First Sound (ㅏ)

    func markFirstJamoSpoken() {
        hasSpokenFirstJamo = true
        firstLessonTranscript = Self.firstSoundCharacter
        firstLessonConfidence = 1
        firstLessonMicState = .success("You just spoke Korean.")
    }

    func startFirstLessonRecording(
        audioService: AudioServiceProtocol,
        speechRecognition: SpeechRecognitionServiceProtocol
    ) async {
        switch firstLessonMicState {
        case .idle, .error, .success:
            break
        case .recording, .processing:
            return
        }

        firstLessonTranscript = ""
        firstLessonConfidence = 0

        guard speechRecognition.isAvailable else {
            firstLessonMicState = .error("Speech recognition is unavailable on this device.")
            return
        }

        let authorized = await speechRecognition.requestAuthorization()
        guard authorized else {
            firstLessonMicState = .error("Microphone access is needed to check your pronunciation.")
            return
        }

        do {
            _ = try await audioService.startRecording()
            firstLessonMicState = .recording
        } catch {
            firstLessonMicState = .error("Could not start recording: \(error.localizedDescription)")
        }
    }

    func stopFirstLessonRecording(
        audioService: AudioServiceProtocol,
        speechRecognition: SpeechRecognitionServiceProtocol
    ) async {
        guard case .recording = firstLessonMicState else { return }

        firstLessonMicState = .processing

        do {
            let audioURL = try await audioService.stopRecording()
            let result = try await speechRecognition.recognizeSpeech(from: audioURL)

            firstLessonTranscript = result.transcript
            firstLessonConfidence = result.confidence

            if matchesFirstLessonTarget(transcript: result.transcript, confidence: result.confidence) {
                hasSpokenFirstJamo = true
                firstLessonMicState = .success("You just spoke Korean.")
            } else {
                firstLessonMicState = .error(
                    "We heard \"\(result.transcript)\" — try saying \"\(Self.firstSoundLabel)\" again."
                )
            }
        } catch {
            firstLessonMicState = .error("We couldn't check that recording: \(error.localizedDescription)")
        }
    }

    func resetFirstLessonMicState() {
        firstLessonTranscript = ""
        firstLessonConfidence = 0
        firstLessonMicState = .idle
    }

    // MARK: - First Consonant (ㄱ)

    func markConsonantLearned() {
        hasLearnedConsonant = true
    }

    // MARK: - First Word (가)

    func revealFirstWord() {
        firstWordRevealed = true
    }

    func markFirstWordBuilt() {
        hasBuiltFirstWord = true
    }

    // MARK: - Completion

    func completeOnboarding() -> OnboardingResult {
        isComplete = true
        return OnboardingResult(
            mediaInterests: Array(selectedMediaInterests),
            experience: selectedExperience ?? .none,
            dailyGoalMinutes: selectedGoal.rawValue,
            needsPlacement: shouldShowPlacementTest,
            placedCEFRLevel: placedCEFRLevel
        )
    }

    func completePlacementAndFinish(cefrLevel: String) -> OnboardingResult {
        placedCEFRLevel = cefrLevel
        shouldShowPlacementTest = false
        isComplete = true
        return OnboardingResult(
            mediaInterests: Array(selectedMediaInterests),
            experience: selectedExperience ?? .some,
            dailyGoalMinutes: selectedGoal.rawValue,
            needsPlacement: true,
            placedCEFRLevel: cefrLevel
        )
    }

    func applyPlacementResult(cefrLevel: String) {
        placedCEFRLevel = cefrLevel
        shouldShowPlacementTest = false
    }

    func dismissPlacementTest() {
        shouldShowPlacementTest = false
        // Complete with default level
        placedCEFRLevel = nil
    }

    // MARK: - Status Helpers

    var firstLessonPrompt: String {
        Self.firstSoundCharacter
    }

    var firstLessonStatusMessage: String {
        switch firstLessonMicState {
        case .idle:
            return "Tap to record, say the sound, then tap to stop."
        case .recording:
            return "Listening..."
        case .processing:
            return "Checking..."
        case .success(let message):
            return message
        case .error(let message):
            return message
        }
    }

    var firstLessonStatusIsError: Bool {
        if case .error = firstLessonMicState { return true }
        return false
    }

    var firstLessonStatusIsSuccess: Bool {
        if case .success = firstLessonMicState { return true }
        return false
    }

    var firstLessonIsRecording: Bool {
        if case .recording = firstLessonMicState { return true }
        return false
    }

    var firstLessonIsProcessing: Bool {
        if case .processing = firstLessonMicState { return true }
        return false
    }

    // MARK: - Private

    private static let firstLessonSoundLabel = "ㅏ"

    private func matchesFirstLessonTarget(transcript: String, confidence: Double) -> Bool {
        guard confidence >= Self.firstLessonConfidenceThreshold else { return false }

        let normalized = Self.normalizeTranscript(transcript)
        return Self.acceptedFirstLessonTranscripts.contains(normalized)
    }

    private static func normalizeTranscript(_ transcript: String) -> String {
        transcript
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "!", with: "")
            .replacingOccurrences(of: "?", with: "")
    }
}

// MARK: - Result

struct OnboardingResult {
    let mediaInterests: [OnboardingViewModel.MediaInterest]
    let experience: OnboardingViewModel.KoreanExperience
    let dailyGoalMinutes: Int
    let needsPlacement: Bool
    var placedCEFRLevel: String? = nil
}
