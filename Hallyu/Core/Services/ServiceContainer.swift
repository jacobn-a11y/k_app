import Foundation
import Observation

@Observable
final class ServiceContainer {
    let claude: ClaudeServiceProtocol
    let audio: AudioServiceProtocol
    let speechRecognition: SpeechRecognitionServiceProtocol
    let srsEngine: SRSEngineProtocol
    let learnerModel: LearnerModelServiceProtocol
    let mediaPlayer: MediaPlayerServiceProtocol
    let auth: AuthServiceProtocol
    let subscription: SubscriptionServiceProtocol

    init(
        claude: ClaudeServiceProtocol? = nil,
        audio: AudioServiceProtocol? = nil,
        speechRecognition: SpeechRecognitionServiceProtocol? = nil,
        srsEngine: SRSEngineProtocol? = nil,
        learnerModel: LearnerModelServiceProtocol? = nil,
        mediaPlayer: MediaPlayerServiceProtocol? = nil,
        auth: AuthServiceProtocol? = nil,
        subscription: SubscriptionServiceProtocol? = nil
    ) {
        self.claude = claude ?? MockClaudeService()
        self.audio = audio ?? MockAudioService()
        self.speechRecognition = speechRecognition ?? MockSpeechRecognitionService()
        self.srsEngine = srsEngine ?? MockSRSEngine()
        self.learnerModel = learnerModel ?? MockLearnerModelService()
        self.mediaPlayer = mediaPlayer ?? MockMediaPlayerService()
        self.auth = auth ?? MockAuthService()
        self.subscription = subscription ?? MockSubscriptionService()
    }
}

// MARK: - Mock Implementations

final class MockClaudeService: ClaudeServiceProtocol, @unchecked Sendable {
    func getComprehensionHelp(context: ComprehensionContext, query: String) async throws -> ComprehensionResponse {
        ComprehensionResponse(
            literalMeaning: "Mock literal meaning",
            contextualMeaning: "Mock contextual meaning",
            grammarPattern: nil,
            simplerExample: "Mock example",
            registerNote: nil
        )
    }

    func getPronunciationFeedback(transcript: String, target: String) async throws -> PronunciationFeedback {
        PronunciationFeedback(
            isCorrect: transcript == target,
            feedback: "Mock feedback",
            articulatoryTip: nil,
            similarSounds: []
        )
    }

    func getGrammarExplanation(pattern: String, context: String) async throws -> GrammarExplanation {
        GrammarExplanation(
            ruleStatement: "Mock rule",
            explanation: "Mock explanation",
            contrastiveExample: "Mock example",
            retrievalQuestion: "Mock question?"
        )
    }

    func generatePracticeItems(mediaContentId: UUID, learnerLevel: String) async throws -> [PracticeItem] {
        [PracticeItem(type: "fill_in_blank", prompt: "Mock prompt", correctAnswer: "answer", alternatives: ["a", "b"])]
    }

    func getCulturalContext(moment: String, mediaContext: String) async throws -> CulturalContextResponse {
        CulturalContextResponse(
            explanation: "Mock cultural context",
            socialDynamics: nil,
            historicalContext: nil,
            relatedMedia: []
        )
    }
}

final class MockAudioService: AudioServiceProtocol, @unchecked Sendable {
    var isRecording: Bool = false
    var isPlaying: Bool = false

    func startRecording() async throws -> URL {
        URL(fileURLWithPath: "/tmp/mock_recording.m4a")
    }

    func stopRecording() async throws -> URL {
        URL(fileURLWithPath: "/tmp/mock_recording.m4a")
    }

    func playAudio(url: URL) async throws {}
    func stopPlayback() async {}
}

final class MockSpeechRecognitionService: SpeechRecognitionServiceProtocol, @unchecked Sendable {
    var isAvailable: Bool = true

    func requestAuthorization() async -> Bool { true }

    func recognizeSpeech(from audioURL: URL) async throws -> SpeechRecognitionResult {
        SpeechRecognitionResult(
            transcript: "mock transcript",
            confidence: 0.95,
            segments: [SpeechSegment(text: "mock", confidence: 0.95, timestamp: 0, duration: 1.0)]
        )
    }
}

final class MockSRSEngine: SRSEngineProtocol, @unchecked Sendable {
    func predictRecallProbability(item: ReviewItem, at date: Date) -> Double { 0.8 }

    func scheduleNextReview(item: ReviewItem, wasCorrect: Bool, responseTime: TimeInterval) -> Date {
        Date().addingTimeInterval(wasCorrect ? 86400 : 3600)
    }

    func getDueItems(for userId: UUID, from items: [ReviewItem], limit: Int) -> [ReviewItem] {
        Array(items.filter { $0.nextReviewAt <= Date() }.prefix(limit))
    }
}

final class MockLearnerModelService: LearnerModelServiceProtocol, @unchecked Sendable {
    func updateMastery(userId: UUID, skillType: String, skillId: String, wasCorrect: Bool, responseTime: TimeInterval) async throws {}

    func getMastery(userId: UUID, skillType: String, skillId: String) async throws -> SkillMastery? { nil }

    func getOverallLevel(userId: UUID) async throws -> String { "pre-A1" }
}

final class MockMediaPlayerService: MediaPlayerServiceProtocol, @unchecked Sendable {
    var currentTime: Double = 0
    var duration: Double = 120
    var isPlaying: Bool = false

    func loadMedia(url: URL) async throws {}
    func play() async { isPlaying = true }
    func pause() async { isPlaying = false }
    func seek(to timeSeconds: Double) async { currentTime = timeSeconds }
    func setPlaybackRate(_ rate: Float) async {}
}

final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    var currentSession: AuthSession? = nil
    var isAuthenticated: Bool = false

    func signInWithApple() async throws -> AuthSession {
        let session = AuthSession(userId: UUID(), accessToken: "mock", refreshToken: "mock", expiresAt: Date().addingTimeInterval(3600))
        currentSession = session
        isAuthenticated = true
        return session
    }

    func signInWithEmail(email: String, password: String) async throws -> AuthSession {
        try await signInWithApple()
    }

    func signUp(email: String, password: String) async throws -> AuthSession {
        try await signInWithApple()
    }

    func signOut() async throws {
        currentSession = nil
        isAuthenticated = false
    }

    func refreshSession() async throws -> AuthSession {
        try await signInWithApple()
    }
}

final class MockSubscriptionService: SubscriptionServiceProtocol, @unchecked Sendable {
    var currentTier: AppState.SubscriptionTier = .free

    func loadProducts() async throws -> [SubscriptionProduct] {
        [
            SubscriptionProduct(id: "core_monthly", name: "Core", description: "Core features", priceFormatted: "$12.99/mo", tier: "core"),
            SubscriptionProduct(id: "pro_monthly", name: "Pro", description: "All features", priceFormatted: "$19.99/mo", tier: "pro")
        ]
    }

    func purchase(productId: String) async throws -> SubscriptionStatus {
        SubscriptionStatus(tier: "core", isActive: true, expiresAt: Date().addingTimeInterval(2_592_000))
    }

    func restorePurchases() async throws -> SubscriptionStatus {
        SubscriptionStatus(tier: "free", isActive: true, expiresAt: nil)
    }

    func checkEntitlement(feature: String) -> Bool {
        currentTier != .free
    }
}
