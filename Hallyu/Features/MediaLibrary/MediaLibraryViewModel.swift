import Foundation
import Observation

@Observable
final class MediaLibraryViewModel {
    var allContent: [MediaContent] = []
    var filteredContent: [MediaContent] = []
    var filters = MediaFilterState()
    var isLoading: Bool = false
    var errorMessage: String?
    var coverageMap: [UUID: Double] = [:]

    private var knownWords: Set<String> = []

    init(knownWords: Set<String> = []) {
        self.knownWords = knownWords
    }

    // MARK: - Loading

    func loadContent(from content: [MediaContent]) {
        allContent = content
        applyFilters()
    }

    func setKnownWords(_ words: Set<String>) {
        knownWords = words
        recomputeCoverage()
        applyFilters()
    }

    // MARK: - Filtering

    func applyFilters() {
        var result = allContent.filter { filters.matches($0) }
        result = applySortOrder(result)
        filteredContent = result
    }

    func updateContentType(_ type: MediaContentType) {
        filters.contentType = type
        applyFilters()
    }

    func updateCEFRLevel(_ level: CEFRFilter) {
        filters.cefrLevel = level
        applyFilters()
    }

    func updateDuration(_ duration: DurationFilter) {
        filters.duration = duration
        applyFilters()
    }

    func updateSortOrder(_ order: MediaSortOrder) {
        filters.sortOrder = order
        applyFilters()
    }

    func updateSearchQuery(_ query: String) {
        filters.searchQuery = query
        applyFilters()
    }

    func clearFilters() {
        filters = MediaFilterState()
        applyFilters()
    }

    // MARK: - Coverage

    func coverage(for content: MediaContent) -> Double {
        if let cached = coverageMap[content.id] {
            return cached
        }
        let coverage = computeCoverage(for: content)
        coverageMap[content.id] = coverage
        return coverage
    }

    func coverageLevel(for content: MediaContent) -> CoverageLevel {
        CoverageLevel(coverage: coverage(for: content))
    }

    private func computeCoverage(for content: MediaContent) -> Double {
        guard !knownWords.isEmpty else { return 0.0 }
        return KoreanTextAnalyzer.estimateCoverage(
            text: content.transcriptKr,
            knownWords: knownWords
        )
    }

    private func recomputeCoverage() {
        coverageMap.removeAll()
        for content in allContent {
            coverageMap[content.id] = computeCoverage(for: content)
        }
    }

    // MARK: - Sorting

    private func applySortOrder(_ content: [MediaContent]) -> [MediaContent] {
        switch filters.sortOrder {
        case .recommended:
            return content.sorted { lhs, rhs in
                let lhsCoverage = coverage(for: lhs)
                let rhsCoverage = coverage(for: rhs)
                // Prefer content in the 70-95% coverage sweet spot
                let lhsScore = recommendationScore(coverage: lhsCoverage, difficulty: lhs.difficultyScore)
                let rhsScore = recommendationScore(coverage: rhsCoverage, difficulty: rhs.difficultyScore)
                return lhsScore > rhsScore
            }
        case .newest:
            return content.sorted { $0.createdAt > $1.createdAt }
        case .easiest:
            return content.sorted { $0.difficultyScore < $1.difficultyScore }
        case .hardest:
            return content.sorted { $0.difficultyScore > $1.difficultyScore }
        }
    }

    private func recommendationScore(coverage: Double, difficulty: Double) -> Double {
        // Ideal coverage is 85-95% (i+1 comprehensible input)
        let coverageScore: Double
        if coverage >= 0.85 && coverage <= 0.95 {
            coverageScore = 1.0
        } else if coverage >= 0.70 {
            coverageScore = 0.7
        } else {
            coverageScore = 0.3
        }
        // Slight preference for moderate difficulty
        let difficultyScore = 1.0 - abs(difficulty - 0.5)
        return coverageScore * 0.7 + difficultyScore * 0.3
    }

    // MARK: - Helpers

    func formattedDuration(for content: MediaContent) -> String {
        let minutes = content.durationSeconds / 60
        let seconds = content.durationSeconds % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        return "0:\(String(format: "%02d", seconds))"
    }

    var contentTypeCounts: [MediaContentType: Int] {
        var counts: [MediaContentType: Int] = [:]
        for type in MediaContentType.allCases where type != .all {
            counts[type] = allContent.filter { $0.contentType == type.rawValue }.count
        }
        return counts
    }
}
