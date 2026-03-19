import Foundation
import Observation

@Observable
final class PlacementTestViewModel {

    // MARK: - Types

    enum ItemType: String, Codable, Sendable {
        case hangulReading = "hangul_reading"
        case vocabularyRecognition = "vocabulary_recognition"
        case grammarMultipleChoice = "grammar_mc"
        case listeningComprehension = "listening"
    }

    struct PlacementItem: Identifiable, Sendable {
        let id = UUID()
        let type: ItemType
        let prompt: String
        let options: [String]
        let correctIndex: Int
        let cefrLevel: String
        let audioClipName: String?

        init(
            type: ItemType,
            prompt: String,
            options: [String],
            correctIndex: Int,
            cefrLevel: String,
            audioClipName: String? = nil
        ) {
            self.type = type
            self.prompt = prompt
            self.options = options
            self.correctIndex = correctIndex
            self.cefrLevel = cefrLevel
            self.audioClipName = audioClipName
        }
    }

    struct ItemResult {
        let item: PlacementItem
        let selectedIndex: Int
        let wasCorrect: Bool
        let responseTimeMs: Int
    }

    // MARK: - State

    private(set) var currentItemIndex: Int = 0
    private(set) var results: [ItemResult] = []
    private(set) var isComplete: Bool = false
    private(set) var estimatedLevel: String = "pre-A1"
    private(set) var skillBreakdown: [String: Double] = [:]
    var selectedOptionIndex: Int?

    private var items: [PlacementItem] = []
    private var currentDifficulty: String = "A1"
    private var itemStartTime: Date = Date()

    // MARK: - Item Pool

    static let itemPool: [PlacementItem] = [
        // A1 Hangul Reading
        PlacementItem(type: .hangulReading, prompt: "What sound does \u{3131} make?", options: ["g/k", "n", "d/t", "r/l"], correctIndex: 0, cefrLevel: "A1"),
        PlacementItem(type: .hangulReading, prompt: "Read this syllable: \u{D55C}", options: ["han", "kan", "nan", "dan"], correctIndex: 0, cefrLevel: "A1"),
        PlacementItem(type: .hangulReading, prompt: "Read this word: \u{C548}\u{B155}", options: ["annyeong", "anyong", "onnyeong", "annyang"], correctIndex: 0, cefrLevel: "A1"),

        // A1 Vocabulary
        PlacementItem(type: .vocabularyRecognition, prompt: "What does \u{AC10}\u{C0AC}\u{D569}\u{B2C8}\u{B2E4} mean?", options: ["Thank you", "Hello", "Goodbye", "Sorry"], correctIndex: 0, cefrLevel: "A1"),
        PlacementItem(type: .vocabularyRecognition, prompt: "What does \u{BB3C} mean?", options: ["Fire", "Water", "Wind", "Earth"], correctIndex: 1, cefrLevel: "A1"),

        // A1 Grammar
        PlacementItem(type: .grammarMultipleChoice, prompt: "Choose the correct particle: \u{C800}___ \u{D559}\u{C0DD}\u{C774}\u{C5D0}\u{C694}", options: ["\u{B294}", "\u{B97C}", "\u{C5D0}", "\u{C758}"], correctIndex: 0, cefrLevel: "A1"),

        // A2 Vocabulary
        PlacementItem(type: .vocabularyRecognition, prompt: "What does \u{C2DC}\u{AC04} mean?", options: ["Place", "Time", "Person", "Thing"], correctIndex: 1, cefrLevel: "A2"),
        PlacementItem(type: .vocabularyRecognition, prompt: "What does \u{C5B4}\u{C81C} mean?", options: ["Today", "Tomorrow", "Yesterday", "Now"], correctIndex: 2, cefrLevel: "A2"),

        // A2 Grammar
        PlacementItem(type: .grammarMultipleChoice, prompt: "Choose the correct ending: \u{C5B4}\u{C81C} \u{C601}\u{D654}\u{B97C} ___", options: ["\u{BD24}\u{C5B4}\u{C694}", "\u{BD10}\u{C694}", "\u{BCA4}\u{C5B4}\u{C694}", "\u{BD24}\u{C694}"], correctIndex: 0, cefrLevel: "A2"),
        PlacementItem(type: .grammarMultipleChoice, prompt: "Which is the polite request form of \u{AC00}\u{B2E4}?", options: ["\u{AC00}\u{C138}\u{C694}", "\u{AC00}\u{C694}", "\u{AC00}\u{B77C}", "\u{AC00}\u{C790}"], correctIndex: 0, cefrLevel: "A2"),

        // B1 Vocabulary
        PlacementItem(type: .vocabularyRecognition, prompt: "What does \u{ACE0}\u{BBFC}\u{D558}\u{B2E4} mean?", options: ["To be happy", "To worry/agonize", "To be angry", "To be surprised"], correctIndex: 1, cefrLevel: "B1"),
        PlacementItem(type: .vocabularyRecognition, prompt: "What does \u{C5B4}\u{C6F8}\u{B4E0} mean?", options: ["Anyway", "However", "Therefore", "Because"], correctIndex: 0, cefrLevel: "B1"),

        // B1 Grammar
        PlacementItem(type: .grammarMultipleChoice, prompt: "Complete: \u{BE44}\u{AC00} ___ \u{C6B0}\u{C0B0}\u{C744} \u{AC00}\u{C838}\u{AC00}\u{C138}\u{C694}", options: ["\u{C624}\u{BA74}", "\u{C624}\u{ACE0}", "\u{C640}\u{C11C}", "\u{C624}\u{B2C8}\u{AE4C}"], correctIndex: 3, cefrLevel: "B1"),

        // B2 Vocabulary
        PlacementItem(type: .vocabularyRecognition, prompt: "What does \u{C800}\u{B3CC}\u{C801}\u{C774}\u{B2E4} mean?", options: ["Automatic", "Spontaneous", "Voluntary", "Impulsive"], correctIndex: 2, cefrLevel: "B2"),
        PlacementItem(type: .vocabularyRecognition, prompt: "What does \u{B9E5}\u{B77D} mean?", options: ["Melody", "Context", "Rhythm", "Summary"], correctIndex: 1, cefrLevel: "B2"),

        // B2 Grammar
        PlacementItem(type: .grammarMultipleChoice, prompt: "Choose the correct connective: \u{B178}\u{B825}\u{D55C} ___ \u{C131}\u{ACF5}\u{D558}\u{C9C0} \u{BABB}\u{D588}\u{B2E4}", options: ["\u{B370}\u{B3C4}", "\u{B2C8}\u{AE4C}", "\u{C5B4}\u{C11C}", "\u{AE30} \u{B54C}\u{BB38}\u{C5D0}"], correctIndex: 0, cefrLevel: "B2"),
    ]

    // MARK: - Computed

    var currentItem: PlacementItem? {
        guard currentItemIndex < items.count else { return nil }
        return items[currentItemIndex]
    }

    var totalItems: Int { items.count }

    var progressFraction: Double {
        guard !items.isEmpty else { return 0 }
        return Double(currentItemIndex) / Double(items.count)
    }

    var correctCount: Int {
        results.filter { $0.wasCorrect }.count
    }

    var totalAnswered: Int {
        results.count
    }

    // MARK: - Init

    init() {
        selectItems()
    }

    // MARK: - Item Selection (IRT-inspired adaptive)

    private func selectItems() {
        // Start with A1 items, then adapt based on performance
        // Select 15-20 items spanning all levels
        let grouped = Dictionary(grouping: Self.itemPool) { $0.cefrLevel }
        var selected: [PlacementItem] = []

        // Always start with 3 A1 items
        if let a1 = grouped["A1"] {
            selected.append(contentsOf: a1.prefix(3))
        }

        // Add items from higher levels
        for level in ["A2", "B1", "B2"] {
            if let items = grouped[level] {
                selected.append(contentsOf: items.prefix(3))
            }
        }

        // Fill remaining with mixed items
        let remaining = Self.itemPool.filter { item in
            !selected.contains(where: { $0.id == item.id })
        }
        selected.append(contentsOf: remaining.prefix(max(0, 18 - selected.count)))

        items = selected
        itemStartTime = Date()
    }

    // MARK: - Actions

    func submitAnswer(optionIndex: Int) {
        guard let item = currentItem else { return }

        let responseTime = Int(Date().timeIntervalSince(itemStartTime) * 1000)
        let wasCorrect = optionIndex == item.correctIndex

        results.append(ItemResult(
            item: item,
            selectedIndex: optionIndex,
            wasCorrect: wasCorrect,
            responseTimeMs: responseTime
        ))

        selectedOptionIndex = nil
        currentItemIndex += 1
        itemStartTime = Date()

        if currentItemIndex >= items.count {
            calculateResults()
        }
    }

    func skipItem() {
        guard let item = currentItem else { return }

        results.append(ItemResult(
            item: item,
            selectedIndex: -1,
            wasCorrect: false,
            responseTimeMs: 0
        ))

        selectedOptionIndex = nil
        currentItemIndex += 1
        itemStartTime = Date()

        if currentItemIndex >= items.count {
            calculateResults()
        }
    }

    // MARK: - Level Estimation

    private func calculateResults() {
        isComplete = true

        // Calculate accuracy per CEFR level
        let groupedResults = Dictionary(grouping: results) { $0.item.cefrLevel }
        var levelAccuracy: [String: Double] = [:]

        for (level, levelResults) in groupedResults {
            let correct = levelResults.filter { $0.wasCorrect }.count
            levelAccuracy[level] = Double(correct) / Double(levelResults.count)
        }

        // Calculate accuracy per skill type
        let typeResults = Dictionary(grouping: results) { $0.item.type.rawValue }
        for (type, typeRes) in typeResults {
            let correct = typeRes.filter { $0.wasCorrect }.count
            skillBreakdown[type] = Double(correct) / Double(typeRes.count)
        }

        // Determine CEFR level: highest level where accuracy >= 60%
        let levels: [(String, Double)] = [
            ("B2", levelAccuracy["B2"] ?? 0),
            ("B1", levelAccuracy["B1"] ?? 0),
            ("A2", levelAccuracy["A2"] ?? 0),
            ("A1", levelAccuracy["A1"] ?? 0),
        ]

        estimatedLevel = "pre-A1"
        for (level, accuracy) in levels {
            if accuracy >= 0.6 {
                estimatedLevel = level
                break
            }
        }
    }
}
