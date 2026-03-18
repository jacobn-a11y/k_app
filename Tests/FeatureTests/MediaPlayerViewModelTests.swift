import Testing
import Foundation
@testable import HallyuCore

@Suite("MediaPlayerViewModel Tests")
struct MediaPlayerViewModelTests {

    private func sampleContent() -> MediaContent {
        MediaContent(
            title: "Test Drama",
            contentType: "drama",
            source: "Test Show",
            difficultyScore: 0.4,
            cefrLevel: "A2",
            durationSeconds: 120,
            transcriptKr: "안녕하세요 오늘 날씨가 좋아요",
            transcriptSegments: [
                MediaContent.TranscriptSegment(startMs: 0, endMs: 5000, textKr: "안녕하세요", textEn: "Hello"),
                MediaContent.TranscriptSegment(startMs: 5000, endMs: 10000, textKr: "오늘 날씨가 좋아요", textEn: "The weather is nice today"),
                MediaContent.TranscriptSegment(startMs: 10000, endMs: 15000, textKr: "감사합니다", textEn: "Thank you"),
            ]
        )
    }

    // MARK: - Subtitle Mode

    @Test("Subtitle mode defaults to Korean only")
    func defaultSubtitleMode() {
        let vm = MediaPlayerViewModel(content: sampleContent())
        #expect(vm.subtitleMode == .koreanOnly)
    }

    @Test("Cycle subtitle mode goes through all modes")
    func cycleSubtitleMode() {
        let vm = MediaPlayerViewModel(content: sampleContent())
        #expect(vm.subtitleMode == .koreanOnly)
        vm.cycleSubtitleMode()
        #expect(vm.subtitleMode == .koreanAndEnglish)
        vm.cycleSubtitleMode()
        #expect(vm.subtitleMode == .none)
        vm.cycleSubtitleMode()
        #expect(vm.subtitleMode == .koreanOnly)
    }

    // MARK: - Playback

    @Test("Toggle playback changes state")
    func togglePlayback() {
        let vm = MediaPlayerViewModel(content: sampleContent())
        #expect(vm.isPlaying == false)
        vm.togglePlayback()
        #expect(vm.isPlaying == true)
        vm.togglePlayback()
        #expect(vm.isPlaying == false)
    }

    @Test("Playback rate cycles through available rates")
    func cyclePlaybackRate() {
        let vm = MediaPlayerViewModel(content: sampleContent())
        #expect(vm.playbackRate == 1.0)
        vm.cyclePlaybackRate()
        #expect(vm.playbackRate == 1.25)
        vm.cyclePlaybackRate()
        #expect(vm.playbackRate == 1.5)
        vm.cyclePlaybackRate()
        #expect(vm.playbackRate == 2.0)
        vm.cyclePlaybackRate()
        #expect(vm.playbackRate == 0.5)
    }

    // MARK: - Seeking

    @Test("Seek clamps to valid range")
    func seekClamped() {
        let vm = MediaPlayerViewModel(content: sampleContent())
        vm.seek(to: -10)
        #expect(vm.currentTime == 0)
        vm.seek(to: 9999)
        #expect(vm.currentTime == vm.duration)
    }

    @Test("Seek forward advances time")
    func seekForward() {
        let vm = MediaPlayerViewModel(content: sampleContent())
        vm.seek(to: 50)
        vm.seekForward(10)
        #expect(vm.currentTime == 60)
    }

    @Test("Seek backward rewinds time")
    func seekBackward() {
        let vm = MediaPlayerViewModel(content: sampleContent())
        vm.seek(to: 50)
        vm.seekBackward(10)
        #expect(vm.currentTime == 40)
    }

    // MARK: - Segment Navigation

    @Test("Next segment advances segment index")
    func nextSegment() {
        let vm = MediaPlayerViewModel(content: sampleContent())
        #expect(vm.currentSegmentIndex == 0)
        vm.nextSegment()
        #expect(vm.currentSegmentIndex == 1)
    }

    @Test("Previous segment from first stays at first")
    func previousSegmentAtStart() {
        let vm = MediaPlayerViewModel(content: sampleContent())
        vm.previousSegment()
        #expect(vm.currentSegmentIndex == 0)
    }

    @Test("Next segment at last stays at last")
    func nextSegmentAtEnd() {
        let vm = MediaPlayerViewModel(content: sampleContent())
        vm.nextSegment()
        vm.nextSegment()
        // Now at index 2 (last)
        vm.nextSegment()
        #expect(vm.currentSegmentIndex == 2)
    }

    // MARK: - Word Tap

    @Test("Tap word sets highlighted word and shows detail")
    func tapWord() {
        let vm = MediaPlayerViewModel(content: sampleContent())
        vm.tapWord("안녕하세요")
        #expect(vm.highlightedWord == "안녕하세요")
        #expect(vm.showWordDetail == true)
    }

    @Test("Dismiss word detail clears state")
    func dismissWordDetail() {
        let vm = MediaPlayerViewModel(content: sampleContent())
        vm.tapWord("안녕하세요")
        vm.dismissWordDetail()
        #expect(vm.highlightedWord == nil)
        #expect(vm.showWordDetail == false)
    }

    // MARK: - Content Type Detection

    @Test("Video content types detected correctly")
    func videoContentTypes() {
        let drama = MediaPlayerViewModel(content: MediaContent(title: "T", contentType: "drama"))
        #expect(drama.isVideoContent == true)
        #expect(drama.isTextContent == false)

        let news = MediaPlayerViewModel(content: MediaContent(title: "T", contentType: "news"))
        #expect(news.isVideoContent == false)
        #expect(news.isTextContent == true)

        let webtoon = MediaPlayerViewModel(content: MediaContent(title: "T", contentType: "webtoon"))
        #expect(webtoon.isVideoContent == false)
        #expect(webtoon.isTextContent == true)
    }

    // MARK: - Progress

    @Test("Progress calculated correctly")
    func progress() {
        let vm = MediaPlayerViewModel(content: sampleContent())
        vm.seek(to: 60)
        #expect(vm.progress == 0.5)
    }

    @Test("Progress is zero at start")
    func progressZero() {
        let vm = MediaPlayerViewModel(content: sampleContent())
        #expect(vm.progress == 0)
    }
}
