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

    // MARK: - Phase 3: Frequency Analysis Tests

    @Test("Frequency rank lookup returns correct rank for known words")
    func frequencyRankLookup() {
        #expect(KoreanTextAnalyzer.frequencyRank(for: "나") == 1)
        #expect(KoreanTextAnalyzer.frequencyRank(for: "사람") == 17)
        #expect(KoreanTextAnalyzer.frequencyRank(for: "안녕하세요") == 401)
    }

    @Test("Frequency rank returns nil for unknown words")
    func frequencyRankUnknown() {
        #expect(KoreanTextAnalyzer.frequencyRank(for: "아스트로노트") == nil)
    }

    @Test("Frequency profile categorizes tokens correctly")
    func frequencyProfileCategories() {
        let tokens = ["나", "사람", "문화", "아스트로노트"]
        let profile = KoreanTextAnalyzer.computeFrequencyProfile(tokens: tokens)
        #expect(profile.totalTokens == 4)
        #expect(profile.highFrequencyRatio == 0.5)  // 나(1), 사람(17) are rank <=100
        #expect(profile.knownByFrequency == 3)  // 나, 사람, 문화 are in frequency list
    }

    @Test("Frequency profile handles empty tokens")
    func frequencyProfileEmpty() {
        let profile = KoreanTextAnalyzer.computeFrequencyProfile(tokens: [])
        #expect(profile.totalTokens == 0)
        #expect(profile.highFrequencyRatio == 0)
    }

    // MARK: - Phase 3: Grammar Detection Tests

    @Test("Detects polite ending grammar pattern")
    func detectPoliteEnding() {
        let patterns = KoreanTextAnalyzer.detectGrammarPatterns(in: "오늘 날씨가 좋아요")
        #expect(patterns.contains("polite ending -아/어요"))
    }

    @Test("Detects formal ending grammar pattern")
    func detectFormalEnding() {
        let patterns = KoreanTextAnalyzer.detectGrammarPatterns(in: "감사합니다")
        #expect(patterns.contains("formal ending -습니다/ㅂ니다"))
    }

    @Test("Detects multiple grammar patterns")
    func detectMultiplePatterns() {
        let patterns = KoreanTextAnalyzer.detectGrammarPatterns(in: "날씨가 좋아서 기분이 좋아요")
        #expect(patterns.contains("cause/sequence -아/어서"))
        #expect(patterns.contains("polite ending -아/어요"))
    }

    @Test("Returns empty array when no patterns detected")
    func detectNoPatterns() {
        let patterns = KoreanTextAnalyzer.detectGrammarPatterns(in: "나 사람 물")
        #expect(patterns.isEmpty)
    }

    // MARK: - Phase 3: Full Analysis Tests

    @Test("Full analysis includes frequency profile")
    func fullAnalysisFrequency() {
        let analysis = KoreanTextAnalyzer.analyzeText("나는 오늘 학교에 갑니다")
        #expect(analysis.frequencyProfile.totalTokens > 0)
    }

    @Test("Full analysis includes detected grammar patterns")
    func fullAnalysisGrammar() {
        let analysis = KoreanTextAnalyzer.analyzeText("오늘 날씨가 좋아서 기분이 좋아요")
        #expect(!analysis.detectedGrammarPatterns.isEmpty)
        #expect(analysis.detectedGrammarPatterns.contains("polite ending -아/어요"))
    }
}
