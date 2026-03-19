import Foundation
import SwiftData

enum SyncOperationType: String, Codable {
    case createReviewItem
    case updateReviewItem
    case createStudySession
    case updateSkillMastery
    case updateLearnerProfile
}

struct PendingSyncOperation: Codable, Identifiable {
    let id: UUID
    let type: SyncOperationType
    let payload: Data
    let payloadChecksum: String
    let createdAt: Date
    var retryCount: Int
    var synced: Bool

    init(type: SyncOperationType, payload: Data) {
        self.id = UUID()
        self.type = type
        self.payload = payload
        // Simple checksum: use payload byte count + first/last bytes as integrity marker
        let bytes = [UInt8](payload)
        let first = bytes.first.map(String.init) ?? "0"
        let last = bytes.last.map(String.init) ?? "0"
        self.payloadChecksum = "\(payload.count)_\(first)_\(last)"
        self.createdAt = Date()
        self.retryCount = 0
        self.synced = false
    }
}

actor OfflineSyncManager {
    private var pendingOperations: [PendingSyncOperation] = []
    private let storageKey = "pendingSyncOperations"
    private let maxRetries = 3

    var pendingCount: Int {
        pendingOperations.count
    }

    init() {
        loadPendingOperations()
    }

    // MARK: - Queue Operations

    func enqueue(type: SyncOperationType, payload: Data) {
        let operation = PendingSyncOperation(type: type, payload: payload)
        pendingOperations.append(operation)
        savePendingOperations()
    }

    func enqueue<T: Encodable>(type: SyncOperationType, value: T) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        enqueue(type: type, payload: data)
    }

    // MARK: - Sync

    func syncAll(using supabaseClient: SupabaseClient) async -> SyncResult {
        guard !pendingOperations.isEmpty else {
            return SyncResult(synced: 0, failed: 0, remaining: 0)
        }

        var synced = 0
        var failed = 0
        var remaining: [PendingSyncOperation] = []

        for var operation in pendingOperations {
            // Skip already-synced operations
            guard !operation.synced else { continue }

            // Verify data integrity before syncing
            let bytes = [UInt8](operation.payload)
            let first = bytes.first.map(String.init) ?? "0"
            let last = bytes.last.map(String.init) ?? "0"
            let currentChecksum = "\(operation.payload.count)_\(first)_\(last)"
            guard currentChecksum == operation.payloadChecksum else {
                failed += 1
                continue
            }

            do {
                try await syncOperation(operation, using: supabaseClient)
                operation.synced = true
                synced += 1
            } catch {
                operation.retryCount += 1
                if operation.retryCount < maxRetries {
                    remaining.append(operation)
                } else {
                    failed += 1
                }
            }
        }

        pendingOperations = remaining
        savePendingOperations()

        return SyncResult(synced: synced, failed: failed, remaining: remaining.count)
    }

    func clearAll() {
        pendingOperations.removeAll()
        savePendingOperations()
    }

    func getPendingOperations() -> [PendingSyncOperation] {
        pendingOperations
    }

    // MARK: - Private

    private func syncOperation(_ operation: PendingSyncOperation, using client: SupabaseClient) async throws {
        switch operation.type {
        case .createReviewItem:
            let item = try JSONDecoder().decode(ReviewItemSync.self, from: operation.payload)
            let _: ReviewItemSync = try await client.insert(into: "review_items", values: item)
        case .updateReviewItem:
            let item = try JSONDecoder().decode(ReviewItemSync.self, from: operation.payload)
            let _: ReviewItemSync = try await client.update(
                table: "review_items",
                query: [URLQueryItem(name: "id", value: "eq.\(item.id.uuidString)")],
                values: item
            )
        case .createStudySession:
            let session = try JSONDecoder().decode(StudySessionSync.self, from: operation.payload)
            let _: StudySessionSync = try await client.insert(into: "study_sessions", values: session)
        case .updateSkillMastery:
            let mastery = try JSONDecoder().decode(SkillMasterySync.self, from: operation.payload)
            let _: SkillMasterySync = try await client.insert(into: "skill_mastery", values: mastery)
        case .updateLearnerProfile:
            let profile = try JSONDecoder().decode(LearnerProfileSync.self, from: operation.payload)
            let _: LearnerProfileSync = try await client.update(
                table: "learner_profiles",
                query: [URLQueryItem(name: "user_id", value: "eq.\(profile.userId.uuidString)")],
                values: profile
            )
        }
    }

    private func savePendingOperations() {
        guard let data = try? JSONEncoder().encode(pendingOperations) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func loadPendingOperations() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let operations = try? JSONDecoder().decode([PendingSyncOperation].self, from: data) else {
            return
        }
        pendingOperations = operations
    }
}

// MARK: - Sync Result

struct SyncResult {
    let synced: Int
    let failed: Int
    let remaining: Int

    var isComplete: Bool { remaining == 0 && failed == 0 }
}

// MARK: - Sync DTOs

struct ReviewItemSync: Codable {
    let id: UUID
    let userId: UUID
    let itemType: String
    let itemId: UUID
    let easeFactor: Double
    let intervalDays: Double
    let halfLifeDays: Double
    let repetitions: Int
    let correctCount: Int
    let incorrectCount: Int
    let lastReviewedAt: Date?
    let nextReviewAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case itemType = "item_type"
        case itemId = "item_id"
        case easeFactor = "ease_factor"
        case intervalDays = "interval_days"
        case halfLifeDays = "half_life_days"
        case repetitions
        case correctCount = "correct_count"
        case incorrectCount = "incorrect_count"
        case lastReviewedAt = "last_reviewed_at"
        case nextReviewAt = "next_review_at"
    }
}

struct StudySessionSync: Codable {
    let id: UUID
    let userId: UUID
    let sessionType: String
    let durationSeconds: Int
    let itemsStudied: Int
    let itemsCorrect: Int
    let startedAt: Date
    let completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sessionType = "session_type"
        case durationSeconds = "duration_seconds"
        case itemsStudied = "items_studied"
        case itemsCorrect = "items_correct"
        case startedAt = "started_at"
        case completedAt = "completed_at"
    }
}

struct SkillMasterySync: Codable {
    let id: UUID
    let userId: UUID
    let skillType: String
    let skillId: String
    let accuracy: Double
    let speedMs: Double?
    let retention: Double
    let attempts: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case skillType = "skill_type"
        case skillId = "skill_id"
        case accuracy
        case speedMs = "speed_ms"
        case retention
        case attempts
    }
}

struct LearnerProfileSync: Codable {
    let userId: UUID
    let cefrLevel: String
    let dailyGoalMinutes: Int
    let hangulCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case cefrLevel = "cefr_level"
        case dailyGoalMinutes = "daily_goal_minutes"
        case hangulCompleted = "hangul_completed"
    }
}
