import Foundation
import SwiftData

@Model
final class GrammarPattern: Codable {
    @Attribute(.unique) var id: UUID
    var patternName: String
    var patternTemplate: String
    var explanation: String
    var cefrLevel: String
    var formalityLevel: String
    var exampleSentencesData: Data?
    var commonMistakes: [String]
    var createdAt: Date

    struct ExampleSentence: Codable, Equatable {
        let kr: String
        let en: String
        let context: String
    }

    var exampleSentences: [ExampleSentence] {
        get {
            guard let data = exampleSentencesData else { return [] }
            return (try? JSONDecoder().decode([ExampleSentence].self, from: data)) ?? []
        }
        set {
            exampleSentencesData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        id: UUID = UUID(),
        patternName: String,
        patternTemplate: String,
        explanation: String,
        cefrLevel: String = "A1",
        formalityLevel: String = "neutral",
        exampleSentences: [ExampleSentence] = [],
        commonMistakes: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.patternName = patternName
        self.patternTemplate = patternTemplate
        self.explanation = explanation
        self.cefrLevel = cefrLevel
        self.formalityLevel = formalityLevel
        self.exampleSentencesData = try? JSONEncoder().encode(exampleSentences)
        self.commonMistakes = commonMistakes
        self.createdAt = createdAt
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id
        case patternName = "pattern_name"
        case patternTemplate = "pattern_template"
        case explanation
        case cefrLevel = "cefr_level"
        case formalityLevel = "formality_level"
        case exampleSentencesData = "example_sentences"
        case commonMistakes = "common_mistakes"
        case createdAt = "created_at"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        patternName = try container.decode(String.self, forKey: .patternName)
        patternTemplate = try container.decode(String.self, forKey: .patternTemplate)
        explanation = try container.decode(String.self, forKey: .explanation)
        cefrLevel = try container.decodeIfPresent(String.self, forKey: .cefrLevel) ?? "A1"
        formalityLevel = try container.decodeIfPresent(String.self, forKey: .formalityLevel) ?? "neutral"
        exampleSentencesData = try container.decodeIfPresent(Data.self, forKey: .exampleSentencesData)
        commonMistakes = try container.decodeIfPresent([String].self, forKey: .commonMistakes) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(patternName, forKey: .patternName)
        try container.encode(patternTemplate, forKey: .patternTemplate)
        try container.encode(explanation, forKey: .explanation)
        try container.encode(cefrLevel, forKey: .cefrLevel)
        try container.encode(formalityLevel, forKey: .formalityLevel)
        try container.encode(exampleSentencesData, forKey: .exampleSentencesData)
        try container.encode(commonMistakes, forKey: .commonMistakes)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
