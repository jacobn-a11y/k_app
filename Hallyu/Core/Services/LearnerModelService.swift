import Foundation

/// Bayesian Knowledge Tracing implementation for per-skill mastery tracking.
/// Tracks learner proficiency across multiple dimensions: accuracy, speed, retention.
final class LearnerModelService: LearnerModelServiceProtocol, @unchecked Sendable {

    // MARK: - Skill Types

    static let skillTypes: [String] = [
        "hangul_recognition",
        "hangul_production",
        "vocab_recognition",
        "vocab_production",
        "grammar",
        "listening",
        "reading",
        "pronunciation"
    ]

    // MARK: - BKT Parameters

    /// Prior probability of knowing the skill before any observation
    let pInit: Double = 0.1

    /// Probability of learning a skill from one opportunity to the next
    let pLearn: Double = 0.15

    /// Probability of a slip (incorrect despite knowing)
    let pSlip: Double = 0.1

    /// Probability of a guess (correct despite not knowing)
    let pGuess: Double = 0.25

    // MARK: - CEFR Thresholds

    /// Minimum aggregate mastery to reach each CEFR level
    static let cefrThresholds: [(level: CEFRLevel, threshold: Double)] = [
        (.b2, 0.90),
        (.b1, 0.75),
        (.a2, 0.55),
        (.a1, 0.30),
        (.preA1, 0.0),
    ]

    // MARK: - Speed Normalization

    /// Expected response time for a "mastered" item (ms)
    let targetSpeedMs: Double = 2000.0

    /// Maximum response time to consider (ms) — anything slower is capped
    let maxSpeedMs: Double = 15000.0

    // MARK: - Storage

    /// In-memory store for development. Production would use SwiftData/Supabase.
    private var masteryStore: [String: SkillMastery] = [:]

    private func storeKey(userId: UUID, skillType: String, skillId: String) -> String {
        "\(userId)_\(skillType)_\(skillId)"
    }

    // MARK: - Protocol Implementation

    func updateMastery(userId: UUID, skillType: String, skillId: String, wasCorrect: Bool, responseTime: TimeInterval) async throws {
        let key = storeKey(userId: userId, skillType: skillType, skillId: skillId)

        var mastery = masteryStore[key] ?? SkillMastery(
            userId: userId,
            skillType: skillType,
            skillId: skillId
        )

        // Bayesian update of accuracy (knowledge probability)
        let pKnown = mastery.accuracy > 0 ? mastery.accuracy : pInit
        let posteriorKnown = bayesianUpdate(pKnown: pKnown, wasCorrect: wasCorrect)

        // Learning transition: P(Ln) = P(Ln-1|obs) + (1 - P(Ln-1|obs)) * P(T)
        let newAccuracy = posteriorKnown + (1.0 - posteriorKnown) * pLearn

        // Speed tracking (exponential moving average)
        let responseMs = responseTime * 1000.0
        let clampedSpeed = min(responseMs, maxSpeedMs)
        let alpha = 0.3 // smoothing factor
        let previousSpeed = mastery.speedMs ?? maxSpeedMs
        let newSpeed = alpha * clampedSpeed + (1.0 - alpha) * previousSpeed

        // Retention: blend of accuracy and speed performance
        let speedScore = max(0, 1.0 - (newSpeed / maxSpeedMs))
        let newRetention = 0.7 * newAccuracy + 0.3 * speedScore

        mastery.accuracy = min(max(newAccuracy, 0.0), 1.0)
        mastery.speedMs = newSpeed
        mastery.retention = min(max(newRetention, 0.0), 1.0)
        mastery.attempts += 1
        mastery.lastAssessedAt = Date()

        masteryStore[key] = mastery
    }

    func getMastery(userId: UUID, skillType: String, skillId: String) async throws -> SkillMastery? {
        let key = storeKey(userId: userId, skillType: skillType, skillId: skillId)
        return masteryStore[key]
    }

    func getOverallLevel(userId: UUID) async throws -> String {
        let level = try await computeCEFRLevel(userId: userId)
        return level.rawValue
    }

    // MARK: - Additional Methods

    /// Get all mastery entries for a user, optionally filtered by skill type.
    func getAllMastery(userId: UUID, skillType: String? = nil) -> [SkillMastery] {
        let prefix = "\(userId)_"
        return masteryStore
            .filter { key, _ in
                guard key.hasPrefix(prefix) else { return false }
                if let type = skillType {
                    return key.hasPrefix("\(prefix)\(type)_")
                }
                return true
            }
            .map { $0.value }
    }

    /// Compute the aggregate mastery score across all skills for a user.
    func aggregateMastery(userId: UUID) -> Double {
        let entries = getAllMastery(userId: userId)
        guard !entries.isEmpty else { return 0.0 }

        // Weight by attempts (more-practiced skills carry more weight)
        let totalWeight = entries.reduce(0.0) { $0 + Double($1.attempts) }
        guard totalWeight > 0 else { return 0.0 }

        let weightedSum = entries.reduce(0.0) { sum, entry in
            sum + entry.accuracy * Double(entry.attempts)
        }

        return weightedSum / totalWeight
    }

    /// Determine CEFR level based on aggregate mastery.
    func computeCEFRLevel(userId: UUID) async throws -> CEFRLevel {
        let aggregate = aggregateMastery(userId: userId)

        for (level, threshold) in Self.cefrThresholds {
            if aggregate >= threshold {
                return level
            }
        }

        return .preA1
    }

    // MARK: - Bayesian Update

    /// Standard BKT posterior update.
    /// P(K|correct) = P(K) * (1 - P(S)) / [P(K)*(1-P(S)) + (1-P(K))*P(G)]
    /// P(K|incorrect) = P(K) * P(S) / [P(K)*P(S) + (1-P(K))*(1-P(G))]
    func bayesianUpdate(pKnown: Double, wasCorrect: Bool) -> Double {
        if wasCorrect {
            let numerator = pKnown * (1.0 - pSlip)
            let denominator = pKnown * (1.0 - pSlip) + (1.0 - pKnown) * pGuess
            guard denominator > 0 else { return pKnown }
            return numerator / denominator
        } else {
            let numerator = pKnown * pSlip
            let denominator = pKnown * pSlip + (1.0 - pKnown) * (1.0 - pGuess)
            guard denominator > 0 else { return pKnown }
            return numerator / denominator
        }
    }

    /// Reset mastery store (for testing).
    func reset() {
        masteryStore.removeAll()
    }
}
