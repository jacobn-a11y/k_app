import Foundation

/// Analyzes media transcripts and cross-references against known vocabulary and grammar
/// to auto-populate metadata fields on MediaContent.
enum MediaMetadataService {

    struct AnalysisResult {
        let vocabularyIds: [UUID]
        let grammarPatternIds: [UUID]
        let autoTags: [String]
        let difficultyScore: Double
        let cefrLevel: String
    }

    /// Analyze a transcript and cross-reference against known vocabulary/grammar records.
    /// Returns populated metadata that can be applied to a MediaContent record.
    static func analyze(
        transcript: String,
        vocabularyItems: [VocabularyItem],
        grammarPatterns: [GrammarPattern]
    ) -> AnalysisResult {
        guard !transcript.isEmpty else {
            return AnalysisResult(
                vocabularyIds: [],
                grammarPatternIds: [],
                autoTags: [],
                difficultyScore: 0.5,
                cefrLevel: "A2"
            )
        }

        let textAnalysis = KoreanTextAnalyzer.analyzeText(transcript)

        // Match tokens against VocabularyItem records by korean field
        let tokens = textAnalysis.uniqueTokens
        let matchedVocab = vocabularyItems.filter { item in
            tokens.contains(item.korean)
        }
        let vocabularyIds = matchedVocab.map(\.id)

        // Match detected grammar patterns against GrammarPattern records by patternName
        let detectedPatternNames = Set(textAnalysis.detectedGrammarPatterns)
        let matchedGrammar = grammarPatterns.filter { pattern in
            detectedPatternNames.contains(pattern.patternName)
        }
        let grammarPatternIds = matchedGrammar.map(\.id)

        // Auto-tag from matched vocabulary mediaDomains
        let autoTags = deriveTagsFromVocabulary(matchedVocab)

        return AnalysisResult(
            vocabularyIds: vocabularyIds,
            grammarPatternIds: grammarPatternIds,
            autoTags: autoTags,
            difficultyScore: textAnalysis.difficultyScore,
            cefrLevel: textAnalysis.estimatedCEFRLevel
        )
    }

    /// Apply analysis results to a MediaContent, merging with any existing metadata.
    /// When `preserveManual` is true, existing difficulty/CEFR values are kept if the content
    /// was manually annotated.
    static func enrich(
        content: MediaContent,
        with result: AnalysisResult,
        preserveManual: Bool = false
    ) {
        content.vocabularyIds = result.vocabularyIds
        content.grammarPatternIds = result.grammarPatternIds

        // Merge auto-tags with existing tags (deduplicated)
        let mergedTags = Array(Set(content.tags + result.autoTags)).sorted()
        content.tags = mergedTags

        let isManual = content.metadataStatus == "manual"
        if !preserveManual || !isManual {
            content.difficultyScore = result.difficultyScore
            content.cefrLevel = result.cefrLevel
        }

        content.metadataStatus = "analyzed"
    }

    // MARK: - Private

    /// Derive topic tags from matched vocabulary items' mediaDomains.
    /// Picks domains that appear across 2+ matched words (to avoid noise from single matches).
    private static func deriveTagsFromVocabulary(_ vocabItems: [VocabularyItem]) -> [String] {
        var domainCounts: [String: Int] = [:]
        for item in vocabItems {
            for domain in item.mediaDomains {
                domainCounts[domain, default: 0] += 1
            }
        }

        // Include domains that appear in 2+ matched words, or all if fewer than 2 exist
        let threshold = domainCounts.values.max().map { $0 >= 2 ? 2 : 1 } ?? 1
        return domainCounts
            .filter { $0.value >= threshold }
            .map(\.key)
            .sorted()
    }
}
