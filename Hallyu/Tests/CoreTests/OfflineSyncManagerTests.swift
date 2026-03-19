import XCTest
@testable import HallyuCore

final class OfflineSyncManagerTests: XCTestCase {

    var syncManager: OfflineSyncManager!

    override func setUp() async throws {
        syncManager = OfflineSyncManager()
        await syncManager.clearAll()
    }

    // MARK: - Queue Operations

    func testEnqueueOperation() async {
        let payload = "test".data(using: .utf8)!
        await syncManager.enqueue(type: .createReviewItem, payload: payload)

        let count = await syncManager.pendingCount
        XCTAssertEqual(count, 1, "Should have 1 pending operation")
    }

    func testEnqueueMultipleOperations() async {
        let payload = "test".data(using: .utf8)!
        await syncManager.enqueue(type: .createReviewItem, payload: payload)
        await syncManager.enqueue(type: .updateSkillMastery, payload: payload)
        await syncManager.enqueue(type: .createStudySession, payload: payload)

        let count = await syncManager.pendingCount
        XCTAssertEqual(count, 3, "Should have 3 pending operations")
    }

    func testEnqueueEncodableValue() async {
        let session = StudySessionSync(
            id: UUID(),
            userId: UUID(),
            sessionType: "review",
            durationSeconds: 300,
            itemsStudied: 10,
            itemsCorrect: 8,
            startedAt: Date(),
            completedAt: Date()
        )

        await syncManager.enqueue(type: .createStudySession, value: session)

        let count = await syncManager.pendingCount
        XCTAssertEqual(count, 1, "Should have 1 pending operation after encoding")
    }

    func testClearAllOperations() async {
        let payload = "test".data(using: .utf8)!
        await syncManager.enqueue(type: .createReviewItem, payload: payload)
        await syncManager.enqueue(type: .updateSkillMastery, payload: payload)

        await syncManager.clearAll()

        let count = await syncManager.pendingCount
        XCTAssertEqual(count, 0, "Should have 0 pending operations after clear")
    }

    func testGetPendingOperations() async {
        let payload = "test".data(using: .utf8)!
        await syncManager.enqueue(type: .createReviewItem, payload: payload)
        await syncManager.enqueue(type: .updateSkillMastery, payload: payload)

        let operations = await syncManager.getPendingOperations()
        XCTAssertEqual(operations.count, 2)
        XCTAssertEqual(operations[0].type, .createReviewItem)
        XCTAssertEqual(operations[1].type, .updateSkillMastery)
    }

    // MARK: - Sync Operation Types

    func testSyncOperationTypeRawValues() {
        XCTAssertEqual(SyncOperationType.createReviewItem.rawValue, "createReviewItem")
        XCTAssertEqual(SyncOperationType.updateReviewItem.rawValue, "updateReviewItem")
        XCTAssertEqual(SyncOperationType.createStudySession.rawValue, "createStudySession")
        XCTAssertEqual(SyncOperationType.updateSkillMastery.rawValue, "updateSkillMastery")
        XCTAssertEqual(SyncOperationType.updateLearnerProfile.rawValue, "updateLearnerProfile")
    }

    // MARK: - Sync Result

    func testSyncResultComplete() {
        let result = SyncResult(synced: 5, failed: 0, remaining: 0)
        XCTAssertTrue(result.isComplete)
    }

    func testSyncResultIncomplete() {
        let result = SyncResult(synced: 3, failed: 1, remaining: 1)
        XCTAssertFalse(result.isComplete)
    }

    // MARK: - Pending Operation

    func testPendingSyncOperationCreation() {
        let payload = "test".data(using: .utf8)!
        let operation = PendingSyncOperation(type: .createReviewItem, payload: payload)

        XCTAssertEqual(operation.type, .createReviewItem)
        XCTAssertEqual(operation.retryCount, 0)
        XCTAssertNotNil(operation.id)
    }
}
