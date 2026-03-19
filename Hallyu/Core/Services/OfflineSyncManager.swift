import Foundation
import SwiftData
import Security

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

    init(type: SyncOperationType, payload: Data, payloadChecksum: String) {
        self.id = UUID()
        self.type = type
        self.payload = payload
        self.payloadChecksum = payloadChecksum
        self.createdAt = Date()
        self.retryCount = 0
        self.synced = false
    }
}

actor OfflineSyncManager {
    private var pendingOperations: [PendingSyncOperation] = []
    private let storageKey = "pendingSyncOperations"
    private static let integrityKeyStorageKey = "pendingSyncIntegrityKey.v1"
    private let maxRetries = 3
    private let signaturePrefix = "hmac256:"
    private let integrityKey: Data

    var pendingCount: Int {
        pendingOperations.count
    }

    init() {
        self.integrityKey = Self.loadOrCreateIntegrityKey(storageKey: Self.integrityKeyStorageKey)
        self.pendingOperations = Self.loadPendingOperations(storageKey: storageKey)
    }

    // MARK: - Queue Operations

    func enqueue(type: SyncOperationType, payload: Data) {
        let checksum = signedChecksum(for: payload)
        let operation = PendingSyncOperation(type: type, payload: payload, payloadChecksum: checksum)
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
            guard verifyChecksum(for: operation.payload, checksum: operation.payloadChecksum) else {
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
        KeychainHelper.save(data, forKey: storageKey)
    }

    private static func loadPendingOperations(storageKey: String) -> [PendingSyncOperation] {
        guard let data = KeychainHelper.load(forKey: storageKey),
              let operations = try? JSONDecoder().decode([PendingSyncOperation].self, from: data) else {
            return []
        }
        return operations
    }

    private func signedChecksum(for payload: Data) -> String {
        let digest = hmacSHA256Hex(for: payload, key: integrityKey)
        return "\(signaturePrefix)\(digest)"
    }

    private func verifyChecksum(for payload: Data, checksum: String) -> Bool {
        guard checksum.hasPrefix(signaturePrefix) else { return false }
        return signedChecksum(for: payload) == checksum
    }

    private static func loadOrCreateIntegrityKey(storageKey: String) -> Data {
        if let storedKeyData = KeychainHelper.load(forKey: storageKey),
           storedKeyData.count >= 32 {
            return storedKeyData
        }

        var keyData = Data(count: 32)
        let status = keyData.withUnsafeMutableBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return errSecParam }
            return SecRandomCopyBytes(kSecRandomDefault, 32, baseAddress)
        }
        if status != errSecSuccess {
            keyData = UUID().uuidString.data(using: .utf8) ?? Data(repeating: 0x5A, count: 32)
        }

        KeychainHelper.save(keyData, forKey: storageKey)
        return keyData
    }

    private func hmacSHA256Hex(for data: Data, key: Data) -> String {
        let blockSize = 64 // SHA-256 block size in bytes
        var keyBytes = [UInt8](key)

        if keyBytes.count > blockSize {
            keyBytes = sha256Bytes(Data(keyBytes))
        }
        if keyBytes.count < blockSize {
            keyBytes += Array(repeating: 0, count: blockSize - keyBytes.count)
        }

        let oKeyPad = keyBytes.map { $0 ^ 0x5c }
        let iKeyPad = keyBytes.map { $0 ^ 0x36 }

        let innerHash = sha256Bytes(Data(iKeyPad) + data)
        let mac = sha256Bytes(Data(oKeyPad) + Data(innerHash))
        return mac.map { String(format: "%02x", $0) }.joined()
    }

    private func sha256Bytes(_ data: Data) -> [UInt8] {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = data.withUnsafeBytes { buffer in
            CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }
        return hash
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
    let promptText: String
    let answerText: String
    let sourceContext: String
    let easeFactor: Double
    let intervalDays: Double
    let halfLifeDays: Double
    let repetitions: Int
    let correctCount: Int
    let incorrectCount: Int
    let lastReviewedAt: Date?
    let nextReviewAt: Date

    init(
        id: UUID,
        userId: UUID,
        itemType: String,
        itemId: UUID,
        promptText: String = "",
        answerText: String = "",
        sourceContext: String = "",
        easeFactor: Double,
        intervalDays: Double,
        halfLifeDays: Double,
        repetitions: Int,
        correctCount: Int,
        incorrectCount: Int,
        lastReviewedAt: Date?,
        nextReviewAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.itemType = itemType
        self.itemId = itemId
        self.promptText = promptText
        self.answerText = answerText
        self.sourceContext = sourceContext
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
        self.halfLifeDays = halfLifeDays
        self.repetitions = repetitions
        self.correctCount = correctCount
        self.incorrectCount = incorrectCount
        self.lastReviewedAt = lastReviewedAt
        self.nextReviewAt = nextReviewAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case itemType = "item_type"
        case itemId = "item_id"
        case promptText = "prompt_text"
        case answerText = "answer_text"
        case sourceContext = "source_context"
        case easeFactor = "ease_factor"
        case intervalDays = "interval_days"
        case halfLifeDays = "half_life_days"
        case repetitions
        case correctCount = "correct_count"
        case incorrectCount = "incorrect_count"
        case lastReviewedAt = "last_reviewed_at"
        case nextReviewAt = "next_review_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        itemType = try container.decode(String.self, forKey: .itemType)
        itemId = try container.decode(UUID.self, forKey: .itemId)
        promptText = try container.decodeIfPresent(String.self, forKey: .promptText) ?? ""
        answerText = try container.decodeIfPresent(String.self, forKey: .answerText) ?? ""
        sourceContext = try container.decodeIfPresent(String.self, forKey: .sourceContext) ?? ""
        easeFactor = try container.decode(Double.self, forKey: .easeFactor)
        intervalDays = try container.decode(Double.self, forKey: .intervalDays)
        halfLifeDays = try container.decode(Double.self, forKey: .halfLifeDays)
        repetitions = try container.decode(Int.self, forKey: .repetitions)
        correctCount = try container.decode(Int.self, forKey: .correctCount)
        incorrectCount = try container.decode(Int.self, forKey: .incorrectCount)
        lastReviewedAt = try container.decodeIfPresent(Date.self, forKey: .lastReviewedAt)
        nextReviewAt = try container.decode(Date.self, forKey: .nextReviewAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(itemType, forKey: .itemType)
        try container.encode(itemId, forKey: .itemId)
        try container.encode(promptText, forKey: .promptText)
        try container.encode(answerText, forKey: .answerText)
        try container.encode(sourceContext, forKey: .sourceContext)
        try container.encode(easeFactor, forKey: .easeFactor)
        try container.encode(intervalDays, forKey: .intervalDays)
        try container.encode(halfLifeDays, forKey: .halfLifeDays)
        try container.encode(repetitions, forKey: .repetitions)
        try container.encode(correctCount, forKey: .correctCount)
        try container.encode(incorrectCount, forKey: .incorrectCount)
        try container.encode(lastReviewedAt, forKey: .lastReviewedAt)
        try container.encode(nextReviewAt, forKey: .nextReviewAt)
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
