import Foundation
import Observation

@MainActor
@Observable
final class OnboardingViewModel {

    // MARK: - Types

    enum Step: Int, CaseIterable {
        case hook = 0           // Cinematic media showcase — the "wow"
        case promise            // "In 10 minutes you'll read Korean"
        case firstSound         // Learn ㅏ (ah) with mic
        case firstConsonant     // Learn ㄱ (g) with mnemonic
        case firstWord          // Combine ㄱ+ㅏ = 가 ("go!")
        case previewExperience  // Mini-demo of actual feed cards
        case journeyAhead       // Timeline + media interests
        case personalize        // Experience + goal — fast finish
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

    /// A real Korean media snippet used in the cinematic hook
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
        // K-Drama iconic lines
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

        // Squid Game — viral
        ShowcaseSnippet(
            korean: "무궁화 꽃이 피었습니다",
            english: "The hibiscus flower has bloomed",
            source: "Squid Game",
            category: .viral,
            contextNote: "You know this one. 1.65 billion hours watched."
        ),

        // K-Pop lyrics
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

        // Webtoon
        ShowcaseSnippet(
            korean: "포기하지 마. 끝까지 가봐",
            english: "Don't give up. See it through to the end.",
            source: "Solo Leveling",
            category: .webtoon,
            contextNote: "The manhwa that became a global phenomenon"
        ),

        // News
        ShowcaseSnippet(
            korean: "한국 영화, 세계를 사로잡다",
            english: "Korean cinema captivates the world",
            source: "News Headline",
            category: .news,
            contextNote: "From Parasite to Oscar glory"
        ),
    ]

    /// Preview feed cards — showing the user what the actual app experience feels like
    struct PreviewCard: Identifiable, Equatable {
        let id = UUID()
        let type: PreviewCardType
        let korean: String
        let english: String
        let detail: String
    }

    enum PreviewCardType: String, Equatable {
        case mediaClip = "Watch & Learn"
        case vocab = "Vocabulary"
        case pronunciation = "Pronunciation"
        case grammar = "Grammar"
        case cultural = "Culture"

        var iconName: String {
            switch self {
            case .mediaClip: return "play.rectangle.fill"
            case .vocab: return "character.book.closed.fill"
            case .pronunciation: return "mic.fill"
            case .grammar: return "text.alignleft"
            case .cultural: return "globe.asia.australia.fill"
            }
        }
    }

    static let previewCards: [PreviewCard] = [
        PreviewCard(
            type: .mediaClip,
            korean: "커피 주세요",
            english: "Coffee please",
            detail: "Watch a real K-drama scene, tap any word to learn it"
        ),
        PreviewCard(
            type: .vocab,
            korean: "감사합니다",
            english: "Thank you",
            detail: "Flashcards powered by spaced repetition — you'll never forget"
        ),
        PreviewCard(
            type: .pronunciation,
            korean: "안녕하세요",
            english: "Hello",
            detail: "Record yourself, get instant feedback on your accent"
        ),
        PreviewCard(
            type: .grammar,
            korean: "저는 학생이에요",
            english: "I am a student",
            detail: "Grammar patterns taught through real dialogue, not textbooks"
        ),
        PreviewCard(
            type: .cultural,
            korean: "밥 먹었어?",
            english: "Have you eaten?",
            detail: "Not about food — it means 'How are you?' in Korean culture"
        ),
    ]

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

    // Showcase animation state
    var showcaseIndex: Int = 0
    var showcaseReady: Bool = false

    // Promise animation
    var promiseAnimationPhase: Int = 0

    // First word
    var firstWordRevealed: Bool = false

    // Preview experience
    var previewCardIndex: Int = 0
    var previewSeen: Bool = false

    private static let firstLessonConfidenceThreshold: Double = 0.7
    private static let acceptedFirstLessonTranscripts: Set<String> = [
        "a", "ah", "아", "ㅏ", "아!", "아아",
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
            return showcaseReady
        case .promise:
            return promiseAnimationPhase >= 1
        case .firstSound:
            return hasSpokenFirstJamo
        case .firstConsonant:
            return hasLearnedConsonant
        case .firstWord:
            return hasBuiltFirstWord
        case .previewExperience:
            return previewSeen
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

    var currentShowcaseSnippet: ShowcaseSnippet {
        let idx = showcaseIndex % Self.showcaseSnippets.count
        return Self.showcaseSnippets[idx]
    }

    var currentPreviewCard: PreviewCard {
        let idx = previewCardIndex % Self.previewCards.count
        return Self.previewCards[idx]
    }

    // MARK: - Static Content

    static let firstSoundCharacter = "ㅏ"
    static let firstSoundLabel = "ah"
    static let firstSoundHint = "Like the 'a' in 'father'"

    static let firstConsonantCharacter = "ㄱ"
    static let firstConsonantLabel = "g"
    static let firstConsonantHint = "Like the 'g' in 'go'"

    static let firstWordCharacter = "가"
    static let firstWordMeaning = "go"

    // MARK: - Journey Milestones

    struct JourneyMilestone: Identifiable {
        let id = UUID()
        let timeframe: String
        let headline: String
        let detail: String
        let icon: String
        let sampleKorean: String?
    }

    static let journeyMilestones: [JourneyMilestone] = [
        JourneyMilestone(timeframe: "Today", headline: "Read your first word", detail: "가 — you just did this", icon: "checkmark.circle.fill", sampleKorean: "가"),
        JourneyMilestone(timeframe: "This week", headline: "Read all of Hangul", detail: "40 letters, one building block at a time", icon: "character.book.closed.fill", sampleKorean: "한글"),
        JourneyMilestone(timeframe: "Week 2", headline: "Your first K-drama clip", detail: "Real scenes with scaffolded support", icon: "play.rectangle.fill", sampleKorean: "커피 주세요"),
        JourneyMilestone(timeframe: "Month 1", headline: "Follow conversations", detail: "Understand basic dialogue", icon: "bubble.left.and.bubble.right.fill", sampleKorean: "오늘 날씨가 좋아요"),
        JourneyMilestone(timeframe: "Month 3", headline: "Consume real media", detail: "News, webtoons, music — in Korean", icon: "star.fill", sampleKorean: "세계를 사로잡다"),
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

    // MARK: - Showcase (Hook)

    func advanceShowcase() {
        showcaseIndex += 1
    }

    func markShowcaseReady() {
        showcaseReady = true
    }

    // MARK: - Promise

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

    // MARK: - Preview Experience

    func advancePreviewCard() {
        if previewCardIndex < Self.previewCards.count - 1 {
            previewCardIndex += 1
        } else {
            previewSeen = true
        }
    }

    func markPreviewSeen() {
        previewSeen = true
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
        placedCEFRLevel = nil
    }

    // MARK: - Status Helpers

    var firstLessonPrompt: String { Self.firstSoundCharacter }

    var firstLessonStatusMessage: String {
        switch firstLessonMicState {
        case .idle: return "Tap to record, say the sound, then tap to stop."
        case .recording: return "Listening..."
        case .processing: return "Checking..."
        case .success(let msg): return msg
        case .error(let msg): return msg
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
