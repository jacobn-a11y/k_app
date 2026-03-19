#if canImport(UIKit)
import SnapshotTesting
import SwiftUI
import XCTest
@testable import HallyuCore

@MainActor
final class CriticalScreensSnapshotTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        isRecording = false
    }

    func testAuthViewDefaultSnapshot() {
        let view = NavigationStack {
            AuthView { _ in }
                .environment(ServiceContainer.testing())
        }

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13Pro)
        )
    }

    func testSpotInTheWildSnapshot() {
        let task = SpotInTheWildTask.tasks(for: 0).first ?? SpotInTheWildTask.sampleTasks[0]
        let view = SpotInTheWildView(task: task)
            .padding()

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13Pro)
        )
    }

    func testMediaPlayerSnapshot() {
        let content = MediaContent(
            title: "Snapshot Clip",
            contentType: "drama",
            source: "Snapshot",
            difficultyScore: 0.35,
            cefrLevel: "A2",
            durationSeconds: 90,
            transcriptKr: "안녕하세요 만나서 반가워요",
            transcriptSegments: [
                .init(startMs: 0, endMs: 5000, textKr: "안녕하세요", textEn: "Hello"),
                .init(startMs: 5000, endMs: 10000, textKr: "만나서 반가워요", textEn: "Nice to meet you")
            ],
            mediaUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )

        let view = NavigationStack {
            MediaPlayerView(content: content)
                .environment(ServiceContainer.testing())
        }

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13Pro)
        )
    }
}
#endif
