import Testing
import Foundation
@testable import HallyuCore

@Suite("SubtitleParser Tests")
struct SubtitleParserTests {

    // MARK: - Format Detection

    @Test("Detects SRT format")
    func detectsSRT() {
        let srt = """
        1
        00:00:01,000 --> 00:00:03,000
        안녕하세요
        """
        #expect(SubtitleParser.detect(srt) == .srt)
    }

    @Test("Detects VTT format")
    func detectsVTT() {
        let vtt = """
        WEBVTT

        00:00:01.000 --> 00:00:03.000
        안녕하세요
        """
        #expect(SubtitleParser.detect(vtt) == .vtt)
    }

    @Test("Returns unknown for unrecognized format")
    func detectsUnknown() {
        #expect(SubtitleParser.detect("just some text") == .unknown)
    }

    // MARK: - SRT Parsing

    @Test("Parses basic SRT with timestamps")
    func parsesBasicSRT() {
        let srt = """
        1
        00:00:01,000 --> 00:00:03,500
        안녕하세요

        2
        00:00:04,000 --> 00:00:07,200
        오늘 날씨가 좋아요
        """

        let segments = SubtitleParser.parseSRT(srt)
        #expect(segments.count == 2)

        #expect(segments[0].startMs == 1000)
        #expect(segments[0].endMs == 3500)
        #expect(segments[0].textKr == "안녕하세요")

        #expect(segments[1].startMs == 4000)
        #expect(segments[1].endMs == 7200)
        #expect(segments[1].textKr == "오늘 날씨가 좋아요")
    }

    @Test("Parses bilingual SRT (Korean + English)")
    func parsesBilingualSRT() {
        let srt = """
        1
        00:00:01,000 --> 00:00:03,000
        안녕하세요
        Hello

        2
        00:00:04,000 --> 00:00:07,000
        감사합니다
        Thank you
        """

        let segments = SubtitleParser.parseSRT(srt)
        #expect(segments.count == 2)

        #expect(segments[0].textKr == "안녕하세요")
        #expect(segments[0].textEn == "Hello")

        #expect(segments[1].textKr == "감사합니다")
        #expect(segments[1].textEn == "Thank you")
    }

    @Test("Handles SRT with hours in timestamp")
    func parsesHoursTimestamp() {
        let srt = """
        1
        01:30:45,500 --> 01:30:48,000
        긴 영화의 대사
        """

        let segments = SubtitleParser.parseSRT(srt)
        #expect(segments.count == 1)
        #expect(segments[0].startMs == 5445500) // 1*3600 + 30*60 + 45 = 5445 seconds
        #expect(segments[0].endMs == 5448000)
    }

    @Test("Skips SRT blocks without timestamps")
    func skipsBadBlocks() {
        let srt = """
        1
        This is not a timestamp
        안녕하세요

        2
        00:00:01,000 --> 00:00:03,000
        좋아요
        """

        let segments = SubtitleParser.parseSRT(srt)
        #expect(segments.count == 1)
        #expect(segments[0].textKr == "좋아요")
    }

    @Test("Handles empty SRT")
    func emptyInput() {
        let segments = SubtitleParser.parseSRT("")
        #expect(segments.isEmpty)
    }

    // MARK: - VTT Parsing

    @Test("Parses basic VTT")
    func parsesBasicVTT() {
        let vtt = """
        WEBVTT

        00:00:01.000 --> 00:00:03.500
        안녕하세요

        00:00:04.000 --> 00:00:07.200
        오늘 날씨가 좋아요
        """

        let segments = SubtitleParser.parseVTT(vtt)
        #expect(segments.count == 2)

        #expect(segments[0].startMs == 1000)
        #expect(segments[0].endMs == 3500)
        #expect(segments[0].textKr == "안녕하세요")

        #expect(segments[1].startMs == 4000)
        #expect(segments[1].endMs == 7200)
    }

    @Test("Parses bilingual VTT")
    func parsesBilingualVTT() {
        let vtt = """
        WEBVTT

        00:00:01.000 --> 00:00:03.000
        커피 주세요
        Coffee please
        """

        let segments = SubtitleParser.parseVTT(vtt)
        #expect(segments.count == 1)
        #expect(segments[0].textKr == "커피 주세요")
        #expect(segments[0].textEn == "Coffee please")
    }

    @Test("VTT with MM:SS format (no hours)")
    func parsesShortVTTTimestamps() {
        let vtt = """
        WEBVTT

        01:20.500 --> 01:25.000
        짧은 타임스탬프
        """

        let segments = SubtitleParser.parseVTT(vtt)
        #expect(segments.count == 1)
        #expect(segments[0].startMs == 80500) // 1*60 + 20 = 80 seconds + 500ms
        #expect(segments[0].endMs == 85000)
    }

    // MARK: - Auto-detect and Parse

    @Test("Auto-detect parses SRT correctly")
    func autoDetectSRT() {
        let srt = """
        1
        00:00:01,000 --> 00:00:03,000
        자동 감지 테스트
        """

        let segments = SubtitleParser.parse(srt)
        #expect(segments.count == 1)
        #expect(segments[0].textKr == "자동 감지 테스트")
    }

    @Test("Auto-detect parses VTT correctly")
    func autoDetectVTT() {
        let vtt = """
        WEBVTT

        00:00:01.000 --> 00:00:03.000
        자동 감지 테스트
        """

        let segments = SubtitleParser.parse(vtt)
        #expect(segments.count == 1)
        #expect(segments[0].textKr == "자동 감지 테스트")
    }
}
