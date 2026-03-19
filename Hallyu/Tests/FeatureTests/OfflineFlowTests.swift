import XCTest
@testable import HallyuCore

final class OfflineFlowTests: XCTestCase {

    // MARK: - AppState Offline Tests

    func testAppStateDefaultsToOnline() {
        let appState = AppState()
        XCTAssertFalse(appState.isOffline)
        XCTAssertEqual(appState.pendingSyncCount, 0)
    }

    func testAppStateOfflineToggle() {
        let appState = AppState()
        appState.isOffline = true
        XCTAssertTrue(appState.isOffline)

        appState.isOffline = false
        XCTAssertFalse(appState.isOffline)
    }

    func testAppStatePendingSyncCount() {
        let appState = AppState()
        appState.pendingSyncCount = 5
        XCTAssertEqual(appState.pendingSyncCount, 5)
    }

    // MARK: - Sync DTO Encoding/Decoding

    func testReviewItemSyncCodable() throws {
        let item = ReviewItemSync(
            id: UUID(),
            userId: UUID(),
            itemType: "vocabulary",
            itemId: UUID(),
            easeFactor: 2.5,
            intervalDays: 3.0,
            halfLifeDays: 2.0,
            repetitions: 5,
            correctCount: 4,
            incorrectCount: 1,
            lastReviewedAt: Date(),
            nextReviewAt: Date().addingTimeInterval(86400 * 3)
        )

        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ReviewItemSync.self, from: data)

        XCTAssertEqual(decoded.id, item.id)
        XCTAssertEqual(decoded.itemType, "vocabulary")
        XCTAssertEqual(decoded.easeFactor, 2.5)
        XCTAssertEqual(decoded.correctCount, 4)
    }

    func testStudySessionSyncCodable() throws {
        let session = StudySessionSync(
            id: UUID(),
            userId: UUID(),
            sessionType: "review",
            durationSeconds: 600,
            itemsStudied: 20,
            itemsCorrect: 16,
            startedAt: Date(),
            completedAt: Date()
        )

        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(StudySessionSync.self, from: data)

        XCTAssertEqual(decoded.sessionType, "review")
        XCTAssertEqual(decoded.durationSeconds, 600)
        XCTAssertEqual(decoded.itemsStudied, 20)
    }

    func testSkillMasterySyncCodable() throws {
        let mastery = SkillMasterySync(
            id: UUID(),
            userId: UUID(),
            skillType: "vocab_recognition",
            skillId: "word_123",
            accuracy: 0.85,
            speedMs: 1500.0,
            retention: 0.78,
            attempts: 12
        )

        let data = try JSONEncoder().encode(mastery)
        let decoded = try JSONDecoder().decode(SkillMasterySync.self, from: data)

        XCTAssertEqual(decoded.skillType, "vocab_recognition")
        XCTAssertEqual(decoded.accuracy, 0.85)
        XCTAssertEqual(decoded.attempts, 12)
    }

    func testLearnerProfileSyncCodable() throws {
        let profile = LearnerProfileSync(
            userId: UUID(),
            cefrLevel: "A1",
            dailyGoalMinutes: 20,
            hangulCompleted: true
        )

        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(LearnerProfileSync.self, from: data)

        XCTAssertEqual(decoded.cefrLevel, "A1")
        XCTAssertEqual(decoded.dailyGoalMinutes, 20)
        XCTAssertTrue(decoded.hangulCompleted)
    }

    // MARK: - AppStore Metadata

    func testAppStoreMetadataValues() {
        XCTAssertEqual(AppStoreMetadata.bundleId, "com.hallyu.app")
        XCTAssertEqual(AppStoreMetadata.minimumOSVersion, "17.0")
        XCTAssertFalse(AppStoreMetadata.description.isEmpty)
        XCTAssertFalse(AppStoreMetadata.keywords.isEmpty)
        XCTAssertEqual(AppStoreMetadata.primaryCategory, "Education")
    }

    func testPrivacyPolicyNotEmpty() {
        XCTAssertFalse(PrivacyPolicy.content.isEmpty)
        XCTAssertFalse(PrivacyPolicy.lastUpdated.isEmpty)
    }

    // MARK: - Service Container with Sync Manager

    func testServiceContainerIncludesSyncManager() {
        let container = ServiceContainer()
        // syncManager should be non-nil (it's not optional)
        let _ = container.syncManager
        // If this compiles and runs, the test passes
    }
}
