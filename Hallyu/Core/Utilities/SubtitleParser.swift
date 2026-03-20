import Foundation

/// Parses SRT and WebVTT subtitle files into MediaContent.TranscriptSegment arrays.
/// Handles bilingual subtitles (Korean + English) by detecting Korean text via HangulUtilities.
enum SubtitleParser {

    enum SubtitleFormat {
        case srt
        case vtt
        case unknown
    }

    /// Detect whether raw subtitle text is SRT, VTT, or unknown.
    static func detect(_ content: String) -> SubtitleFormat {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("WEBVTT") {
            return .vtt
        }
        // SRT files typically start with a sequence number (digit)
        if let first = trimmed.first, first.isNumber {
            return .srt
        }
        // Try to detect by timestamp format
        if trimmed.contains("-->") {
            if trimmed.contains(",") { return .srt }
            if trimmed.contains(".") { return .vtt }
        }
        return .unknown
    }

    /// Parse subtitle content, auto-detecting format.
    static func parse(_ content: String) -> [MediaContent.TranscriptSegment] {
        switch detect(content) {
        case .srt: return parseSRT(content)
        case .vtt: return parseVTT(content)
        case .unknown: return parseSRT(content) // best-effort fallback
        }
    }

    /// Parse SRT format subtitles.
    /// SRT timestamps use comma as decimal separator: `HH:MM:SS,mmm --> HH:MM:SS,mmm`
    static func parseSRT(_ content: String) -> [MediaContent.TranscriptSegment] {
        let blocks = splitIntoBlocks(content)
        return blocks.compactMap { parseSRTBlock($0) }
    }

    /// Parse WebVTT format subtitles.
    /// VTT timestamps use dot as decimal separator: `HH:MM:SS.mmm --> HH:MM:SS.mmm`
    static func parseVTT(_ content: String) -> [MediaContent.TranscriptSegment] {
        // Strip WEBVTT header and any metadata before first cue
        var cleaned = content
        if let headerEnd = content.range(of: "\n\n") {
            let header = content[content.startIndex..<headerEnd.lowerBound]
            if header.contains("WEBVTT") {
                cleaned = String(content[headerEnd.upperBound...])
            }
        }

        let blocks = splitIntoBlocks(cleaned)
        return blocks.compactMap { parseVTTBlock($0) }
    }

    // MARK: - Private

    private static func splitIntoBlocks(_ content: String) -> [String] {
        content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func parseSRTBlock(_ block: String) -> MediaContent.TranscriptSegment? {
        let lines = block.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        // Find the timestamp line (contains "-->")
        guard let timestampIndex = lines.firstIndex(where: { $0.contains("-->") }) else {
            return nil
        }

        let timestampLine = lines[timestampIndex]
        guard let (startMs, endMs) = parseTimestampLine(timestampLine, decimalSeparator: ",") else {
            return nil
        }

        // Text lines are everything after the timestamp
        let textLines = Array(lines[(timestampIndex + 1)...])
            .filter { !$0.isEmpty }

        guard !textLines.isEmpty else { return nil }

        let (textKr, textEn) = splitBilingualText(textLines)

        return MediaContent.TranscriptSegment(
            startMs: startMs,
            endMs: endMs,
            textKr: textKr,
            textEn: textEn
        )
    }

    private static func parseVTTBlock(_ block: String) -> MediaContent.TranscriptSegment? {
        let lines = block.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard let timestampIndex = lines.firstIndex(where: { $0.contains("-->") }) else {
            return nil
        }

        let timestampLine = lines[timestampIndex]
        guard let (startMs, endMs) = parseTimestampLine(timestampLine, decimalSeparator: ".") else {
            return nil
        }

        let textLines = Array(lines[(timestampIndex + 1)...])
            .filter { !$0.isEmpty }

        guard !textLines.isEmpty else { return nil }

        let (textKr, textEn) = splitBilingualText(textLines)

        return MediaContent.TranscriptSegment(
            startMs: startMs,
            endMs: endMs,
            textKr: textKr,
            textEn: textEn
        )
    }

    /// Parse a timestamp line like "00:01:20,500 --> 00:01:25,000" into (startMs, endMs).
    private static func parseTimestampLine(_ line: String, decimalSeparator: Character) -> (Int, Int)? {
        let parts = line.components(separatedBy: "-->")
        guard parts.count == 2 else { return nil }

        let startStr = parts[0].trimmingCharacters(in: .whitespaces)
        let endStr = parts[1].trimmingCharacters(in: .whitespaces)

        guard let startMs = parseTimestamp(startStr, decimalSeparator: decimalSeparator),
              let endMs = parseTimestamp(endStr, decimalSeparator: decimalSeparator) else {
            return nil
        }

        return (startMs, endMs)
    }

    /// Parse a single timestamp like "00:01:20,500" or "01:20.500" into milliseconds.
    /// Supports both HH:MM:SS and MM:SS formats.
    private static func parseTimestamp(_ raw: String, decimalSeparator: Character) -> Int? {
        // Strip any VTT positioning metadata (e.g., "align:start position:10%")
        let timestamp = raw.components(separatedBy: " ").first ?? raw

        let mainAndMs = timestamp.split(separator: decimalSeparator, maxSplits: 1)
        guard let mainPart = mainAndMs.first else { return nil }

        let msStr = mainAndMs.count > 1 ? String(mainAndMs[1]) : "0"
        let ms = Int(msStr.prefix(3).padding(toLength: 3, withPad: "0", startingAt: 0)) ?? 0

        let timeComponents = mainPart.split(separator: ":").compactMap { Int($0) }
        let totalSeconds: Int
        switch timeComponents.count {
        case 3: // HH:MM:SS
            totalSeconds = timeComponents[0] * 3600 + timeComponents[1] * 60 + timeComponents[2]
        case 2: // MM:SS
            totalSeconds = timeComponents[0] * 60 + timeComponents[1]
        default:
            return nil
        }

        return totalSeconds * 1000 + ms
    }

    /// Split text lines into Korean and English parts.
    /// If multiple lines, check each for Korean content.
    private static func splitBilingualText(_ lines: [String]) -> (textKr: String, textEn: String) {
        if lines.count == 1 {
            return (lines[0], "")
        }

        var koreanLines: [String] = []
        var englishLines: [String] = []

        for line in lines {
            if HangulUtilities.containsKorean(line) {
                koreanLines.append(line)
            } else {
                englishLines.append(line)
            }
        }

        // If all lines are Korean (no English detected), join them all as Korean
        if englishLines.isEmpty {
            return (lines.joined(separator: " "), "")
        }
        // If no Korean detected, treat first line as Korean (might be romanized)
        if koreanLines.isEmpty {
            return (lines.joined(separator: " "), "")
        }

        return (koreanLines.joined(separator: " "), englishLines.joined(separator: " "))
    }
}
