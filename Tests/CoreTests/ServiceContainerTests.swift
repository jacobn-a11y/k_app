import Testing
import Foundation
@testable import HallyuCore

@Suite("ServiceContainer & DI Tests")
struct ServiceContainerTests {

    private final class ResetTrackingClaudeService: ClaudeServiceProtocol, @unchecked Sendable {
        var resetCallCount = 0
        var lastTierCheck: AppState.SubscriptionTier?

        func checkTierAllowed(tier: AppState.SubscriptionTier) async throws {
            lastTierCheck = tier
        }

        func resetSessionState() async {
            resetCallCount += 1
        }

        func getComprehensionHelp(context: ComprehensionContext, query: String) async throws -> ComprehensionResponse {
            ComprehensionResponse(
                literalMeaning: "tracked",
                contextualMeaning: "tracked",
                grammarPattern: nil,
                simplerExample: "tracked",
                registerNote: nil
            )
        }

        func getPronunciationFeedback(transcript: String, target: String) async throws -> PronunciationFeedback {
            PronunciationFeedback(isCorrect: true, feedback: "tracked", articulatoryTip: nil, similarSounds: [])
        }

        func getGrammarExplanation(pattern: String, context: String) async throws -> GrammarExplanation {
            GrammarExplanation(
                ruleStatement: "tracked",
                explanation: "tracked",
                contrastiveExample: "tracked",
                retrievalQuestion: "tracked?"
            )
        }

        func generatePracticeItems(mediaContentId: UUID, learnerLevel: String) async throws -> [PracticeItem] {
            [PracticeItem(type: "comprehension", prompt: "tracked", correctAnswer: "tracked", alternatives: [])]
        }

        func getCulturalContext(moment: String, mediaContext: String) async throws -> CulturalContextResponse {
            CulturalContextResponse(explanation: "tracked")
        }
    }

    private final class UnavailableTrackingClaudeService: ClaudeServiceProtocol, @unchecked Sendable {
        func checkTierAllowed(tier: AppState.SubscriptionTier) async throws {}
        func resetSessionState() async {}

        func getComprehensionHelp(context: ComprehensionContext, query: String) async throws -> ComprehensionResponse {
            throw ServiceUnavailableError(reason: "Claude unavailable")
        }

        func getPronunciationFeedback(transcript: String, target: String) async throws -> PronunciationFeedback {
            throw ServiceUnavailableError(reason: "Claude unavailable")
        }

        func getGrammarExplanation(pattern: String, context: String) async throws -> GrammarExplanation {
            throw ServiceUnavailableError(reason: "Claude unavailable")
        }

        func generatePracticeItems(mediaContentId: UUID, learnerLevel: String) async throws -> [PracticeItem] {
            throw ServiceUnavailableError(reason: "Claude unavailable")
        }

        func getCulturalContext(moment: String, mediaContext: String) async throws -> CulturalContextResponse {
            throw ServiceUnavailableError(reason: "Claude unavailable")
        }
    }

    private let sampleContext = ComprehensionContext(
        mediaTitle: "Test",
        transcript: "안녕하세요",
        targetWord: "안녕",
        learnerLevel: "A1",
        knownVocabulary: []
    )

    @Test("ServiceContainer initializes production auth and subscription services by default")
    func defaultServices() {
        let container = ServiceContainer()
        #expect(!(container.claude is MockClaudeService))
        #expect(container.audio is AudioService)
        #expect(container.speechRecognition is SpeechRecognitionService)
        #expect(container.srsEngine is SRSEngine)
        #expect(container.learnerModel is LearnerModelService)
        #expect(container.mediaPlayer is AVMediaPlayerService)
        #expect(!(container.auth is MockAuthService))
        #expect(container.subscription is StoreKitSubscriptionService)
    }

    @Test("ServiceContainer can still be built with test doubles")
    func testingContainer() {
        let container = ServiceContainer.testing()
        #expect(!(container.auth is MockAuthService))
        #expect(container.subscription is MockSubscriptionService)
    }

    @Test("ServiceContainer accepts custom service implementations")
    func customServices() async throws {
        let customClaude = MockClaudeService()
        let subscription = MockSubscriptionService()
        subscription.currentTier = .core
        let container = ServiceContainer(claude: customClaude, auth: MockAuthService(), subscription: subscription)
        let response = try await container.claude.getComprehensionHelp(context: sampleContext, query: "help")
        #expect(response.literalMeaning == "Mock literal meaning")
    }

    @Test("MockClaudeService returns comprehension response")
    func mockClaudeComprehension() async throws {
        let service = MockClaudeService()
        let context = ComprehensionContext(
            mediaTitle: "Test",
            transcript: "안녕하세요",
            targetWord: "안녕",
            learnerLevel: "A1",
            knownVocabulary: []
        )
        let response = try await service.getComprehensionHelp(context: context, query: "What does this mean?")
        #expect(!response.literalMeaning.isEmpty)
    }

    @Test("MockClaudeService pronunciation feedback matches")
    func mockPronunciation() async throws {
        let service = MockClaudeService()
        let matchResult = try await service.getPronunciationFeedback(transcript: "안녕", target: "안녕")
        #expect(matchResult.isCorrect == true)

        let mismatchResult = try await service.getPronunciationFeedback(transcript: "안영", target: "안녕")
        #expect(mismatchResult.isCorrect == false)
    }

    @Test("MockClaudeService tier checks follow Claude limits")
    func mockClaudeTierChecks() async throws {
        let service = MockClaudeService()

        do {
            try await service.checkTierAllowed(tier: .free)
            Issue.record("Expected free tier to be blocked")
        } catch {
            #expect(error is ClaudeServiceError)
        }

        try await service.checkTierAllowed(tier: .core)
        try await service.checkTierAllowed(tier: .pro)
    }

    @Test("Container Claude service centrally blocks free tier role calls")
    func containerClaudeCentralTierEnforcement() async throws {
        let subscription = MockSubscriptionService()
        subscription.currentTier = .free
        let container = ServiceContainer(
            claude: MockClaudeService(),
            auth: MockAuthService(),
            subscription: subscription
        )

        do {
            _ = try await container.claude.getComprehensionHelp(context: sampleContext, query: "help")
            Issue.record("Expected tier enforcement to block Claude role call")
        } catch {
            #expect(error is ClaudeServiceError)
        }
    }

    @Test("Container Claude service uses subscription tier at service boundary")
    func containerClaudeUsesCurrentSubscriptionTier() async throws {
        let trackingClaude = ResetTrackingClaudeService()
        let subscription = MockSubscriptionService()
        subscription.currentTier = .pro
        let container = ServiceContainer(
            claude: trackingClaude,
            auth: MockAuthService(),
            subscription: subscription
        )

        _ = try await container.claude.getGrammarExplanation(pattern: "-아요", context: "Test context")
        #expect(trackingClaude.lastTierCheck == .pro)
    }

    @Test("Container auth sign-out resets Claude session state")
    func containerAuthSignOutResetsClaudeState() async throws {
        let trackingClaude = ResetTrackingClaudeService()
        let auth = MockAuthService()
        let subscription = MockSubscriptionService()
        subscription.currentTier = .core
        let container = ServiceContainer(
            claude: trackingClaude,
            auth: auth,
            subscription: subscription
        )

        _ = try await container.auth.signInWithApple()
        try await container.auth.signOut()

        #expect(auth.isAuthenticated == false)
        #expect(trackingClaude.resetCallCount == 1)
    }

    @Test("Container preserves unavailable Claude behavior for allowed tiers")
    func containerClaudePreservesUnavailableBehavior() async throws {
        let subscription = MockSubscriptionService()
        subscription.currentTier = .core
        let container = ServiceContainer(
            claude: UnavailableTrackingClaudeService(),
            auth: MockAuthService(),
            subscription: subscription
        )

        do {
            _ = try await container.claude.getComprehensionHelp(context: sampleContext, query: "help")
            Issue.record("Expected unavailable Claude service to throw")
        } catch {
            #expect(error is ServiceUnavailableError)
        }
    }

    @Test("MockSRSEngine filters due items")
    func mockSRSDueItems() {
        let engine = MockSRSEngine()
        let userId = UUID()
        let pastDue = ReviewItem(userId: userId, itemType: "vocab", itemId: UUID(), nextReviewAt: Date().addingTimeInterval(-3600))
        let futureItem = ReviewItem(userId: userId, itemType: "vocab", itemId: UUID(), nextReviewAt: Date().addingTimeInterval(86400))

        let dueItems = engine.getDueItems(for: userId, from: [pastDue, futureItem], limit: 10)
        #expect(dueItems.count == 1)
    }

    @Test("MockSRSEngine schedules correct answers further out")
    func mockSRSScheduling() {
        let engine = MockSRSEngine()
        let item = ReviewItem(userId: UUID(), itemType: "vocab", itemId: UUID())
        let correctDate = engine.scheduleNextReview(item: item, wasCorrect: true, responseTime: 2.0)
        let incorrectDate = engine.scheduleNextReview(item: item, wasCorrect: false, responseTime: 2.0)
        #expect(correctDate > incorrectDate)
    }

    @Test("MockAuthService sign-in sets authenticated state")
    func mockAuthSignIn() async throws {
        let service = MockAuthService()
        #expect(service.isAuthenticated == false)

        let session = try await service.signInWithApple()
        #expect(service.isAuthenticated == true)
        #expect(!session.accessToken.isEmpty)
    }

    @Test("MockAuthService sign-out clears state")
    func mockAuthSignOut() async throws {
        let service = MockAuthService()
        _ = try await service.signInWithApple()
        try await service.signOut()
        #expect(service.isAuthenticated == false)
        #expect(service.currentSession == nil)
    }

    @Test("MockSubscriptionService entitlement check")
    func mockSubscriptionEntitlement() {
        let service = MockSubscriptionService()
        #expect(service.checkEntitlement(feature: "claude") == false)

        service.currentTier = .core
        #expect(service.checkEntitlement(feature: "claude") == true)
    }

    @Test("MockSpeechRecognitionService returns result")
    func mockSpeechRecognition() async throws {
        let service = MockSpeechRecognitionService()
        #expect(service.isAvailable == true)

        let authorized = await service.requestAuthorization()
        #expect(authorized == true)

        let result = try await service.recognizeSpeech(from: URL(fileURLWithPath: "/tmp/test.m4a"))
        #expect(!result.transcript.isEmpty)
        #expect(result.confidence > 0)
    }

    @Test("MockMediaPlayerService state management")
    func mockMediaPlayer() async {
        let player = MockMediaPlayerService()
        #expect(player.isPlaying == false)

        await player.play()
        #expect(player.isPlaying == true)

        await player.pause()
        #expect(player.isPlaying == false)

        await player.seek(to: 30.0)
        #expect(player.currentTime == 30.0)
    }
}
