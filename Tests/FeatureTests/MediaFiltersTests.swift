import Testing
import Foundation
@testable import HallyuCore

@Suite("MediaFilters Tests")
struct MediaFiltersTests {

    // MARK: - DurationFilter

    @Test("Duration filter matches correctly")
    func durationFilterMatching() {
        #expect(DurationFilter.short.matches(durationSeconds: 60) == true)
        #expect(DurationFilter.short.matches(durationSeconds: 120) == false)
        #expect(DurationFilter.medium.matches(durationSeconds: 180) == true)
        #expect(DurationFilter.medium.matches(durationSeconds: 60) == false)
        #expect(DurationFilter.long.matches(durationSeconds: 400) == true)
        #expect(DurationFilter.long.matches(durationSeconds: 200) == false)
        #expect(DurationFilter.all.matches(durationSeconds: 9999) == true)
    }

    // MARK: - MediaFilterState

    @Test("Filter state matches content by type")
    func filterStateContentType() {
        var state = MediaFilterState()
        state.contentType = .drama
        let drama = MediaContent(title: "Drama", contentType: "drama")
        let news = MediaContent(title: "News", contentType: "news")
        #expect(state.matches(drama) == true)
        #expect(state.matches(news) == false)
    }

    @Test("Filter state matches content by CEFR level")
    func filterStateCEFR() {
        var state = MediaFilterState()
        state.cefrLevel = .a1
        let a1 = MediaContent(title: "A1", contentType: "drama", cefrLevel: "A1")
        let b2 = MediaContent(title: "B2", contentType: "drama", cefrLevel: "B2")
        #expect(state.matches(a1) == true)
        #expect(state.matches(b2) == false)
    }

    @Test("Filter state matches content by search query")
    func filterStateSearch() {
        var state = MediaFilterState()
        state.searchQuery = "drama"
        let match = MediaContent(title: "My Drama", contentType: "drama")
        let noMatch = MediaContent(title: "News Report", contentType: "news")
        #expect(state.matches(match) == true)
        #expect(state.matches(noMatch) == false)
    }

    @Test("Filter state search matches tags")
    func filterStateSearchTags() {
        var state = MediaFilterState()
        state.searchQuery = "romance"
        let content = MediaContent(title: "Drama", contentType: "drama", tags: ["romance", "comedy"])
        #expect(state.matches(content) == true)
    }

    @Test("isFiltered detects active filters")
    func isFiltered() {
        var state = MediaFilterState()
        #expect(state.isFiltered == false)
        state.contentType = .drama
        #expect(state.isFiltered == true)
    }

    // MARK: - CoverageLevel

    @Test("Coverage level tiers are correct")
    func coverageLevelTiers() {
        #expect(CoverageLevel(coverage: 0.9) == .high)
        #expect(CoverageLevel(coverage: 0.85) == .high)
        #expect(CoverageLevel(coverage: 0.75) == .medium)
        #expect(CoverageLevel(coverage: 0.70) == .medium)
        #expect(CoverageLevel(coverage: 0.5) == .low)
    }

    // MARK: - MediaContentType

    @Test("Media content types have correct raw values")
    func contentTypeRawValues() {
        #expect(MediaContentType.drama.rawValue == "drama")
        #expect(MediaContentType.shortVideo.rawValue == "short_video")
        #expect(MediaContentType.all.rawValue == "all")
    }

    // MARK: - MediaContentSeeder

    @Test("Seeder generates correct number of placeholder content")
    func seederContentCount() {
        let content = MediaContentSeeder.allPlaceholderContent()
        // 50 drama + 30 webtoon + 20 news + 10 short video + 10 music = 120
        #expect(content.count >= 100) // at least 100 pieces
    }

    @Test("Seeder generates all content types")
    func seederContentTypes() {
        let content = MediaContentSeeder.allPlaceholderContent()
        let types = Set(content.map { $0.contentType })
        #expect(types.contains("drama"))
        #expect(types.contains("webtoon"))
        #expect(types.contains("news"))
        #expect(types.contains("short_video"))
        #expect(types.contains("music"))
    }

    @Test("Seeder content has valid CEFR levels")
    func seederCEFRLevels() {
        let content = MediaContentSeeder.allPlaceholderContent()
        let validLevels = Set(["pre-A1", "A1", "A2", "B1", "B2"])
        for item in content {
            #expect(validLevels.contains(item.cefrLevel), "Invalid CEFR level: \(item.cefrLevel) for \(item.title)")
        }
    }

    @Test("Seeder content has non-empty titles")
    func seederTitles() {
        let content = MediaContentSeeder.allPlaceholderContent()
        for item in content {
            #expect(!item.title.isEmpty, "Empty title found")
        }
    }
}
