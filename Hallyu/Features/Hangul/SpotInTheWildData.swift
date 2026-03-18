import Foundation
import CoreGraphics
import Observation

// MARK: - Data

struct SpotInTheWildTask: Identifiable, Equatable {
    let id: UUID
    let targetJamo: Character
    let imageName: String
    let imageDescription: String
    let tapTargets: [TapTarget]
    let groupIndex: Int
}

struct TapTarget: Identifiable, Equatable {
    let id: UUID
    let boundingBox: CGRect // normalized 0-1 coordinates
    let character: String
}

// MARK: - View Model

@Observable
final class SpotInTheWildViewModel {
    let task: SpotInTheWildTask
    private(set) var foundTargets: Set<UUID> = []
    private(set) var incorrectTaps: Int = 0
    private(set) var isComplete: Bool = false
    private(set) var score: Double = 0

    var remainingCount: Int {
        task.tapTargets.count - foundTargets.count
    }

    init(task: SpotInTheWildTask) {
        self.task = task
    }

    func handleTap(at normalizedPoint: CGPoint) -> TapResult {
        for target in task.tapTargets {
            guard !foundTargets.contains(target.id) else { continue }

            if target.boundingBox.contains(normalizedPoint) {
                foundTargets.insert(target.id)
                if foundTargets.count == task.tapTargets.count {
                    isComplete = true
                    calculateScore()
                }
                return .found(target)
            }
        }

        incorrectTaps += 1
        return .missed
    }

    private func calculateScore() {
        let totalTaps = foundTargets.count + incorrectTaps
        guard totalTaps > 0 else {
            score = 0
            return
        }
        score = Double(foundTargets.count) / Double(totalTaps)
    }

    enum TapResult: Equatable {
        case found(TapTarget)
        case missed
    }
}

// MARK: - Sample Data

extension SpotInTheWildTask {
    static let sampleTasks: [SpotInTheWildTask] = [
        SpotInTheWildTask(
            id: UUID(),
            targetJamo: "ㄱ",
            imageName: "sample_drama_1",
            imageDescription: "K-drama scene with Korean text overlay showing title",
            tapTargets: [
                TapTarget(id: UUID(), boundingBox: CGRect(x: 0.3, y: 0.2, width: 0.08, height: 0.08), character: "ㄱ"),
                TapTarget(id: UUID(), boundingBox: CGRect(x: 0.6, y: 0.5, width: 0.08, height: 0.08), character: "ㄱ"),
            ],
            groupIndex: 0
        ),
        SpotInTheWildTask(
            id: UUID(),
            targetJamo: "ㅏ",
            imageName: "sample_drama_2",
            imageDescription: "Webtoon panel with dialogue bubbles",
            tapTargets: [
                TapTarget(id: UUID(), boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.06, height: 0.08), character: "ㅏ"),
                TapTarget(id: UUID(), boundingBox: CGRect(x: 0.5, y: 0.6, width: 0.06, height: 0.08), character: "ㅏ"),
                TapTarget(id: UUID(), boundingBox: CGRect(x: 0.7, y: 0.4, width: 0.06, height: 0.08), character: "ㅏ"),
            ],
            groupIndex: 0
        ),
    ]

    static func tasks(for groupIndex: Int) -> [SpotInTheWildTask] {
        sampleTasks.filter { $0.groupIndex == groupIndex }
    }
}
