import Testing
import Foundation
import CoreGraphics
@testable import HallyuCore

@Suite("SpotInTheWild Tests")
struct SpotInTheWildTests {

    private func makeTask() -> SpotInTheWildTask {
        SpotInTheWildTask(
            id: UUID(),
            targetJamo: "ㄱ",
            imageName: "test_image",
            imageDescription: "Test image",
            tapTargets: [
                TapTarget(id: UUID(), boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.1, height: 0.1), character: "ㄱ"),
                TapTarget(id: UUID(), boundingBox: CGRect(x: 0.5, y: 0.5, width: 0.1, height: 0.1), character: "ㄱ"),
            ],
            groupIndex: 0
        )
    }

    @Test("Initial state has zero found targets")
    func initialState() {
        let vm = SpotInTheWildViewModel(task: makeTask())
        #expect(vm.foundTargets.isEmpty)
        #expect(vm.incorrectTaps == 0)
        #expect(vm.isComplete == false)
        #expect(vm.remainingCount == 2)
    }

    @Test("Tapping on a target marks it as found")
    func tapOnTarget() {
        let vm = SpotInTheWildViewModel(task: makeTask())
        let result = vm.handleTap(at: CGPoint(x: 0.15, y: 0.15))
        if case .found = result {
            #expect(vm.foundTargets.count == 1)
            #expect(vm.remainingCount == 1)
        } else {
            Issue.record("Expected found result")
        }
    }

    @Test("Tapping away from targets counts as miss")
    func tapMiss() {
        let vm = SpotInTheWildViewModel(task: makeTask())
        let result = vm.handleTap(at: CGPoint(x: 0.9, y: 0.9))
        #expect(result == .missed)
        #expect(vm.incorrectTaps == 1)
        #expect(vm.foundTargets.isEmpty)
    }

    @Test("Finding all targets completes the task")
    func findAllTargets() {
        let vm = SpotInTheWildViewModel(task: makeTask())
        _ = vm.handleTap(at: CGPoint(x: 0.15, y: 0.15))
        _ = vm.handleTap(at: CGPoint(x: 0.55, y: 0.55))
        #expect(vm.isComplete == true)
        #expect(vm.foundTargets.count == 2)
    }

    @Test("Score reflects accuracy")
    func scoreAccuracy() {
        let vm = SpotInTheWildViewModel(task: makeTask())
        _ = vm.handleTap(at: CGPoint(x: 0.9, y: 0.9)) // miss
        _ = vm.handleTap(at: CGPoint(x: 0.15, y: 0.15)) // hit
        _ = vm.handleTap(at: CGPoint(x: 0.55, y: 0.55)) // hit
        #expect(vm.isComplete)
        // 2 hits + 1 miss = 2/3 accuracy
        #expect(abs(vm.score - (2.0/3.0)) < 0.01)
    }

    @Test("Perfect score with no misses")
    func perfectScore() {
        let vm = SpotInTheWildViewModel(task: makeTask())
        _ = vm.handleTap(at: CGPoint(x: 0.15, y: 0.15))
        _ = vm.handleTap(at: CGPoint(x: 0.55, y: 0.55))
        #expect(vm.score == 1.0)
    }

    @Test("Tapping already-found target does not re-count")
    func tapAlreadyFound() {
        let vm = SpotInTheWildViewModel(task: makeTask())
        _ = vm.handleTap(at: CGPoint(x: 0.15, y: 0.15))
        let result = vm.handleTap(at: CGPoint(x: 0.15, y: 0.15))
        // Second tap on same region should miss (already found)
        #expect(result == .missed)
        #expect(vm.foundTargets.count == 1)
    }

    @Test("Sample tasks exist for group 0")
    func sampleTasksExist() {
        let tasks = SpotInTheWildTask.tasks(for: 0)
        #expect(!tasks.isEmpty)
    }

    @Test("Spot tasks cover all lesson groups")
    func sampleTasksCoverAllGroups() {
        let allGroups = Set(HangulData.lessonGroups.map(\.id))
        let coveredGroups = Set(SpotInTheWildTask.sampleTasks.map(\.groupIndex))
        #expect(allGroups.isSubset(of: coveredGroups))
    }

    @Test("Each sample task has at least two tap targets")
    func sampleTaskTargetsSufficient() {
        for task in SpotInTheWildTask.sampleTasks {
            #expect(task.tapTargets.count >= 2)
        }
    }
}
