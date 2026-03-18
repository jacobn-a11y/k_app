import Foundation
import SwiftData

@Model
final class StudySession: Codable {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var sessionType: String
    var durationSeconds: Int
    var itemsStudied: Int
    var itemsCorrect: Int
    var mediaContentId: UUID?
    var sessionDataStorage: Data?
    var startedAt: Date
    var completedAt: Date?

    var sessionData: [String: String] {
        get {
            guard let data = sessionDataStorage else { return [:] }
            return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
        }
        set {
            sessionDataStorage = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        sessionType: String,
        durationSeconds: Int = 0,
        itemsStudied: Int = 0,
        itemsCorrect: Int = 0,
        mediaContentId: UUID? = nil,
        sessionData: [String: String] = [:],
        startedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.sessionType = sessionType
        self.durationSeconds = durationSeconds
        self.itemsStudied = itemsStudied
        self.itemsCorrect = itemsCorrect
        self.mediaContentId = mediaContentId
        self.sessionDataStorage = try? JSONEncoder().encode(sessionData)
        self.startedAt = startedAt
        self.completedAt = completedAt
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sessionType = "session_type"
        case durationSeconds = "duration_seconds"
        case itemsStudied = "items_studied"
        case itemsCorrect = "items_correct"
        case mediaContentId = "media_content_id"
        case sessionDataStorage = "session_data"
        case startedAt = "started_at"
        case completedAt = "completed_at"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        sessionType = try container.decode(String.self, forKey: .sessionType)
        durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds) ?? 0
        itemsStudied = try container.decodeIfPresent(Int.self, forKey: .itemsStudied) ?? 0
        itemsCorrect = try container.decodeIfPresent(Int.self, forKey: .itemsCorrect) ?? 0
        mediaContentId = try container.decodeIfPresent(UUID.self, forKey: .mediaContentId)
        sessionDataStorage = try container.decodeIfPresent(Data.self, forKey: .sessionDataStorage)
        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt) ?? Date()
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(sessionType, forKey: .sessionType)
        try container.encode(durationSeconds, forKey: .durationSeconds)
        try container.encode(itemsStudied, forKey: .itemsStudied)
        try container.encode(itemsCorrect, forKey: .itemsCorrect)
        try container.encode(mediaContentId, forKey: .mediaContentId)
        try container.encode(sessionDataStorage, forKey: .sessionDataStorage)
        try container.encode(startedAt, forKey: .startedAt)
        try container.encode(completedAt, forKey: .completedAt)
    }
}
