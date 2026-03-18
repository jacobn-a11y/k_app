import Testing
import Foundation
@testable import HallyuCore

@Suite("ServiceContainer & DI Tests")
struct ServiceContainerTests {

    @Test("ServiceContainer initializes with mock services by default")
    func defaultMocks() {
        let container = ServiceContainer()
        #expect(container.claude is MockClaudeService)
        #expect(container.audio is MockAudioService)
        #expect(container.speechRecognition is MockSpeechRecognitionService)
        #expect(container.srsEngine is MockSRSEngine)
        #expect(container.learnerModel is MockLearnerModelService)
        #expect(container.mediaPlayer is MockMediaPlayerService)
        #expect(container.auth is MockAuthService)
        #expect(container.subscription is MockSubscriptionService)
    }

    @Test("ServiceContainer accepts custom service implementations")
    func customServices() {
        let customClaude = MockClaudeService()
        let container = ServiceContainer(claude: customClaude)
        #expect(container.claude is MockClaudeService)
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
