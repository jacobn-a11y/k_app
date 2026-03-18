import Testing
import Foundation
@testable import HallyuCore

@Suite("LearnerModelService Tests")
struct LearnerModelServiceTests {

    private let userId = UUID()

    private func makeService() -> LearnerModelService {
        LearnerModelService()
    }

    // MARK: - Mastery Updates

    @Test("First correct answer creates mastery entry with increased accuracy")
    func firstCorrectAnswer() async throws {
        let service = makeService()
        try await service.updateMastery(userId: userId, skillType: "vocab_recognition", skillId: "word_1", wasCorrect: true, responseTime: 2.0)

        let mastery = try await service.getMastery(userId: userId, skillType: "vocab_recognition", skillId: "word_1")
        #expect(mastery != nil)
        #expect(mastery!.accuracy > 0.1) // should be higher than pInit
        #expect(mastery!.attempts == 1)
    }

    @Test("First incorrect answer creates mastery with decreased accuracy")
    func firstIncorrectAnswer() async throws {
        let service = makeService()
        try await service.updateMastery(userId: userId, skillType: "vocab_recognition", skillId: "word_1", wasCorrect: false, responseTime: 5.0)

        let mastery = try await service.getMastery(userId: userId, skillType: "vocab_recognition", skillId: "word_1")
        #expect(mastery != nil)
        #expect(mastery!.accuracy < 0.5)
    }

    @Test("Mastery converges toward 1.0 with repeated successes")
    func masteryConverges() async throws {
        let service = makeService()

        for _ in 0..<20 {
            try await service.updateMastery(userId: userId, skillType: "hangul_recognition", skillId: "ㄱ", wasCorrect: true, responseTime: 1.5)
        }

        let mastery = try await service.getMastery(userId: userId, skillType: "hangul_recognition", skillId: "ㄱ")
        #expect(mastery != nil)
        #expect(mastery!.accuracy > 0.9, "Accuracy should converge toward 1.0 after many correct answers, got \(mastery!.accuracy)")
    }

    @Test("Mastery decreases with repeated failures")
    func masteryDecreases() async throws {
        let service = makeService()

        // Build up mastery first
        for _ in 0..<10 {
            try await service.updateMastery(userId: userId, skillType: "vocab_recognition", skillId: "word_1", wasCorrect: true, responseTime: 2.0)
        }

        let highMastery = try await service.getMastery(userId: userId, skillType: "vocab_recognition", skillId: "word_1")

        // Then fail repeatedly
        for _ in 0..<10 {
            try await service.updateMastery(userId: userId, skillType: "vocab_recognition", skillId: "word_1", wasCorrect: false, responseTime: 8.0)
        }

        let lowMastery = try await service.getMastery(userId: userId, skillType: "vocab_recognition", skillId: "word_1")
        #expect(lowMastery!.accuracy < highMastery!.accuracy)
    }

    @Test("Attempts count increments correctly")
    func attemptsCount() async throws {
        let service = makeService()

        for _ in 0..<5 {
            try await service.updateMastery(userId: userId, skillType: "grammar", skillId: "pattern_1", wasCorrect: true, responseTime: 3.0)
        }

        let mastery = try await service.getMastery(userId: userId, skillType: "grammar", skillId: "pattern_1")
        #expect(mastery?.attempts == 5)
    }

    // MARK: - Speed Tracking

    @Test("Speed is tracked via exponential moving average")
    func speedTracking() async throws {
        let service = makeService()

        // Fast response
        try await service.updateMastery(userId: userId, skillType: "vocab_recognition", skillId: "word_1", wasCorrect: true, responseTime: 1.0)
        let mastery1 = try await service.getMastery(userId: userId, skillType: "vocab_recognition", skillId: "word_1")

        // Slow response
        try await service.updateMastery(userId: userId, skillType: "vocab_recognition", skillId: "word_1", wasCorrect: true, responseTime: 10.0)
        let mastery2 = try await service.getMastery(userId: userId, skillType: "vocab_recognition", skillId: "word_1")

        #expect(mastery2!.speedMs! > mastery1!.speedMs!)
    }

    @Test("Speed is capped at maximum")
    func speedCapped() async throws {
        let service = makeService()

        try await service.updateMastery(userId: userId, skillType: "vocab_recognition", skillId: "word_1", wasCorrect: true, responseTime: 60.0) // very slow
        let mastery = try await service.getMastery(userId: userId, skillType: "vocab_recognition", skillId: "word_1")

        #expect(mastery!.speedMs! <= service.maxSpeedMs)
    }

    // MARK: - Retention

    @Test("Retention reflects both accuracy and speed")
    func retentionBlend() async throws {
        let service = makeService()

        // Good accuracy + fast speed → high retention
        for _ in 0..<10 {
            try await service.updateMastery(userId: userId, skillType: "hangul_recognition", skillId: "fast", wasCorrect: true, responseTime: 1.0)
        }
        let fastMastery = try await service.getMastery(userId: userId, skillType: "hangul_recognition", skillId: "fast")

        let service2 = makeService()
        // Good accuracy + slow speed → lower retention
        for _ in 0..<10 {
            try await service2.updateMastery(userId: userId, skillType: "hangul_recognition", skillId: "slow", wasCorrect: true, responseTime: 12.0)
        }
        let slowMastery = try await service2.getMastery(userId: userId, skillType: "hangul_recognition", skillId: "slow")

        #expect(fastMastery!.retention > slowMastery!.retention)
    }

    // MARK: - Bayesian Update

    @Test("Bayesian update increases probability on correct answer")
    func bayesianCorrect() {
        let service = makeService()
        let prior = 0.5
        let posterior = service.bayesianUpdate(pKnown: prior, wasCorrect: true)
        #expect(posterior > prior)
    }

    @Test("Bayesian update decreases probability on incorrect answer")
    func bayesianIncorrect() {
        let service = makeService()
        let prior = 0.5
        let posterior = service.bayesianUpdate(pKnown: prior, wasCorrect: false)
        #expect(posterior < prior)
    }

    @Test("Bayesian update keeps probability in [0,1] range")
    func bayesianRange() {
        let service = makeService()

        for p in stride(from: 0.0, through: 1.0, by: 0.1) {
            let correct = service.bayesianUpdate(pKnown: p, wasCorrect: true)
            let incorrect = service.bayesianUpdate(pKnown: p, wasCorrect: false)
            #expect(correct >= 0 && correct <= 1, "Correct posterior out of range for p=\(p): \(correct)")
            #expect(incorrect >= 0 && incorrect <= 1, "Incorrect posterior out of range for p=\(p): \(incorrect)")
        }
    }

    // MARK: - CEFR Level

    @Test("New user starts at pre-A1")
    func newUserLevel() async throws {
        let service = makeService()
        let level = try await service.getOverallLevel(userId: userId)
        #expect(level == "pre-A1")
    }

    @Test("CEFR level increases with mastery")
    func cefrProgression() async throws {
        let service = makeService()

        // Build up high mastery across many skills
        for i in 0..<20 {
            for _ in 0..<30 {
                try await service.updateMastery(userId: userId, skillType: "vocab_recognition", skillId: "word_\(i)", wasCorrect: true, responseTime: 1.5)
            }
        }

        let level = try await service.computeCEFRLevel(userId: userId)
        #expect(level > .preA1)
    }

    @Test("CEFR thresholds are ordered correctly")
    func cefrThresholds() {
        let thresholds = LearnerModelService.cefrThresholds
        for i in 0..<(thresholds.count - 1) {
            #expect(thresholds[i].threshold > thresholds[i + 1].threshold,
                    "Thresholds should be in descending order")
        }
    }

    // MARK: - Aggregate Mastery

    @Test("Aggregate mastery is 0 for new user")
    func aggregateNewUser() {
        let service = makeService()
        let aggregate = service.aggregateMastery(userId: userId)
        #expect(aggregate == 0.0)
    }

    @Test("Aggregate mastery weights by attempts")
    func aggregateWeighted() async throws {
        let service = makeService()

        // Skill A: high mastery, many attempts
        for _ in 0..<20 {
            try await service.updateMastery(userId: userId, skillType: "vocab_recognition", skillId: "a", wasCorrect: true, responseTime: 1.5)
        }

        // Skill B: low mastery, few attempts
        try await service.updateMastery(userId: userId, skillType: "vocab_recognition", skillId: "b", wasCorrect: false, responseTime: 10.0)

        let aggregate = service.aggregateMastery(userId: userId)
        let masteryA = try await service.getMastery(userId: userId, skillType: "vocab_recognition", skillId: "a")

        // Aggregate should be closer to A's mastery since it has more weight
        #expect(aggregate > 0.5, "Aggregate should be weighted toward high-mastery skill")
        #expect(aggregate < masteryA!.accuracy, "Aggregate should be below A's accuracy due to B")
    }

    // MARK: - getAllMastery

    @Test("getAllMastery returns entries filtered by skill type")
    func getAllMasteryFiltered() async throws {
        let service = makeService()

        try await service.updateMastery(userId: userId, skillType: "vocab_recognition", skillId: "w1", wasCorrect: true, responseTime: 2.0)
        try await service.updateMastery(userId: userId, skillType: "hangul_recognition", skillId: "ㄱ", wasCorrect: true, responseTime: 2.0)

        let vocabOnly = service.getAllMastery(userId: userId, skillType: "vocab_recognition")
        #expect(vocabOnly.count == 1)
        #expect(vocabOnly.first?.skillType == "vocab_recognition")
    }

    @Test("getAllMastery returns all entries when no filter")
    func getAllMasteryUnfiltered() async throws {
        let service = makeService()

        try await service.updateMastery(userId: userId, skillType: "vocab_recognition", skillId: "w1", wasCorrect: true, responseTime: 2.0)
        try await service.updateMastery(userId: userId, skillType: "hangul_recognition", skillId: "ㄱ", wasCorrect: true, responseTime: 2.0)

        let all = service.getAllMastery(userId: userId)
        #expect(all.count == 2)
    }

    // MARK: - Non-existent Lookup

    @Test("getMastery returns nil for non-existent skill")
    func nonExistentMastery() async throws {
        let service = makeService()
        let mastery = try await service.getMastery(userId: userId, skillType: "vocab", skillId: "nope")
        #expect(mastery == nil)
    }

    // MARK: - Reset

    @Test("Reset clears all mastery data")
    func resetClears() async throws {
        let service = makeService()
        try await service.updateMastery(userId: userId, skillType: "vocab_recognition", skillId: "w1", wasCorrect: true, responseTime: 2.0)
        service.reset()
        let mastery = try await service.getMastery(userId: userId, skillType: "vocab_recognition", skillId: "w1")
        #expect(mastery == nil)
    }
}
