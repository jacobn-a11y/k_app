import SwiftUI

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

// MARK: - View

struct SpotInTheWildView: View {
    @State private var viewModel: SpotInTheWildViewModel
    @State private var showFeedback: Bool = false
    @State private var lastTapResult: SpotInTheWildViewModel.TapResult?
    @State private var feedbackPosition: CGPoint = .zero

    init(task: SpotInTheWildTask) {
        _viewModel = State(initialValue: SpotInTheWildViewModel(task: task))
    }

    var body: some View {
        VStack(spacing: 16) {
            // Instruction
            VStack(spacing: 4) {
                Text("Find all the")
                    .font(.headline)
                HStack(spacing: 8) {
                    Text(String(viewModel.task.targetJamo))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.blue)
                    Text("in this image!")
                        .font(.headline)
                }
                Text("\(viewModel.remainingCount) remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Image area with tap targets
            GeometryReader { geo in
                ZStack {
                    // Placeholder for actual image
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                        .overlay {
                            VStack {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                                Text(viewModel.task.imageDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }

                    // Show found targets
                    ForEach(viewModel.task.tapTargets) { target in
                        if viewModel.foundTargets.contains(target.id) {
                            Circle()
                                .stroke(Color.green, lineWidth: 3)
                                .frame(
                                    width: target.boundingBox.width * geo.size.width,
                                    height: target.boundingBox.height * geo.size.height
                                )
                                .position(
                                    x: (target.boundingBox.midX) * geo.size.width,
                                    y: (target.boundingBox.midY) * geo.size.height
                                )
                                .overlay {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .position(
                                            x: (target.boundingBox.midX) * geo.size.width,
                                            y: (target.boundingBox.midY) * geo.size.height
                                        )
                                }
                        }
                    }

                    // Tap feedback
                    if showFeedback {
                        let isHit = {
                            if case .found = lastTapResult { return true }
                            return false
                        }()
                        Image(systemName: isHit ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(isHit ? .green : .red)
                            .position(feedbackPosition)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let normalized = CGPoint(
                        x: location.x / geo.size.width,
                        y: location.y / geo.size.height
                    )
                    feedbackPosition = location
                    lastTapResult = viewModel.handleTap(at: normalized)
                    showFeedback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showFeedback = false
                    }
                }
            }
            .frame(height: 300)
            .padding(.horizontal)

            // Completion
            if viewModel.isComplete {
                VStack(spacing: 8) {
                    Label("All found!", systemImage: "party.popper.fill")
                        .font(.title2)
                        .foregroundStyle(.green)

                    Text("Accuracy: \(Int(viewModel.score * 100))%")
                        .font(.headline)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
