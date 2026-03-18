import Foundation

struct TextAnalysis {
    let tokens: [String]
    let uniqueTokens: Set<String>
    let koreanCharacterCount: Int
    let totalCharacterCount: Int
    let difficultyScore: Double
    let estimatedCEFRLevel: String
}

enum KoreanTextAnalyzer {
    /// Analyze a Korean text and return vocabulary tokens, difficulty, etc.
    static func analyzeText(_ korean: String) -> TextAnalysis {
        let tokens = tokenize(korean)
        let uniqueTokens = Set(tokens)
        let koreanCount = HangulUtilities.koreanCharacterCount(korean)
        let difficulty = estimateDifficulty(tokens: tokens, uniqueTokens: uniqueTokens)
        let level = estimateCEFRLevel(difficultyScore: difficulty)

        return TextAnalysis(
            tokens: tokens,
            uniqueTokens: uniqueTokens,
            koreanCharacterCount: koreanCount,
            totalCharacterCount: korean.count,
            difficultyScore: difficulty,
            estimatedCEFRLevel: level
        )
    }

    /// Simple whitespace + punctuation tokenizer for Korean text
    static func tokenize(_ text: String) -> [String] {
        let punctuation = CharacterSet.punctuationCharacters
            .union(.whitespaces)
            .union(.newlines)

        return text.unicodeScalars
            .split { punctuation.contains($0) }
            .map { String($0) }
            .filter { !$0.isEmpty && HangulUtilities.containsKorean($0) }
    }

    /// Estimate vocabulary coverage for a learner given their known words
    static func estimateCoverage(text: String, knownWords: Set<String>) -> Double {
        let tokens = tokenize(text)
        guard !tokens.isEmpty else { return 1.0 }

        let knownCount = tokens.filter { knownWords.contains($0) }.count
        return Double(knownCount) / Double(tokens.count)
    }

    /// Estimate difficulty score (0.0 = easiest, 1.0 = hardest)
    static func estimateDifficulty(tokens: [String], uniqueTokens: Set<String>) -> Double {
        guard !tokens.isEmpty else { return 0.0 }

        // Factor 1: Lexical diversity (type-token ratio)
        let ttr = Double(uniqueTokens.count) / Double(tokens.count)

        // Factor 2: Average token length (longer words tend to be more complex)
        let avgLength = Double(tokens.reduce(0) { $0 + $1.count }) / Double(tokens.count)
        let lengthFactor = min(avgLength / 6.0, 1.0) // normalize to 0-1

        // Factor 3: Text length (longer texts are generally harder to process)
        let lengthDifficulty = min(Double(tokens.count) / 100.0, 1.0)

        // Weighted combination
        let difficulty = ttr * 0.4 + lengthFactor * 0.3 + lengthDifficulty * 0.3
        return min(max(difficulty, 0.0), 1.0)
    }

    /// Map difficulty score to estimated CEFR level
    static func estimateCEFRLevel(difficultyScore: Double) -> String {
        switch difficultyScore {
        case 0.0..<0.2: return "pre-A1"
        case 0.2..<0.35: return "A1"
        case 0.35..<0.5: return "A2"
        case 0.5..<0.7: return "B1"
        default: return "B2"
        }
    }
}
