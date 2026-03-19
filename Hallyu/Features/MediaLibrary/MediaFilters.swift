import Foundation

enum MediaContentType: String, CaseIterable, Identifiable {
    case all = "all"
    case drama = "drama"
    case news = "news"
    case webtoon = "webtoon"
    case shortVideo = "short_video"
    case music = "music"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "All"
        case .drama: return "K-Drama"
        case .news: return "News"
        case .webtoon: return "Webtoon"
        case .shortVideo: return "Short Video"
        case .music: return "Music"
        }
    }

    var iconName: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .drama: return "tv"
        case .news: return "newspaper"
        case .webtoon: return "book.pages"
        case .shortVideo: return "play.rectangle"
        case .music: return "music.note"
        }
    }
}

enum CEFRFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case preA1 = "pre-A1"
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "All Levels"
        default: return rawValue
        }
    }
}

enum DurationFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case short = "short"
    case medium = "medium"
    case long = "long"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "Any Duration"
        case .short: return "< 2 min"
        case .medium: return "2-5 min"
        case .long: return "> 5 min"
        }
    }

    func matches(durationSeconds: Int) -> Bool {
        switch self {
        case .all: return true
        case .short: return durationSeconds < 120
        case .medium: return durationSeconds >= 120 && durationSeconds <= 300
        case .long: return durationSeconds > 300
        }
    }
}

enum MediaSortOrder: String, CaseIterable, Identifiable {
    case recommended = "recommended"
    case newest = "newest"
    case easiest = "easiest"
    case hardest = "hardest"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .recommended: return "Recommended"
        case .newest: return "Newest"
        case .easiest: return "Easiest First"
        case .hardest: return "Hardest First"
        }
    }
}

struct MediaFilterState {
    var contentType: MediaContentType = .all
    var cefrLevel: CEFRFilter = .all
    var duration: DurationFilter = .all
    var sortOrder: MediaSortOrder = .recommended
    var searchQuery: String = ""

    var isFiltered: Bool {
        contentType != .all || cefrLevel != .all || duration != .all || !searchQuery.isEmpty
    }

    func matches(_ content: MediaContent) -> Bool {
        if contentType != .all && content.contentType != contentType.rawValue {
            return false
        }
        if cefrLevel != .all && content.cefrLevel != cefrLevel.rawValue {
            return false
        }
        if !duration.matches(durationSeconds: content.durationSeconds) {
            return false
        }
        if !searchQuery.isEmpty {
            // Cap search query length to prevent performance issues
            let safeQuery = String(searchQuery.prefix(100))
            let query = safeQuery.lowercased()
            let matchesTitle = content.title.lowercased().contains(query)
            let matchesSource = content.source.lowercased().contains(query)
            let matchesTags = content.tags.contains { $0.lowercased().contains(query) }
            if !matchesTitle && !matchesSource && !matchesTags {
                return false
            }
        }
        return true
    }
}

enum CoverageLevel: Equatable {
    case high    // 85%+ vocabulary coverage
    case medium  // 70-85%
    case low     // < 70%

    init(coverage: Double) {
        if coverage >= 0.85 {
            self = .high
        } else if coverage >= 0.70 {
            self = .medium
        } else {
            self = .low
        }
    }

    var label: String {
        switch self {
        case .high: return "Easy"
        case .medium: return "Moderate"
        case .low: return "Challenging"
        }
    }

    var colorName: String {
        switch self {
        case .high: return "green"
        case .medium: return "yellow"
        case .low: return "red"
        }
    }
}
