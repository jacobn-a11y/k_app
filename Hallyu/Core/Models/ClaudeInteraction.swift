import Foundation
import SwiftData

@Model
final class ClaudeInteraction: Codable {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var role: String
    var contextMediaId: UUID?
    var userQuery: String
    var claudeResponse: String
    var promptTokens: Int
    var completionTokens: Int
    var cached: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        role: String,
        contextMediaId: UUID? = nil,
        userQuery: String = "",
        claudeResponse: String = "",
        promptTokens: Int = 0,
        completionTokens: Int = 0,
        cached: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.role = role
        self.contextMediaId = contextMediaId
        self.userQuery = userQuery
        self.claudeResponse = claudeResponse
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.cached = cached
        self.createdAt = createdAt
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case role
        case contextMediaId = "context_media_id"
        case userQuery = "user_query"
        case claudeResponse = "claude_response"
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case cached
        case createdAt = "created_at"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        role = try container.decode(String.self, forKey: .role)
        contextMediaId = try container.decodeIfPresent(UUID.self, forKey: .contextMediaId)
        userQuery = try container.decodeIfPresent(String.self, forKey: .userQuery) ?? ""
        claudeResponse = try container.decodeIfPresent(String.self, forKey: .claudeResponse) ?? ""
        promptTokens = try container.decodeIfPresent(Int.self, forKey: .promptTokens) ?? 0
        completionTokens = try container.decodeIfPresent(Int.self, forKey: .completionTokens) ?? 0
        cached = try container.decodeIfPresent(Bool.self, forKey: .cached) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(role, forKey: .role)
        try container.encode(contextMediaId, forKey: .contextMediaId)
        try container.encode(userQuery, forKey: .userQuery)
        try container.encode(claudeResponse, forKey: .claudeResponse)
        try container.encode(promptTokens, forKey: .promptTokens)
        try container.encode(completionTokens, forKey: .completionTokens)
        try container.encode(cached, forKey: .cached)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
