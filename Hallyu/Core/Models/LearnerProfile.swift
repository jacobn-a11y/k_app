import Foundation
import SwiftData

@Model
final class LearnerProfile: Codable {
    @Attribute(.unique) var userId: UUID
    var displayName: String
    var nativeLanguage: String
    var cefrLevel: String
    var onboardingCompleted: Bool
    var hangulCompleted: Bool
    var dailyGoalMinutes: Int
    var subscriptionTier: String
    var createdAt: Date
    var updatedAt: Date

    init(
        userId: UUID = UUID(),
        displayName: String = "",
        nativeLanguage: String = "en",
        cefrLevel: String = "pre-A1",
        onboardingCompleted: Bool = false,
        hangulCompleted: Bool = false,
        dailyGoalMinutes: Int = 15,
        subscriptionTier: String = "free",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.userId = userId
        self.displayName = displayName
        self.nativeLanguage = nativeLanguage
        self.cefrLevel = cefrLevel
        self.onboardingCompleted = onboardingCompleted
        self.hangulCompleted = hangulCompleted
        self.dailyGoalMinutes = dailyGoalMinutes
        self.subscriptionTier = subscriptionTier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case nativeLanguage = "native_language"
        case cefrLevel = "cefr_level"
        case onboardingCompleted = "onboarding_completed"
        case hangulCompleted = "hangul_completed"
        case dailyGoalMinutes = "daily_goal_minutes"
        case subscriptionTier = "subscription_tier"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decode(UUID.self, forKey: .userId)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        nativeLanguage = try container.decodeIfPresent(String.self, forKey: .nativeLanguage) ?? "en"
        cefrLevel = try container.decodeIfPresent(String.self, forKey: .cefrLevel) ?? "pre-A1"
        onboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .onboardingCompleted) ?? false
        hangulCompleted = try container.decodeIfPresent(Bool.self, forKey: .hangulCompleted) ?? false
        dailyGoalMinutes = try container.decodeIfPresent(Int.self, forKey: .dailyGoalMinutes) ?? 15
        subscriptionTier = try container.decodeIfPresent(String.self, forKey: .subscriptionTier) ?? "free"
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(nativeLanguage, forKey: .nativeLanguage)
        try container.encode(cefrLevel, forKey: .cefrLevel)
        try container.encode(onboardingCompleted, forKey: .onboardingCompleted)
        try container.encode(hangulCompleted, forKey: .hangulCompleted)
        try container.encode(dailyGoalMinutes, forKey: .dailyGoalMinutes)
        try container.encode(subscriptionTier, forKey: .subscriptionTier)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
