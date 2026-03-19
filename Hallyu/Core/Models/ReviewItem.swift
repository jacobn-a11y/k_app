import Foundation
import SwiftData

@Model
final class ReviewItem: Codable {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var itemType: String
    var itemId: UUID
    var promptText: String
    var answerText: String
    var sourceContext: String
    var easeFactor: Double
    var intervalDays: Double
    var halfLifeDays: Double
    var repetitions: Int
    var correctCount: Int
    var incorrectCount: Int
    var lastReviewedAt: Date?
    var nextReviewAt: Date
    var createdAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        itemType: String,
        itemId: UUID,
        promptText: String = "",
        answerText: String = "",
        sourceContext: String = "",
        easeFactor: Double = 2.5,
        intervalDays: Double = 0,
        halfLifeDays: Double = 1.0,
        repetitions: Int = 0,
        correctCount: Int = 0,
        incorrectCount: Int = 0,
        lastReviewedAt: Date? = nil,
        nextReviewAt: Date = Date(),
        createdAt: Date = Date()
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
        self.createdAt = createdAt
    }

    // MARK: - Codable

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
        case createdAt = "created_at"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        itemType = try container.decode(String.self, forKey: .itemType)
        itemId = try container.decode(UUID.self, forKey: .itemId)
        promptText = try container.decodeIfPresent(String.self, forKey: .promptText) ?? ""
        answerText = try container.decodeIfPresent(String.self, forKey: .answerText) ?? ""
        sourceContext = try container.decodeIfPresent(String.self, forKey: .sourceContext) ?? ""
        easeFactor = try container.decodeIfPresent(Double.self, forKey: .easeFactor) ?? 2.5
        intervalDays = try container.decodeIfPresent(Double.self, forKey: .intervalDays) ?? 0
        halfLifeDays = try container.decodeIfPresent(Double.self, forKey: .halfLifeDays) ?? 1.0
        repetitions = try container.decodeIfPresent(Int.self, forKey: .repetitions) ?? 0
        correctCount = try container.decodeIfPresent(Int.self, forKey: .correctCount) ?? 0
        incorrectCount = try container.decodeIfPresent(Int.self, forKey: .incorrectCount) ?? 0
        lastReviewedAt = try container.decodeIfPresent(Date.self, forKey: .lastReviewedAt)
        nextReviewAt = try container.decodeIfPresent(Date.self, forKey: .nextReviewAt) ?? Date()
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
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
        try container.encode(createdAt, forKey: .createdAt)
    }
}
