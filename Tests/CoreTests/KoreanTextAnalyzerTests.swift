import Testing
import Foundation
@testable import HallyuCore

@Suite("KoreanTextAnalyzer Tests")
struct KoreanTextAnalyzerTests {

    @Test("Tokenize splits Korean text by whitespace and punctuation")
    func tokenizeBasic() {
        let tokens = KoreanTextAnalyzer.tokenize("안녕하세요! 오늘 날씨가 좋아요.")
        #expect(tokens.count == 4)
        #expect(tokens.contains("안녕하세요"))
        #expect(tokens.contains("좋아요"))
    }

    @Test("Tokenize filters out non-Korean tokens")
    func tokenizeFiltersEnglish() {
        let tokens = KoreanTextAnalyzer.tokenize("Hello 안녕 World 세계")
        #expect(tokens.count == 2)
        #expect(tokens == ["안녕", "세계"])
    }

    @Test("Tokenize handles empty string")
    func tokenizeEmpty() {
        let tokens = KoreanTextAnalyzer.tokenize("")
        #expect(tokens.isEmpty)
    }

    @Test("Analyze text returns correct structure")
    func analyzeText() {
        let analysis = KoreanTextAnalyzer.analyzeText("안녕하세요 오늘 날씨가 좋아요")
        #expect(analysis.tokens.count == 4)
        #expect(analysis.uniqueTokens.count == 4)
        #expect(analysis.koreanCharacterCount > 0)
        #expect(analysis.difficultyScore >= 0.0)
        #expect(analysis.difficultyScore <= 1.0)
    }

    @Test("Estimate coverage with known words")
    func estimateCoverage() {
        let text = "안녕 안녕 세계 세계"
        let known: Set<String> = ["안녕"]
        let coverage = KoreanTextAnalyzer.estimateCoverage(text: text, knownWords: known)
        #expect(coverage == 0.5)
    }

    @Test("Estimate coverage with all known words")
    func estimateFullCoverage() {
        let text = "안녕 세계"
        let known: Set<String> = ["안녕", "세계"]
        let coverage = KoreanTextAnalyzer.estimateCoverage(text: text, knownWords: known)
        #expect(coverage == 1.0)
    }

    @Test("Estimate coverage with no known words")
    func estimateZeroCoverage() {
        let text = "안녕 세계"
        let known: Set<String> = []
        let coverage = KoreanTextAnalyzer.estimateCoverage(text: text, knownWords: known)
        #expect(coverage == 0.0)
    }

    @Test("Difficulty score is between 0 and 1")
    func difficultyRange() {
        let easy = KoreanTextAnalyzer.estimateDifficulty(tokens: ["안녕", "안녕", "안녕"], uniqueTokens: Set(["안녕"]))
        let hard = KoreanTextAnalyzer.estimateDifficulty(
            tokens: ["안녕하세요", "오늘은", "날씨가", "정말로", "좋습니다"],
            uniqueTokens: Set(["안녕하세요", "오늘은", "날씨가", "정말로", "좋습니다"])
        )
        #expect(easy >= 0.0 && easy <= 1.0)
        #expect(hard >= 0.0 && hard <= 1.0)
        #expect(hard > easy)
    }

    @Test("CEFR level estimation from difficulty score")
    func cefrEstimation() {
        #expect(KoreanTextAnalyzer.estimateCEFRLevel(difficultyScore: 0.1) == "pre-A1")
        #expect(KoreanTextAnalyzer.estimateCEFRLevel(difficultyScore: 0.25) == "A1")
        #expect(KoreanTextAnalyzer.estimateCEFRLevel(difficultyScore: 0.4) == "A2")
        #expect(KoreanTextAnalyzer.estimateCEFRLevel(difficultyScore: 0.6) == "B1")
        #expect(KoreanTextAnalyzer.estimateCEFRLevel(difficultyScore: 0.8) == "B2")
    }
}
