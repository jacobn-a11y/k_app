import Foundation
import SwiftData

@Model
final class MediaContent: Codable {
    @Attribute(.unique) var id: UUID
    var title: String
    var contentType: String
    var source: String
    var difficultyScore: Double
    var cefrLevel: String
    var durationSeconds: Int
    var transcriptKr: String
    var transcriptSegmentsData: Data?
    var vocabularyIds: [UUID]
    var grammarPatternIds: [UUID]
    var mediaUrl: String
    var thumbnailUrl: String
    var culturalNotes: String
    var tags: [String]
    var metadataStatus: String
    var createdAt: Date

    struct TranscriptSegment: Codable, Equatable {
        let startMs: Int
        let endMs: Int
        let textKr: String
        let textEn: String
    }

    var transcriptSegments: [TranscriptSegment] {
        get {
            guard let data = transcriptSegmentsData else { return [] }
            return (try? JSONDecoder().decode([TranscriptSegment].self, from: data)) ?? []
        }
        set {
            transcriptSegmentsData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        id: UUID = UUID(),
        title: String,
        contentType: String,
        source: String = "",
        difficultyScore: Double = 0.5,
        cefrLevel: String = "A1",
        durationSeconds: Int = 0,
        transcriptKr: String = "",
        transcriptSegments: [TranscriptSegment] = [],
        vocabularyIds: [UUID] = [],
        grammarPatternIds: [UUID] = [],
        mediaUrl: String = "",
        thumbnailUrl: String = "",
        culturalNotes: String = "",
        tags: [String] = [],
        metadataStatus: String = "pending",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.contentType = contentType
        self.source = source
        self.difficultyScore = difficultyScore
        self.cefrLevel = cefrLevel
        self.durationSeconds = durationSeconds
        self.transcriptKr = transcriptKr
        self.transcriptSegmentsData = try? JSONEncoder().encode(transcriptSegments)
        self.vocabularyIds = vocabularyIds
        self.grammarPatternIds = grammarPatternIds
        self.mediaUrl = mediaUrl
        self.thumbnailUrl = thumbnailUrl
        self.culturalNotes = culturalNotes
        self.tags = tags
        self.metadataStatus = metadataStatus
        self.createdAt = createdAt
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, title, source, tags
        case contentType = "content_type"
        case difficultyScore = "difficulty_score"
        case cefrLevel = "cefr_level"
        case durationSeconds = "duration_seconds"
        case transcriptKr = "transcript_kr"
        case transcriptSegmentsData = "transcript_segments"
        case vocabularyIds = "vocabulary_ids"
        case grammarPatternIds = "grammar_pattern_ids"
        case mediaUrl = "media_url"
        case thumbnailUrl = "thumbnail_url"
        case culturalNotes = "cultural_notes"
        case metadataStatus = "metadata_status"
        case createdAt = "created_at"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        contentType = try container.decode(String.self, forKey: .contentType)
        source = try container.decodeIfPresent(String.self, forKey: .source) ?? ""
        difficultyScore = try container.decodeIfPresent(Double.self, forKey: .difficultyScore) ?? 0.5
        cefrLevel = try container.decodeIfPresent(String.self, forKey: .cefrLevel) ?? "A1"
        durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds) ?? 0
        transcriptKr = try container.decodeIfPresent(String.self, forKey: .transcriptKr) ?? ""
        transcriptSegmentsData = try container.decodeIfPresent(Data.self, forKey: .transcriptSegmentsData)
        vocabularyIds = try container.decodeIfPresent([UUID].self, forKey: .vocabularyIds) ?? []
        grammarPatternIds = try container.decodeIfPresent([UUID].self, forKey: .grammarPatternIds) ?? []
        mediaUrl = try container.decodeIfPresent(String.self, forKey: .mediaUrl) ?? ""
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl) ?? ""
        culturalNotes = try container.decodeIfPresent(String.self, forKey: .culturalNotes) ?? ""
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        metadataStatus = try container.decodeIfPresent(String.self, forKey: .metadataStatus) ?? "pending"
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(source, forKey: .source)
        try container.encode(difficultyScore, forKey: .difficultyScore)
        try container.encode(cefrLevel, forKey: .cefrLevel)
        try container.encode(durationSeconds, forKey: .durationSeconds)
        try container.encode(transcriptKr, forKey: .transcriptKr)
        try container.encode(transcriptSegmentsData, forKey: .transcriptSegmentsData)
        try container.encode(vocabularyIds, forKey: .vocabularyIds)
        try container.encode(grammarPatternIds, forKey: .grammarPatternIds)
        try container.encode(mediaUrl, forKey: .mediaUrl)
        try container.encode(thumbnailUrl, forKey: .thumbnailUrl)
        try container.encode(culturalNotes, forKey: .culturalNotes)
        try container.encode(tags, forKey: .tags)
        try container.encode(metadataStatus, forKey: .metadataStatus)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
