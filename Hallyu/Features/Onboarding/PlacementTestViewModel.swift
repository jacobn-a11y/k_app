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
    private var currentDifficultyIndex: Int = 1
    private var itemStartTime: Date = Date()
    private let maxQuestionCount: Int = 12

    private static let levelOrder = ["pre-A1", "A1", "A2", "B1", "B2"]

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

        // A1/A2 Listening
        PlacementItem(type: .listeningComprehension, prompt: "Listen to the greeting. Which phrase was spoken?", options: ["안녕하세요", "감사합니다", "미안합니다", "잘 가요"], correctIndex: 0, cefrLevel: "A1", audioClipName: "greeting_a1"),
        PlacementItem(type: .listeningComprehension, prompt: "Listen to the request. What did you hear?", options: ["이거 얼마예요?", "커피 주세요", "잘 부탁드립니다", "다음에 또 만나요"], correctIndex: 1, cefrLevel: "A2", audioClipName: "request_a2"),
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
        currentDifficultyIndex = levelIndex(for: "A1")
        let prioritized = Self.itemPool.sorted { lhs, rhs in
            let lhsPriority = itemPriority(lhs, targetDifficultyIndex: currentDifficultyIndex)
            let rhsPriority = itemPriority(rhs, targetDifficultyIndex: currentDifficultyIndex)
            if lhsPriority != rhsPriority { return lhsPriority < rhsPriority }
            return lhs.id.uuidString < rhs.id.uuidString
        }
        items = Array(prioritized.prefix(maxQuestionCount))
        itemStartTime = Date()
    }

    // MARK: - Actions

    func submitAnswer(optionIndex: Int) {
        guard let item = currentItem else { return }

        let responseTime = Int(Date().timeIntervalSince(itemStartTime) * 1000)
        recordResponse(item: item, selectedIndex: optionIndex, wasCorrect: optionIndex == item.correctIndex, responseTimeMs: responseTime)
    }

    func skipItem() {
        guard let item = currentItem else { return }
        recordResponse(item: item, selectedIndex: -1, wasCorrect: false, responseTimeMs: 0)
    }

    // MARK: - Level Estimation

    private func calculateResults() {
        isComplete = true

        // Calculate accuracy per skill type
        let typeResults = Dictionary(grouping: results) { $0.item.type.rawValue }
        for (type, typeRes) in typeResults {
            let correct = typeRes.filter { $0.wasCorrect }.count
            skillBreakdown[type] = Double(correct) / Double(typeRes.count)
        }

        let readinessScore = estimatedReadiness(from: results)
        estimatedLevel = levelForReadiness(readinessScore)
    }

    // MARK: - Adaptive Helpers

    private func recordResponse(item: PlacementItem, selectedIndex: Int, wasCorrect: Bool, responseTimeMs: Int) {
        results.append(ItemResult(
            item: item,
            selectedIndex: selectedIndex,
            wasCorrect: wasCorrect,
            responseTimeMs: responseTimeMs
        ))

        selectedOptionIndex = nil
        currentItemIndex += 1
        itemStartTime = Date()

        if currentItemIndex >= items.count {
            calculateResults()
            return
        }

        updateDifficulty(afterCorrect: wasCorrect, responseTimeMs: responseTimeMs)
        rebalanceRemainingItems()
    }

    private func updateDifficulty(afterCorrect: Bool, responseTimeMs: Int) {
        let fastestThreshold = 4_500
        let slowThreshold = 12_000

        if afterCorrect {
            if responseTimeMs <= fastestThreshold {
                currentDifficultyIndex = min(currentDifficultyIndex + 1, Self.levelOrder.count - 1)
            } else if responseTimeMs >= slowThreshold {
                currentDifficultyIndex = max(currentDifficultyIndex - 1, 0)
            }
        } else {
            currentDifficultyIndex = max(currentDifficultyIndex - 1, 0)
        }
    }

    private func rebalanceRemainingItems() {
        guard currentItemIndex < items.count else { return }

        let answeredItems = Array(items.prefix(currentItemIndex))
        let answeredIDs = Set(answeredItems.map(\.id))
        let remainingPool = Self.itemPool.filter { !answeredIDs.contains($0.id) }
        let remainingSlots = min(maxQuestionCount, items.count) - currentItemIndex

        let sortedRemaining = remainingPool.sorted { lhs, rhs in
            let lhsPriority = itemPriority(lhs, targetDifficultyIndex: currentDifficultyIndex)
            let rhsPriority = itemPriority(rhs, targetDifficultyIndex: currentDifficultyIndex)
            if lhsPriority != rhsPriority { return lhsPriority < rhsPriority }
            if lhs.type == .listeningComprehension && rhs.type != .listeningComprehension { return true }
            if lhs.type != .listeningComprehension && rhs.type == .listeningComprehension { return false }
            return lhs.id.uuidString < rhs.id.uuidString
        }

        items = answeredItems + Array(sortedRemaining.prefix(remainingSlots))
    }

    private func levelIndex(for level: String) -> Int {
        Self.levelOrder.firstIndex(of: level) ?? 1
    }

    private func itemPriority(_ item: PlacementItem, targetDifficultyIndex: Int) -> Int {
        let levelDistance = abs(levelIndex(for: item.cefrLevel) - targetDifficultyIndex)
        let typePriority: Int
        switch item.type {
        case .listeningComprehension:
            typePriority = 0
        case .hangulReading:
            typePriority = 1
        case .vocabularyRecognition:
            typePriority = 2
        case .grammarMultipleChoice:
            typePriority = 3
        }

        return levelDistance * 10 + typePriority
    }

    private func difficultyWeight(for level: String) -> Double {
        switch level {
        case "B2": return 1.4
        case "B1": return 1.2
        case "A2": return 1.0
        case "A1": return 0.8
        default: return 0.6
        }
    }

    private func responseWeight(for responseTimeMs: Int) -> Double {
        if responseTimeMs <= 4_500 { return 1.1 }
        if responseTimeMs <= 9_000 { return 1.0 }
        return 0.85
    }

    private func estimatedReadiness(from results: [ItemResult]) -> Double {
        guard !results.isEmpty else { return 0 }

        let weightedScore = results.reduce(0.0) { sum, result in
            guard result.wasCorrect else { return sum }
            let levelWeight = difficultyWeight(for: result.item.cefrLevel)
            let speedWeight = responseWeight(for: result.responseTimeMs)
            return sum + levelWeight * speedWeight
        }

        let totalWeight = results.reduce(0.0) { sum, result in
            sum + difficultyWeight(for: result.item.cefrLevel)
        }

        return totalWeight > 0 ? min(weightedScore / totalWeight, 1.0) : 0
    }

    private func levelForReadiness(_ readiness: Double) -> String {
        switch readiness {
        case ..<0.20:
            return "pre-A1"
        case ..<0.40:
            return "A1"
        case ..<0.60:
            return "A2"
        case ..<0.80:
            return "B1"
        default:
            return "B2"
        }
    }
}
