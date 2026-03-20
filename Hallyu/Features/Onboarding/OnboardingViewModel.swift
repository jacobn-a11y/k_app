import Foundation
import Observation

@MainActor
@Observable
final class OnboardingViewModel {

    // MARK: - Types

    enum Step: Int, CaseIterable {
        case welcome = 0        // Static hook — one showcase snippet + value prop
        case interests          // "What do you want to learn?" multi-tap
        case proficiency        // "What's your Korean level?"
        case dailyGoal          // Pick daily goal
        case micDemo            // Optional voice demo — fully skippable
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

        var subtitle: String {
            switch self {
            case .light: return "A few minutes a day adds up fast"
            case .moderate: return "The sweet spot for steady progress"
            case .committed: return "You'll be reading subtitles in no time"
            }
        }
    }

    // MARK: - Showcase Content

    struct ShowcaseSnippet: Identifiable, Equatable {
        let id = UUID()
        let korean: String
        let english: String
        let source: String
        let category: ShowcaseCategory
        let contextNote: String
    }

    enum ShowcaseCategory: String, Equatable {
        case drama = "K-Drama"
        case music = "K-Pop"
        case webtoon = "Webtoon"
        case viral = "Viral"
        case news = "News"

        var iconName: String {
            switch self {
            case .drama: return "film"
            case .music: return "music.note"
            case .webtoon: return "book.pages"
            case .viral: return "flame.fill"
            case .news: return "newspaper.fill"
            }
        }

        var accentColor: String {
            switch self {
            case .drama: return "purple"
            case .music: return "pink"
            case .webtoon: return "green"
            case .viral: return "orange"
            case .news: return "blue"
            }
        }
    }

    /// Curated real Korean media lines — the "wow" content
    static let showcaseSnippets: [ShowcaseSnippet] = [
        ShowcaseSnippet(
            korean: "사랑해",
            english: "I love you",
            source: "Every K-Drama Ever",
            category: .drama,
            contextNote: "The most spoken line in Korean drama history"
        ),
        ShowcaseSnippet(
            korean: "어디에 있든, 내가 꼭 찾을 거야",
            english: "Wherever you are, I will find you",
            source: "Crash Landing on You",
            category: .drama,
            contextNote: "Captain Ri's promise across the border"
        ),
        ShowcaseSnippet(
            korean: "내 옆에 있어줘",
            english: "Stay by my side",
            source: "Goblin",
            category: .drama,
            contextNote: "The line that made millions cry"
        ),
        ShowcaseSnippet(
            korean: "무궁화 꽃이 피었습니다",
            english: "The hibiscus flower has bloomed",
            source: "Squid Game",
            category: .viral,
            contextNote: "You know this one. 1.65 billion hours watched."
        ),
        ShowcaseSnippet(
            korean: "우리는 전생에도 영원히 함께니까",
            english: "Because we're together forever, even in past lives",
            source: "BTS — DNA",
            category: .music,
            contextNote: "The song that broke YouTube"
        ),
        ShowcaseSnippet(
            korean: "사랑을 했다",
            english: "We were in love",
            source: "iKON — Love Scenario",
            category: .music,
            contextNote: "Banned from Korean elementary schools — too catchy"
        ),
        ShowcaseSnippet(
            korean: "포기하지 마. 끝까지 가봐",
            english: "Don't give up. See it through to the end.",
            source: "Solo Leveling",
            category: .webtoon,
            contextNote: "The manhwa that became a global phenomenon"
        ),
        ShowcaseSnippet(
            korean: "한국 영화, 세계를 사로잡다",
            english: "Korean cinema captivates the world",
            source: "News Headline",
            category: .news,
            contextNote: "From Parasite to Oscar glory"
        ),
    ]

    // MARK: - State

    private(set) var currentStep: Step = .welcome
    var selectedMediaInterests: Set<MediaInterest> = []
    var selectedExperience: KoreanExperience?
    var selectedGoal: DailyGoal = .light
    private(set) var isComplete: Bool = false
    private(set) var shouldShowPlacementTest: Bool = false
    private(set) var placedCEFRLevel: String?

    // Mic demo state
    private(set) var micDemoState: MicDemoState = .idle
    private(set) var micDemoTranscript: String = ""
    private(set) var micDemoConfidence: Double = 0
    private(set) var micDemoSkipped: Bool = false
    private(set) var micDemoSucceeded: Bool = false

    // Welcome step — show a random snippet, no animation gate
    var showcaseSnippetIndex: Int = 0

    // Progress persistence
    private static let persistedStepKey = "onboarding.lastCompletedStep"
    private static let persistedInterestsKey = "onboarding.interests"
    private static let persistedExperienceKey = "onboarding.experience"
    private static let persistedGoalKey = "onboarding.goal"

    enum MicDemoState: Equatable {
        case idle
        case recording
        case processing
        case success(String)
        case error(String)
        case unavailable(String)
    }

    private static let micDemoConfidenceThreshold: Double = 0.7
    private static let acceptedMicDemoTranscripts: Set<String> = [
        "a", "ah", "아", "ㅏ", "아!", "아아",
    ]

    // MARK: - Analytics

    enum OnboardingEvent: Equatable {
        case stepViewed(Step)
        case stepCompleted(Step)
        case stepSkipped(Step)
        case micPermissionDenied
        case micUnavailable
        case micRecordingError(String)
        case micSuccess
        case placementTestShown
        case placementTestCompleted(String)
        case onboardingCompleted(totalSteps: Int)
        case onboardingResumed(fromStep: Step)
    }

    private(set) var analyticsLog: [OnboardingEvent] = []

    // MARK: - Computed

    /// Continue button is always enabled. No hard gates.
    /// For interests step, require at least one selection.
    /// For proficiency, require a selection.
    /// Everything else: always proceed.
    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .interests:
            return !selectedMediaInterests.isEmpty
        case .proficiency:
            return selectedExperience != nil
        case .dailyGoal:
            return true
        case .micDemo:
            return true
        }
    }

    var isFirstStep: Bool {
        currentStep == .welcome
    }

    var isLastStep: Bool {
        currentStep == .micDemo
    }

    var progressFraction: Double {
        Double(currentStep.rawValue + 1) / Double(Step.allCases.count)
    }

    var currentShowcaseSnippet: ShowcaseSnippet {
        let idx = showcaseSnippetIndex % Self.showcaseSnippets.count
        return Self.showcaseSnippets[idx]
    }

    // MARK: - Static Content

    static let micDemoCharacter = "ㅏ"
    static let micDemoLabel = "ah"
    static let micDemoHint = "Like the 'a' in 'father'"

    // MARK: - Actions

    func advance() {
        guard canProceed else { return }

        trackEvent(.stepCompleted(currentStep))
        persistProgress()

        if isLastStep {
            return
        }

        if let next = Step(rawValue: currentStep.rawValue + 1) {
            currentStep = next
            trackEvent(.stepViewed(next))
        }
    }

    func goBack() {
        if let prev = Step(rawValue: currentStep.rawValue - 1) {
            currentStep = prev
        }
    }

    func skipCurrentStep() {
        trackEvent(.stepSkipped(currentStep))

        switch currentStep {
        case .interests:
            // Allow skipping — will use default interests
            break
        case .proficiency:
            // Default to fresh starter
            if selectedExperience == nil {
                selectedExperience = .none
            }
        case .micDemo:
            micDemoSkipped = true
        default:
            break
        }

        persistProgress()

        if let next = Step(rawValue: currentStep.rawValue + 1) {
            currentStep = next
            trackEvent(.stepViewed(next))
        }
    }

    /// Whether the current step can be skipped
    var canSkipCurrentStep: Bool {
        switch currentStep {
        case .welcome:
            return false // First step, just tap Continue
        case .interests:
            return true
        case .proficiency:
            return true
        case .dailyGoal:
            return false // Already has a default, Continue always works
        case .micDemo:
            return true
        }
    }

    // MARK: - Mic Demo

    func startMicDemo(
        audioService: AudioServiceProtocol,
        speechRecognition: SpeechRecognitionServiceProtocol
    ) async {
        switch micDemoState {
        case .idle, .error, .success, .unavailable:
            break
        case .recording, .processing:
            return
        }

        micDemoTranscript = ""
        micDemoConfidence = 0

        guard speechRecognition.isAvailable else {
            micDemoState = .unavailable("Voice isn't available on this device — no worries, you can use it later.")
            trackEvent(.micUnavailable)
            return
        }

        let authorized = await speechRecognition.requestAuthorization()
        guard authorized else {
            micDemoState = .unavailable("Mic access was declined — you can enable it later in Settings.")
            trackEvent(.micPermissionDenied)
            return
        }

        do {
            _ = try await audioService.startRecording()
            micDemoState = .recording
        } catch {
            micDemoState = .error("Couldn't start recording. You can try voice later in lessons.")
            trackEvent(.micRecordingError(error.localizedDescription))
        }
    }

    func stopMicDemo(
        audioService: AudioServiceProtocol,
        speechRecognition: SpeechRecognitionServiceProtocol
    ) async {
        guard case .recording = micDemoState else { return }
        micDemoState = .processing

        do {
            let audioURL = try await audioService.stopRecording()
            let result = try await speechRecognition.recognizeSpeech(from: audioURL)
            micDemoTranscript = result.transcript
            micDemoConfidence = result.confidence

            if matchesMicDemoTarget(transcript: result.transcript, confidence: result.confidence) {
                micDemoSucceeded = true
                micDemoState = .success("You just spoke Korean!")
                trackEvent(.micSuccess)
            } else {
                micDemoState = .error(
                    "We heard \"\(result.transcript)\" — try saying \"\(Self.micDemoLabel)\" again, or skip for now."
                )
            }
        } catch {
            micDemoState = .error("Couldn't process that — you can try voice later in lessons.")
            trackEvent(.micRecordingError(error.localizedDescription))
        }
    }

    func resetMicDemo() {
        micDemoTranscript = ""
        micDemoConfidence = 0
        micDemoState = .idle
    }

    func skipMicDemo() {
        micDemoSkipped = true
        trackEvent(.stepSkipped(.micDemo))
    }

    // MARK: - Mic Demo Status Helpers

    var micDemoStatusMessage: String {
        switch micDemoState {
        case .idle: return "Tap the mic, say the sound, then tap to stop."
        case .recording: return "Listening..."
        case .processing: return "Checking..."
        case .success(let msg): return msg
        case .error(let msg): return msg
        case .unavailable(let msg): return msg
        }
    }

    var micDemoStatusIsError: Bool {
        if case .error = micDemoState { return true }
        return false
    }

    var micDemoStatusIsSuccess: Bool {
        if case .success = micDemoState { return true }
        return false
    }

    var micDemoIsRecording: Bool {
        if case .recording = micDemoState { return true }
        return false
    }

    var micDemoIsProcessing: Bool {
        if case .processing = micDemoState { return true }
        return false
    }

    var micDemoIsUnavailable: Bool {
        if case .unavailable = micDemoState { return true }
        return false
    }

    // MARK: - Completion

    func completeOnboarding() -> OnboardingResult {
        isComplete = true

        if selectedExperience == .some {
            shouldShowPlacementTest = true
        }

        trackEvent(.onboardingCompleted(totalSteps: Step.allCases.count))
        clearPersistedProgress()

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
        trackEvent(.placementTestCompleted(cefrLevel))
        clearPersistedProgress()
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
        placedCEFRLevel = nil
    }

    // MARK: - Progress Persistence

    func persistProgress() {
        UserDefaults.standard.set(currentStep.rawValue, forKey: Self.persistedStepKey)
        if !selectedMediaInterests.isEmpty {
            let interests = selectedMediaInterests.map(\.rawValue)
            UserDefaults.standard.set(interests, forKey: Self.persistedInterestsKey)
        }
        if let experience = selectedExperience {
            UserDefaults.standard.set(experience.rawValue, forKey: Self.persistedExperienceKey)
        }
        UserDefaults.standard.set(selectedGoal.rawValue, forKey: Self.persistedGoalKey)
    }

    func restoreProgress() {
        let lastStep = UserDefaults.standard.integer(forKey: Self.persistedStepKey)
        if lastStep > 0, let step = Step(rawValue: lastStep) {
            // Resume from the completed step (go to next)
            if let next = Step(rawValue: step.rawValue + 1) {
                currentStep = next
                trackEvent(.onboardingResumed(fromStep: next))
            } else {
                currentStep = step
                trackEvent(.onboardingResumed(fromStep: step))
            }
        }

        if let savedInterests = UserDefaults.standard.stringArray(forKey: Self.persistedInterestsKey) {
            selectedMediaInterests = Set(savedInterests.compactMap { MediaInterest(rawValue: $0) })
        }

        if let savedExperience = UserDefaults.standard.string(forKey: Self.persistedExperienceKey),
           let experience = KoreanExperience(rawValue: savedExperience) {
            selectedExperience = experience
        }

        if let savedGoal = UserDefaults.standard.object(forKey: Self.persistedGoalKey) as? Int,
           let goal = DailyGoal(rawValue: savedGoal) {
            selectedGoal = goal
        }
    }

    private func clearPersistedProgress() {
        UserDefaults.standard.removeObject(forKey: Self.persistedStepKey)
        UserDefaults.standard.removeObject(forKey: Self.persistedInterestsKey)
        UserDefaults.standard.removeObject(forKey: Self.persistedExperienceKey)
        UserDefaults.standard.removeObject(forKey: Self.persistedGoalKey)
    }

    // MARK: - Analytics

    private func trackEvent(_ event: OnboardingEvent) {
        analyticsLog.append(event)
    }

    // MARK: - Private

    private func matchesMicDemoTarget(transcript: String, confidence: Double) -> Bool {
        guard confidence >= Self.micDemoConfidenceThreshold else { return false }
        let normalized = Self.normalizeTranscript(transcript)
        return Self.acceptedMicDemoTranscripts.contains(normalized)
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
