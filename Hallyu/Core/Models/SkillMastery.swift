import Foundation
import SwiftData

@Model
final class SkillMastery: Codable {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var skillType: String
    var skillId: String
    var accuracy: Double
    var speedMs: Double?
    var retention: Double
    var attempts: Int
    var lastAssessedAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        skillType: String,
        skillId: String,
        accuracy: Double = 0.0,
        speedMs: Double? = nil,
        retention: Double = 0.0,
        attempts: Int = 0,
        lastAssessedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.skillType = skillType
        self.skillId = skillId
        self.accuracy = accuracy
        self.speedMs = speedMs
        self.retention = retention
        self.attempts = attempts
        self.lastAssessedAt = lastAssessedAt
        self.createdAt = createdAt
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case skillType = "skill_type"
        case skillId = "skill_id"
        case accuracy
        case speedMs = "speed_ms"
        case retention
        case attempts
        case lastAssessedAt = "last_assessed_at"
        case createdAt = "created_at"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        skillType = try container.decode(String.self, forKey: .skillType)
        skillId = try container.decode(String.self, forKey: .skillId)
        accuracy = try container.decodeIfPresent(Double.self, forKey: .accuracy) ?? 0.0
        speedMs = try container.decodeIfPresent(Double.self, forKey: .speedMs)
        retention = try container.decodeIfPresent(Double.self, forKey: .retention) ?? 0.0
        attempts = try container.decodeIfPresent(Int.self, forKey: .attempts) ?? 0
        lastAssessedAt = try container.decodeIfPresent(Date.self, forKey: .lastAssessedAt)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(skillType, forKey: .skillType)
        try container.encode(skillId, forKey: .skillId)
        try container.encode(accuracy, forKey: .accuracy)
        try container.encode(speedMs, forKey: .speedMs)
        try container.encode(retention, forKey: .retention)
        try container.encode(attempts, forKey: .attempts)
        try container.encode(lastAssessedAt, forKey: .lastAssessedAt)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
