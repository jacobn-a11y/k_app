import Testing
import Foundation
@testable import HallyuCore

@Suite("MediaMetadataService Tests")
struct MediaMetadataServiceTests {

    // MARK: - Helpers

    private func makeVocabItem(korean: String, english: String, domains: [String] = [], cefrLevel: String = "A1") -> VocabularyItem {
        VocabularyItem(
            korean: korean,
            english: english,
            cefrLevel: cefrLevel,
            mediaDomains: domains
        )
    }

    private func makeGrammarPattern(name: String, template: String, cefrLevel: String = "A1") -> GrammarPattern {
        GrammarPattern(
            patternName: name,
            patternTemplate: template,
            explanation: "test",
            cefrLevel: cefrLevel
        )
    }

    // MARK: - Empty Input

    @Test("Empty transcript returns default metadata")
    func emptyTranscript() {
        let result = MediaMetadataService.analyze(
            transcript: "",
            vocabularyItems: [],
            grammarPatterns: []
        )
        #expect(result.vocabularyIds.isEmpty)
        #expect(result.grammarPatternIds.isEmpty)
        #expect(result.autoTags.isEmpty)
        #expect(result.difficultyScore == 0.5)
        #expect(result.cefrLevel == "A2")
    }

    // MARK: - Vocabulary Matching

    @Test("Matches vocabulary items present in transcript")
    func matchesVocabulary() {
        let vocab = [
            makeVocabItem(korean: "안녕하세요", english: "hello", domains: ["greeting"]),
            makeVocabItem(korean: "커피", english: "coffee", domains: ["cafe", "food"]),
            makeVocabItem(korean: "병원", english: "hospital", domains: ["medical"]),
        ]

        let result = MediaMetadataService.analyze(
            transcript: "안녕하세요. 커피 주세요.",
            vocabularyItems: vocab,
            grammarPatterns: []
        )

        #expect(result.vocabularyIds.count == 2)
        #expect(result.vocabularyIds.contains(vocab[0].id)) // 안녕하세요
        #expect(result.vocabularyIds.contains(vocab[1].id)) // 커피
        #expect(!result.vocabularyIds.contains(vocab[2].id)) // 병원 not in transcript
    }

    @Test("No vocabulary match when items don't appear in transcript")
    func noVocabularyMatch() {
        let vocab = [
            makeVocabItem(korean: "병원", english: "hospital", domains: ["medical"]),
        ]

        let result = MediaMetadataService.analyze(
            transcript: "안녕하세요. 오늘 날씨가 좋아요.",
            vocabularyItems: vocab,
            grammarPatterns: []
        )

        #expect(result.vocabularyIds.isEmpty)
    }

    // MARK: - Grammar Pattern Matching

    @Test("Matches grammar patterns detected in transcript")
    func matchesGrammar() {
        let patterns = [
            makeGrammarPattern(name: "polite ending -아/어요", template: "V + 아/어요", cefrLevel: "A1"),
            makeGrammarPattern(name: "desire -고 싶다", template: "V + 고 싶다", cefrLevel: "A1"),
            makeGrammarPattern(name: "hypothetical -다면", template: "V/A + 다면", cefrLevel: "B2"),
        ]

        let result = MediaMetadataService.analyze(
            transcript: "먹고 싶어요. 한국에 가고 싶어요.",
            vocabularyItems: [],
            grammarPatterns: patterns
        )

        // Should detect "desire -고 싶다" and "polite ending -아/어요"
        #expect(result.grammarPatternIds.count >= 1)
        #expect(result.grammarPatternIds.contains(patterns[1].id)) // -고 싶다
    }

    // MARK: - Auto-Tagging

    @Test("Derives tags from matched vocabulary domains")
    func derivesTags() {
        let vocab = [
            makeVocabItem(korean: "밥", english: "rice", domains: ["food"]),
            makeVocabItem(korean: "먹다", english: "to eat", domains: ["food"]),
            makeVocabItem(korean: "커피", english: "coffee", domains: ["cafe", "food"]),
        ]

        let result = MediaMetadataService.analyze(
            transcript: "밥 먹다 커피",
            vocabularyItems: vocab,
            grammarPatterns: []
        )

        // "food" appears in 3 items, should definitely be tagged
        #expect(result.autoTags.contains("food"))
    }

    @Test("No tags when no vocabulary matches")
    func noTagsWhenNoMatches() {
        let result = MediaMetadataService.analyze(
            transcript: "이것은 테스트입니다",
            vocabularyItems: [],
            grammarPatterns: []
        )

        #expect(result.autoTags.isEmpty)
    }

    // MARK: - Difficulty and CEFR

    @Test("Produces difficulty score and CEFR level from transcript")
    func producesDifficultyAndCEFR() {
        let result = MediaMetadataService.analyze(
            transcript: "안녕하세요. 오늘 날씨가 좋아요. 감사합니다.",
            vocabularyItems: [],
            grammarPatterns: []
        )

        #expect(result.difficultyScore >= 0.0 && result.difficultyScore <= 1.0)
        #expect(!result.cefrLevel.isEmpty)
    }

    // MARK: - Enrich

    @Test("Enrich applies analysis result to MediaContent")
    func enrichAppliesResult() {
        let content = MediaContent(
            title: "Test",
            contentType: "drama",
            tags: ["existing-tag"]
        )

        let result = MediaMetadataService.AnalysisResult(
            vocabularyIds: [UUID()],
            grammarPatternIds: [UUID()],
            autoTags: ["food", "cafe"],
            difficultyScore: 0.35,
            cefrLevel: "A2"
        )

        MediaMetadataService.enrich(content: content, with: result)

        #expect(content.vocabularyIds.count == 1)
        #expect(content.grammarPatternIds.count == 1)
        #expect(content.tags.contains("existing-tag"))
        #expect(content.tags.contains("food"))
        #expect(content.tags.contains("cafe"))
        #expect(content.difficultyScore == 0.35)
        #expect(content.cefrLevel == "A2")
        #expect(content.metadataStatus == "analyzed")
    }

    @Test("Enrich preserves manual difficulty when flag is set")
    func enrichPreservesManual() {
        let content = MediaContent(
            title: "Test",
            contentType: "drama",
            difficultyScore: 0.8,
            cefrLevel: "B2",
            metadataStatus: "manual"
        )

        let result = MediaMetadataService.AnalysisResult(
            vocabularyIds: [],
            grammarPatternIds: [],
            autoTags: [],
            difficultyScore: 0.2,
            cefrLevel: "A1"
        )

        MediaMetadataService.enrich(content: content, with: result, preserveManual: true)

        // Should keep original values since metadataStatus was "manual"
        #expect(content.difficultyScore == 0.8)
        #expect(content.cefrLevel == "B2")
    }
}
