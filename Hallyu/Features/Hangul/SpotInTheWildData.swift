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
        makeTask(
            target: "ㄱ",
            imageName: "sample_drama_1",
            imageDescription: "A subtitle freeze frame from a convenience store scene",
            groupIndex: 0,
            targets: [
                CGRect(x: 0.18, y: 0.22, width: 0.10, height: 0.10),
                CGRect(x: 0.62, y: 0.53, width: 0.10, height: 0.10),
            ]
        ),
        makeTask(
            target: "ㅏ",
            imageName: "sample_drama_2",
            imageDescription: "A webtoon dialogue panel with handwritten bubbles",
            groupIndex: 0,
            targets: [
                CGRect(x: 0.20, y: 0.30, width: 0.09, height: 0.11),
                CGRect(x: 0.52, y: 0.62, width: 0.09, height: 0.11),
                CGRect(x: 0.74, y: 0.41, width: 0.09, height: 0.11),
            ]
        ),
        makeTask(
            target: "ㅁ",
            imageName: "sample_drama_3",
            imageDescription: "A cafe menu board screenshot from a vlog",
            groupIndex: 1,
            targets: [
                CGRect(x: 0.26, y: 0.18, width: 0.11, height: 0.10),
                CGRect(x: 0.56, y: 0.37, width: 0.11, height: 0.10),
            ]
        ),
        makeTask(
            target: "ㅗ",
            imageName: "sample_drama_4",
            imageDescription: "A K-drama text-message overlay with mixed short words",
            groupIndex: 1,
            targets: [
                CGRect(x: 0.15, y: 0.40, width: 0.08, height: 0.10),
                CGRect(x: 0.43, y: 0.56, width: 0.08, height: 0.10),
                CGRect(x: 0.75, y: 0.28, width: 0.08, height: 0.10),
            ]
        ),
        makeTask(
            target: "ㅅ",
            imageName: "sample_drama_5",
            imageDescription: "A fast subtitle line during a market conversation",
            groupIndex: 2,
            targets: [
                CGRect(x: 0.30, y: 0.68, width: 0.09, height: 0.11),
                CGRect(x: 0.58, y: 0.68, width: 0.09, height: 0.11),
            ]
        ),
        makeTask(
            target: "ㅇ",
            imageName: "sample_drama_6",
            imageDescription: "A webtoon panel with a short speech balloon",
            groupIndex: 2,
            targets: [
                CGRect(x: 0.22, y: 0.25, width: 0.10, height: 0.10),
                CGRect(x: 0.50, y: 0.25, width: 0.10, height: 0.10),
                CGRect(x: 0.68, y: 0.55, width: 0.10, height: 0.10),
            ]
        ),
        makeTask(
            target: "ㅊ",
            imageName: "sample_drama_7",
            imageDescription: "A headline card from short-form news video",
            groupIndex: 3,
            targets: [
                CGRect(x: 0.18, y: 0.18, width: 0.09, height: 0.11),
                CGRect(x: 0.46, y: 0.18, width: 0.09, height: 0.11),
            ]
        ),
        makeTask(
            target: "ㅑ",
            imageName: "sample_drama_8",
            imageDescription: "A colorful lyric subtitle card from a music clip",
            groupIndex: 3,
            targets: [
                CGRect(x: 0.33, y: 0.34, width: 0.10, height: 0.12),
                CGRect(x: 0.62, y: 0.34, width: 0.10, height: 0.12),
            ]
        ),
        makeTask(
            target: "ㅎ",
            imageName: "sample_drama_9",
            imageDescription: "A dramatic title card with emphasized final consonants",
            groupIndex: 4,
            targets: [
                CGRect(x: 0.24, y: 0.22, width: 0.10, height: 0.12),
                CGRect(x: 0.52, y: 0.50, width: 0.10, height: 0.12),
                CGRect(x: 0.76, y: 0.50, width: 0.10, height: 0.12),
            ]
        ),
        makeTask(
            target: "ㅃ",
            imageName: "sample_drama_10",
            imageDescription: "An on-screen sound-effect caption in a variety show clip",
            groupIndex: 5,
            targets: [
                CGRect(x: 0.27, y: 0.45, width: 0.12, height: 0.12),
                CGRect(x: 0.58, y: 0.45, width: 0.12, height: 0.12),
            ]
        ),
        makeTask(
            target: "ㅔ",
            imageName: "sample_drama_11",
            imageDescription: "A mobile chat screenshot from a slice-of-life scene",
            groupIndex: 6,
            targets: [
                CGRect(x: 0.19, y: 0.31, width: 0.09, height: 0.11),
                CGRect(x: 0.47, y: 0.31, width: 0.09, height: 0.11),
                CGRect(x: 0.72, y: 0.63, width: 0.09, height: 0.11),
            ]
        ),
        makeTask(
            target: "ㅘ",
            imageName: "sample_drama_12",
            imageDescription: "A subtitle frame from a travel vlog about Seoul",
            groupIndex: 7,
            targets: [
                CGRect(x: 0.21, y: 0.58, width: 0.10, height: 0.12),
                CGRect(x: 0.53, y: 0.58, width: 0.10, height: 0.12),
            ]
        ),
    ]

    static func tasks(for groupIndex: Int) -> [SpotInTheWildTask] {
        let matches = sampleTasks.filter { $0.groupIndex == groupIndex }
        if matches.isEmpty {
            return sampleTasks.filter { $0.groupIndex == 0 }
        }
        return matches
    }

    private static func makeTask(
        target: Character,
        imageName: String,
        imageDescription: String,
        groupIndex: Int,
        targets: [CGRect]
    ) -> SpotInTheWildTask {
        SpotInTheWildTask(
            id: UUID(),
            targetJamo: target,
            imageName: imageName,
            imageDescription: imageDescription,
            tapTargets: targets.map {
                TapTarget(id: UUID(), boundingBox: $0, character: String(target))
            },
            groupIndex: groupIndex
        )
    }
}
