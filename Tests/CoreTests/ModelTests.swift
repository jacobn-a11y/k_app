import Testing
import Foundation
@testable import HallyuCore

@Suite("SwiftData Model Tests")
struct ModelTests {

    // MARK: - LearnerProfile

    @Test("LearnerProfile initializes with defaults")
    func learnerProfileDefaults() {
        let profile = LearnerProfile()
        #expect(profile.nativeLanguage == "en")
        #expect(profile.cefrLevel == "pre-A1")
        #expect(profile.onboardingCompleted == false)
        #expect(profile.hangulCompleted == false)
        #expect(profile.dailyGoalMinutes == 15)
        #expect(profile.subscriptionTier == "free")
    }

    @Test("LearnerProfile initializes with custom values")
    func learnerProfileCustom() {
        let profile = LearnerProfile(
            displayName: "Test User",
            cefrLevel: "A1",
            dailyGoalMinutes: 30,
            subscriptionTier: "core"
        )
        #expect(profile.displayName == "Test User")
        #expect(profile.cefrLevel == "A1")
        #expect(profile.dailyGoalMinutes == 30)
        #expect(profile.subscriptionTier == "core")
    }

    @Test("LearnerProfile Codable roundtrip")
    func learnerProfileCodable() throws {
        let original = LearnerProfile(displayName: "Coder", cefrLevel: "B1")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LearnerProfile.self, from: data)
        #expect(decoded.displayName == "Coder")
        #expect(decoded.cefrLevel == "B1")
        #expect(decoded.userId == original.userId)
    }

    // MARK: - VocabularyItem

    @Test("VocabularyItem initializes correctly")
    func vocabularyItemInit() {
        let item = VocabularyItem(
            korean: "안녕하세요",
            romanization: "annyeonghaseyo",
            english: "Hello",
            partOfSpeech: "interjection",
            frequencyRank: 1
        )
        #expect(item.korean == "안녕하세요")
        #expect(item.english == "Hello")
        #expect(item.frequencyRank == 1)
    }

    @Test("VocabularyItem Codable roundtrip")
    func vocabularyItemCodable() throws {
        let original = VocabularyItem(korean: "물", english: "water", cefrLevel: "A1")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(VocabularyItem.self, from: data)
        #expect(decoded.korean == "물")
        #expect(decoded.english == "water")
    }

    // MARK: - GrammarPattern

    @Test("GrammarPattern with example sentences")
    func grammarPatternExamples() {
        let examples = [
            GrammarPattern.ExampleSentence(kr: "나는 학생이에요", en: "I am a student", context: "self-introduction")
        ]
        let pattern = GrammarPattern(
            patternName: "Subject marker -이/가",
            patternTemplate: "[noun]-이/가",
            explanation: "Marks the subject of a sentence",
            exampleSentences: examples
        )
        #expect(pattern.patternName == "Subject marker -이/가")
        #expect(pattern.exampleSentences.count == 1)
        #expect(pattern.exampleSentences.first?.kr == "나는 학생이에요")
    }

    // MARK: - ReviewItem

    @Test("ReviewItem initializes with SRS defaults")
    func reviewItemDefaults() {
        let item = ReviewItem(
            userId: UUID(),
            itemType: "vocabulary",
            itemId: UUID()
        )
        #expect(item.easeFactor == 2.5)
        #expect(item.intervalDays == 0)
        #expect(item.halfLifeDays == 1.0)
        #expect(item.repetitions == 0)
        #expect(item.correctCount == 0)
        #expect(item.incorrectCount == 0)
    }

    @Test("ReviewItem Codable roundtrip")
    func reviewItemCodable() throws {
        let userId = UUID()
        let itemId = UUID()
        let original = ReviewItem(userId: userId, itemType: "grammar", itemId: itemId)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ReviewItem.self, from: data)
        #expect(decoded.userId == userId)
        #expect(decoded.itemType == "grammar")
        #expect(decoded.itemId == itemId)
    }

    // MARK: - SkillMastery

    @Test("SkillMastery initializes with zero mastery")
    func skillMasteryDefaults() {
        let mastery = SkillMastery(
            userId: UUID(),
            skillType: "hangul_recognition",
            skillId: "ㄱ"
        )
        #expect(mastery.accuracy == 0.0)
        #expect(mastery.retention == 0.0)
        #expect(mastery.attempts == 0)
    }

    // MARK: - StudySession

    @Test("StudySession stores session data")
    func studySessionData() {
        let session = StudySession(
            userId: UUID(),
            sessionType: "hangul",
            sessionData: ["lesson": "jamo_group_1"]
        )
        #expect(session.sessionType == "hangul")
        #expect(session.sessionData["lesson"] == "jamo_group_1")
    }

    // MARK: - MediaContent

    @Test("MediaContent with transcript segments")
    func mediaContentSegments() {
        let segments = [
            MediaContent.TranscriptSegment(startMs: 0, endMs: 3000, textKr: "안녕하세요", textEn: "Hello")
        ]
        let content = MediaContent(
            title: "Test Drama",
            contentType: "drama",
            transcriptSegments: segments
        )
        #expect(content.transcriptSegments.count == 1)
        #expect(content.transcriptSegments.first?.textKr == "안녕하세요")
    }

    // MARK: - ClaudeInteraction

    @Test("ClaudeInteraction initializes correctly")
    func claudeInteractionInit() {
        let interaction = ClaudeInteraction(
            userId: UUID(),
            role: "comprehension",
            userQuery: "What does this mean?",
            claudeResponse: "It means hello",
            promptTokens: 100,
            completionTokens: 50
        )
        #expect(interaction.role == "comprehension")
        #expect(interaction.promptTokens == 100)
        #expect(interaction.cached == false)
    }
}
