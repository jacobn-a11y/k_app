import Testing
import Foundation
@testable import HallyuCore

@Suite("MediaLibraryViewModel Tests")
struct MediaLibraryViewModelTests {

    // MARK: - Helpers

    private func sampleContent() -> [MediaContent] {
        [
            MediaContent(title: "Easy Drama", contentType: "drama", source: "Show A", difficultyScore: 0.2, cefrLevel: "A1", durationSeconds: 120, transcriptKr: "안녕하세요 오늘 좋아요", tags: ["drama", "easy"]),
            MediaContent(title: "Medium News", contentType: "news", source: "KBS", difficultyScore: 0.5, cefrLevel: "B1", durationSeconds: 60, transcriptKr: "경제가 발전하고 있습니다", tags: ["news", "economy"]),
            MediaContent(title: "Hard Webtoon", contentType: "webtoon", source: "Naver", difficultyScore: 0.8, cefrLevel: "B2", durationSeconds: 0, transcriptKr: "세계적으로 큰 영향을 미치고 있습니다", tags: ["webtoon", "advanced"]),
            MediaContent(title: "Short Video", contentType: "short_video", source: "YouTube", difficultyScore: 0.3, cefrLevel: "A2", durationSeconds: 90, transcriptKr: "오늘은 한국 음식을 먹어볼 거예요", tags: ["food", "vlog"]),
            MediaContent(title: "K-Pop Song", contentType: "music", source: "BTS", difficultyScore: 0.35, cefrLevel: "A2", durationSeconds: 200, transcriptKr: "사랑을 했다 우리가 만난 건", tags: ["music", "kpop"]),
        ]
    }

    // MARK: - Loading

    @Test("Load content populates allContent and filteredContent")
    func loadContent() {
        let vm = MediaLibraryViewModel()
        let content = sampleContent()
        vm.loadContent(from: content)
        #expect(vm.allContent.count == 5)
        #expect(vm.filteredContent.count == 5)
    }

    // MARK: - Content Type Filtering

    @Test("Filter by content type shows only matching content")
    func filterByContentType() {
        let vm = MediaLibraryViewModel()
        vm.loadContent(from: sampleContent())
        vm.updateContentType(.drama)
        #expect(vm.filteredContent.count == 1)
        #expect(vm.filteredContent.first?.contentType == "drama")
    }

    @Test("Filter by all content type shows everything")
    func filterByAllContentType() {
        let vm = MediaLibraryViewModel()
        vm.loadContent(from: sampleContent())
        vm.updateContentType(.drama)
        vm.updateContentType(.all)
        #expect(vm.filteredContent.count == 5)
    }

    // MARK: - CEFR Level Filtering

    @Test("Filter by CEFR level shows only matching content")
    func filterByCEFRLevel() {
        let vm = MediaLibraryViewModel()
        vm.loadContent(from: sampleContent())
        vm.updateCEFRLevel(.a1)
        #expect(vm.filteredContent.count == 1)
        #expect(vm.filteredContent.first?.cefrLevel == "A1")
    }

    // MARK: - Duration Filtering

    @Test("Filter by short duration shows clips under 2 minutes")
    func filterByShortDuration() {
        let vm = MediaLibraryViewModel()
        vm.loadContent(from: sampleContent())
        vm.updateDuration(.short)
        // 60s (news) and 90s (short_video) and 0s (webtoon) are < 120
        let durations = vm.filteredContent.map { $0.durationSeconds }
        #expect(durations.allSatisfy { $0 < 120 })
    }

    @Test("Filter by medium duration shows clips 2-5 minutes")
    func filterByMediumDuration() {
        let vm = MediaLibraryViewModel()
        vm.loadContent(from: sampleContent())
        vm.updateDuration(.medium)
        let durations = vm.filteredContent.map { $0.durationSeconds }
        #expect(durations.allSatisfy { $0 >= 120 && $0 <= 300 })
    }

    // MARK: - Search

    @Test("Search by title filters content")
    func searchByTitle() {
        let vm = MediaLibraryViewModel()
        vm.loadContent(from: sampleContent())
        vm.updateSearchQuery("Drama")
        #expect(vm.filteredContent.count == 1)
        #expect(vm.filteredContent.first?.title == "Easy Drama")
    }

    @Test("Search by source filters content")
    func searchBySource() {
        let vm = MediaLibraryViewModel()
        vm.loadContent(from: sampleContent())
        vm.updateSearchQuery("KBS")
        #expect(vm.filteredContent.count == 1)
        #expect(vm.filteredContent.first?.source == "KBS")
    }

    @Test("Search by tag filters content")
    func searchByTag() {
        let vm = MediaLibraryViewModel()
        vm.loadContent(from: sampleContent())
        vm.updateSearchQuery("kpop")
        #expect(vm.filteredContent.count == 1)
        #expect(vm.filteredContent.first?.contentType == "music")
    }

    @Test("Empty search shows all content")
    func emptySearch() {
        let vm = MediaLibraryViewModel()
        vm.loadContent(from: sampleContent())
        vm.updateSearchQuery("Drama")
        vm.updateSearchQuery("")
        #expect(vm.filteredContent.count == 5)
    }

    // MARK: - Sorting

    @Test("Sort by easiest shows lowest difficulty first")
    func sortByEasiest() {
        let vm = MediaLibraryViewModel()
        vm.loadContent(from: sampleContent())
        vm.updateSortOrder(.easiest)
        let scores = vm.filteredContent.map { $0.difficultyScore }
        #expect(scores == scores.sorted())
    }

    @Test("Sort by hardest shows highest difficulty first")
    func sortByHardest() {
        let vm = MediaLibraryViewModel()
        vm.loadContent(from: sampleContent())
        vm.updateSortOrder(.hardest)
        let scores = vm.filteredContent.map { $0.difficultyScore }
        #expect(scores == scores.sorted(by: >))
    }

    @Test("Sort by newest shows most recent first")
    func sortByNewest() {
        let vm = MediaLibraryViewModel()
        vm.loadContent(from: sampleContent())
        vm.updateSortOrder(.newest)
        let dates = vm.filteredContent.map { $0.createdAt }
        #expect(dates == dates.sorted(by: >))
    }

    // MARK: - Coverage

    @Test("Coverage computed with known words")
    func coverageComputation() {
        let vm = MediaLibraryViewModel(knownWords: ["안녕하세요", "오늘"])
        let content = MediaContent(title: "Test", contentType: "drama", transcriptKr: "안녕하세요 오늘 날씨가 좋아요")
        vm.loadContent(from: [content])
        let coverage = vm.coverage(for: content)
        // "안녕하세요" and "오늘" are known out of 4 tokens
        #expect(coverage == 0.5)
    }

    @Test("Coverage level returns correct tier")
    func coverageLevelTiers() {
        let vm = MediaLibraryViewModel(knownWords: ["안녕하세요", "오늘", "날씨가", "좋아요"])
        let content = MediaContent(title: "Test", contentType: "drama", transcriptKr: "안녕하세요 오늘 날씨가 좋아요")
        vm.loadContent(from: [content])
        let level = vm.coverageLevel(for: content)
        #expect(level == .high)
    }

    @Test("Coverage is zero with no known words")
    func coverageZero() {
        let vm = MediaLibraryViewModel(knownWords: [])
        let content = MediaContent(title: "Test", contentType: "drama", transcriptKr: "안녕하세요 오늘 날씨가 좋아요")
        vm.loadContent(from: [content])
        #expect(vm.coverage(for: content) == 0.0)
    }

    // MARK: - Clear Filters

    @Test("Clear filters resets all filter state")
    func clearFilters() {
        let vm = MediaLibraryViewModel()
        vm.loadContent(from: sampleContent())
        vm.updateContentType(.drama)
        vm.updateCEFRLevel(.a1)
        vm.updateSearchQuery("test")
        vm.clearFilters()
        #expect(vm.filters.contentType == .all)
        #expect(vm.filters.cefrLevel == .all)
        #expect(vm.filters.searchQuery == "")
        #expect(vm.filteredContent.count == 5)
    }

    // MARK: - Content Type Counts

    @Test("Content type counts reflect all content")
    func contentTypeCounts() {
        let vm = MediaLibraryViewModel()
        vm.loadContent(from: sampleContent())
        let counts = vm.contentTypeCounts
        #expect(counts[.drama] == 1)
        #expect(counts[.news] == 1)
        #expect(counts[.webtoon] == 1)
        #expect(counts[.shortVideo] == 1)
        #expect(counts[.music] == 1)
    }

    // MARK: - Formatted Duration

    @Test("Formatted duration shows correct format")
    func formattedDuration() {
        let vm = MediaLibraryViewModel()
        let content = MediaContent(title: "Test", contentType: "drama", durationSeconds: 150)
        #expect(vm.formattedDuration(for: content) == "2:30")
    }

    @Test("Formatted duration for zero seconds")
    func formattedDurationZero() {
        let vm = MediaLibraryViewModel()
        let content = MediaContent(title: "Test", contentType: "drama", durationSeconds: 0)
        #expect(vm.formattedDuration(for: content) == "0:00")
    }

    // MARK: - Combined Filters

    @Test("Multiple filters combine correctly")
    func combinedFilters() {
        let vm = MediaLibraryViewModel()
        vm.loadContent(from: sampleContent())
        vm.updateContentType(.drama)
        vm.updateCEFRLevel(.a1)
        #expect(vm.filteredContent.count == 1)
        #expect(vm.filteredContent.first?.title == "Easy Drama")
    }

    @Test("No results when filters are too restrictive")
    func noResults() {
        let vm = MediaLibraryViewModel()
        vm.loadContent(from: sampleContent())
        vm.updateContentType(.drama)
        vm.updateCEFRLevel(.b2)
        #expect(vm.filteredContent.isEmpty)
    }
}
