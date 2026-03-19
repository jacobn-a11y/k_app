import XCTest
@testable import Hallyu

final class MediaDownloadManagerTests: XCTestCase {

    var downloadManager: MediaDownloadManager!

    override func setUp() {
        downloadManager = MediaDownloadManager()
        downloadManager.removeAllDownloads()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertTrue(downloadManager.downloadedMedia.isEmpty)
        XCTAssertEqual(downloadManager.totalDownloadSize, 0)
        XCTAssertEqual(downloadManager.formattedTotalSize, "Zero KB")
    }

    // MARK: - Download State

    func testDownloadStateForUnknownMedia() {
        let mediaId = UUID()
        XCTAssertEqual(downloadManager.downloadState(for: mediaId), .notDownloaded)
    }

    func testIsDownloadedReturnsFalseForUnknownMedia() {
        XCTAssertFalse(downloadManager.isDownloaded(mediaId: UUID()))
    }

    func testLocalURLReturnsNilForUnknownMedia() {
        XCTAssertNil(downloadManager.localURL(for: UUID()))
    }

    // MARK: - Download State Enum

    func testDownloadStateRawValues() {
        XCTAssertEqual(DownloadState.notDownloaded.rawValue, "notDownloaded")
        XCTAssertEqual(DownloadState.downloading.rawValue, "downloading")
        XCTAssertEqual(DownloadState.downloaded.rawValue, "downloaded")
        XCTAssertEqual(DownloadState.failed.rawValue, "failed")
    }

    // MARK: - Remove Operations

    func testRemoveNonExistentDownload() {
        // Should not crash when removing a non-existent download
        downloadManager.removeDownload(mediaId: UUID())
        XCTAssertTrue(downloadManager.downloadedMedia.isEmpty)
    }

    func testRemoveAllDownloadsWhenEmpty() {
        downloadManager.removeAllDownloads()
        XCTAssertTrue(downloadManager.downloadedMedia.isEmpty)
        XCTAssertEqual(downloadManager.totalDownloadSize, 0)
    }
}
