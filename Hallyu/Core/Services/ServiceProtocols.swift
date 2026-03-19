import Foundation

// MARK: - Claude Service

protocol ClaudeServiceProtocol: Sendable {
    func checkTierAllowed(tier: AppState.SubscriptionTier) async throws
    func resetSessionState() async
    func getComprehensionHelp(context: ComprehensionContext, query: String) async throws -> ComprehensionResponse
    func getPronunciationFeedback(transcript: String, target: String) async throws -> PronunciationFeedback
    func getGrammarExplanation(pattern: String, context: String) async throws -> GrammarExplanation
    func generatePracticeItems(mediaContentId: UUID, learnerLevel: String) async throws -> [PracticeItem]
    func getCulturalContext(moment: String, mediaContext: String) async throws -> CulturalContextResponse
}

struct ComprehensionContext: Codable, Sendable {
    let mediaTitle: String
    let transcript: String
    let targetWord: String
    let learnerLevel: String
    let knownVocabulary: [String]
}

struct ComprehensionResponse: Codable, Sendable {
    let literalMeaning: String
    let contextualMeaning: String
    let grammarPattern: String?
    let simplerExample: String
    let registerNote: String?
}

struct PronunciationFeedback: Codable, Sendable {
    let isCorrect: Bool
    let feedback: String
    let articulatoryTip: String?
    let similarSounds: [String]
}

struct GrammarExplanation: Codable, Sendable {
    let ruleStatement: String
    let explanation: String
    let contrastiveExample: String
    let retrievalQuestion: String
}

struct PracticeItem: Codable, Sendable {
    let type: String // fill_in_blank, comprehension, production
    let prompt: String
    let correctAnswer: String
    let alternatives: [String]
}

struct CulturalContextResponse: Codable, Sendable {
    let explanation: String
    let socialDynamics: String?
    let honorificNote: String?
    let historicalContext: String?
    let relatedMedia: [String]

    // Backwards-compatible init (honorificNote defaults to nil)
    init(
        explanation: String,
        socialDynamics: String? = nil,
        honorificNote: String? = nil,
        historicalContext: String? = nil,
        relatedMedia: [String] = []
    ) {
        self.explanation = explanation
        self.socialDynamics = socialDynamics
        self.honorificNote = honorificNote
        self.historicalContext = historicalContext
        self.relatedMedia = relatedMedia
    }
}

// MARK: - Enhanced Practice Item

struct EnhancedPracticeItem: Codable, Sendable {
    let type: String // fill_in_blank, comprehension, production
    let prompt: String
    let correctAnswer: String
    let alternatives: [String]
    let sourceContext: String?
}

// MARK: - Claude Interaction Tracking

enum ClaudeRole: String, Codable, Sendable, CaseIterable {
    case comprehension
    case pronunciation
    case grammar
    case contentAdapter = "content_adapter"
    case cultural
}

struct ClaudeTierLimits {
    let dailyLimit: Int? // nil = unlimited

    static func limits(for tier: AppState.SubscriptionTier) -> ClaudeTierLimits {
        switch tier {
        case .free:
            return ClaudeTierLimits(dailyLimit: 0)
        case .core:
            return ClaudeTierLimits(dailyLimit: 50)
        case .pro:
            return ClaudeTierLimits(dailyLimit: nil)
        }
    }

    func isAllowed(currentCount: Int) -> Bool {
        guard let limit = dailyLimit else { return true }
        return currentCount < limit
    }
}

// MARK: - Audio Service

protocol AudioServiceProtocol: Sendable {
    func startRecording() async throws -> URL
    func stopRecording() async throws -> URL
    func playAudio(url: URL) async throws
    func stopPlayback() async
    var isRecording: Bool { get }
    var isPlaying: Bool { get }
}

// MARK: - Speech Recognition Service

protocol SpeechRecognitionServiceProtocol: Sendable {
    func requestAuthorization() async -> Bool
    func recognizeSpeech(from audioURL: URL) async throws -> SpeechRecognitionResult
    var isAvailable: Bool { get }
}

struct SpeechRecognitionResult: Codable, Sendable {
    let transcript: String
    let confidence: Double
    let segments: [SpeechSegment]
}

struct SpeechSegment: Codable, Sendable {
    let text: String
    let confidence: Double
    let timestamp: Double
    let duration: Double
}

// MARK: - SRS Engine

protocol SRSEngineProtocol: Sendable {
    func predictRecallProbability(item: ReviewItem, at date: Date) -> Double
    func scheduleNextReview(item: ReviewItem, wasCorrect: Bool, responseTime: TimeInterval) -> Date
    func getDueItems(for userId: UUID, from items: [ReviewItem], limit: Int) -> [ReviewItem]
    func getSessionRetryItems(from sessionItems: [(item: ReviewItem, wasCorrect: Bool)]) -> [ReviewItem]
}

// MARK: - Learner Model Service

protocol LearnerModelServiceProtocol: Sendable {
    func updateMastery(userId: UUID, skillType: String, skillId: String, wasCorrect: Bool, responseTime: TimeInterval) async throws
    func getMastery(userId: UUID, skillType: String, skillId: String) async throws -> SkillMastery?
    func getOverallLevel(userId: UUID) async throws -> String
}

// MARK: - Media Player Service

protocol MediaPlayerServiceProtocol: Sendable {
    func loadMedia(url: URL) async throws
    func play() async
    func pause() async
    func seek(to timeSeconds: Double) async
    func setPlaybackRate(_ rate: Float) async
    var currentTime: Double { get }
    var duration: Double { get }
    var isPlaying: Bool { get }
}

// MARK: - Auth Service

protocol AuthServiceProtocol: Sendable {
    func signInWithApple() async throws -> AuthSession
    func signInWithApple(idToken: String, nonce: String?) async throws -> AuthSession
    func signInWithEmail(email: String, password: String) async throws -> AuthSession
    func signUp(email: String, password: String) async throws -> AuthSession
    func signOut() async throws
    func refreshSession() async throws -> AuthSession
    var currentSession: AuthSession? { get }
    var isAuthenticated: Bool { get }
}

struct AuthSession: Codable, Sendable {
    let userId: UUID
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}

// MARK: - Subscription Service

protocol SubscriptionServiceProtocol: Sendable {
    func loadProducts() async throws -> [SubscriptionProduct]
    func purchase(productId: String) async throws -> SubscriptionStatus
    func restorePurchases() async throws -> SubscriptionStatus
    func checkEntitlement(feature: String) -> Bool
    var currentTier: AppState.SubscriptionTier { get }
}

struct SubscriptionProduct: Codable, Sendable {
    let id: String
    let name: String
    let description: String
    let priceFormatted: String
    let tier: String
}

struct SubscriptionStatus: Codable, Sendable {
    let tier: String
    let isActive: Bool
    let expiresAt: Date?
}
