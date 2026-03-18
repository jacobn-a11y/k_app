import Foundation
import SwiftData

@Model
final class VocabularyItem: Codable {
    @Attribute(.unique) var id: UUID
    var korean: String
    var romanization: String
    var english: String
    var partOfSpeech: String
    var cefrLevel: String
    var frequencyRank: Int
    var mediaDomains: [String]
    var exampleSentenceKr: String
    var exampleSentenceEn: String
    var audioUrl: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        korean: String,
        romanization: String = "",
        english: String,
        partOfSpeech: String = "",
        cefrLevel: String = "A1",
        frequencyRank: Int = 0,
        mediaDomains: [String] = [],
        exampleSentenceKr: String = "",
        exampleSentenceEn: String = "",
        audioUrl: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.korean = korean
        self.romanization = romanization
        self.english = english
        self.partOfSpeech = partOfSpeech
        self.cefrLevel = cefrLevel
        self.frequencyRank = frequencyRank
        self.mediaDomains = mediaDomains
        self.exampleSentenceKr = exampleSentenceKr
        self.exampleSentenceEn = exampleSentenceEn
        self.audioUrl = audioUrl
        self.createdAt = createdAt
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id
        case korean
        case romanization
        case english
        case partOfSpeech = "part_of_speech"
        case cefrLevel = "cefr_level"
        case frequencyRank = "frequency_rank"
        case mediaDomains = "media_domains"
        case exampleSentenceKr = "example_sentence_kr"
        case exampleSentenceEn = "example_sentence_en"
        case audioUrl = "audio_url"
        case createdAt = "created_at"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        korean = try container.decode(String.self, forKey: .korean)
        romanization = try container.decodeIfPresent(String.self, forKey: .romanization) ?? ""
        english = try container.decode(String.self, forKey: .english)
        partOfSpeech = try container.decodeIfPresent(String.self, forKey: .partOfSpeech) ?? ""
        cefrLevel = try container.decodeIfPresent(String.self, forKey: .cefrLevel) ?? "A1"
        frequencyRank = try container.decodeIfPresent(Int.self, forKey: .frequencyRank) ?? 0
        mediaDomains = try container.decodeIfPresent([String].self, forKey: .mediaDomains) ?? []
        exampleSentenceKr = try container.decodeIfPresent(String.self, forKey: .exampleSentenceKr) ?? ""
        exampleSentenceEn = try container.decodeIfPresent(String.self, forKey: .exampleSentenceEn) ?? ""
        audioUrl = try container.decodeIfPresent(String.self, forKey: .audioUrl) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(korean, forKey: .korean)
        try container.encode(romanization, forKey: .romanization)
        try container.encode(english, forKey: .english)
        try container.encode(partOfSpeech, forKey: .partOfSpeech)
        try container.encode(cefrLevel, forKey: .cefrLevel)
        try container.encode(frequencyRank, forKey: .frequencyRank)
        try container.encode(mediaDomains, forKey: .mediaDomains)
        try container.encode(exampleSentenceKr, forKey: .exampleSentenceKr)
        try container.encode(exampleSentenceEn, forKey: .exampleSentenceEn)
        try container.encode(audioUrl, forKey: .audioUrl)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
