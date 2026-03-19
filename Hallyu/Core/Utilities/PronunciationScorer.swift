import Foundation

struct PronunciationScore: Sendable {
    let overall: Double
    let jamoAccuracy: Double
    let prosodyAccuracy: Double
}

enum PronunciationScorer {
    /// Heuristic pronunciation score blending phoneme-level (jamo) alignment,
    /// coarse prosody/length alignment, and ASR confidence.
    static func evaluate(transcript: String, target: String, asrConfidence: Double) -> PronunciationScore {
        let transcriptJamo = jamoSequence(for: transcript)
        let targetJamo = jamoSequence(for: target)

        let jamoAccuracy = normalizedSimilarity(lhs: transcriptJamo, rhs: targetJamo)
        let prosodyAccuracy = prosodySimilarity(transcript: transcript, target: target)
        let confidence = clamp(asrConfidence)

        let overall = clamp(0.60 * jamoAccuracy + 0.25 * confidence + 0.15 * prosodyAccuracy)
        return PronunciationScore(
            overall: overall,
            jamoAccuracy: jamoAccuracy,
            prosodyAccuracy: prosodyAccuracy
        )
    }

    // MARK: - Private

    private static func jamoSequence(for text: String) -> [Character] {
        var result: [Character] = []

        for char in text {
            if let parts = HangulUtilities.decomposeSyllable(char) {
                result.append(HangulUtilities.leadingConsonants[parts.leadIndex])
                result.append(HangulUtilities.medialVowels[parts.vowelIndex])
                if parts.tailIndex > 0,
                   let tail = HangulUtilities.finalConsonants[parts.tailIndex] {
                    result.append(tail)
                }
            } else if HangulUtilities.isHangulJamo(char) {
                result.append(char)
            } else if char.isLetter || char.isNumber {
                result.append(Character(String(char).lowercased()))
            }
        }

        return result
    }

    private static func prosodySimilarity(transcript: String, target: String) -> Double {
        let transcriptSyllables = max(HangulUtilities.koreanCharacterCount(transcript), transcript.count)
        let targetSyllables = max(HangulUtilities.koreanCharacterCount(target), target.count)

        guard transcriptSyllables > 0, targetSyllables > 0 else { return 0.0 }

        let ratio = Double(min(transcriptSyllables, targetSyllables)) / Double(max(transcriptSyllables, targetSyllables))

        let transcriptTokens = transcript.split(whereSeparator: \.isWhitespace).count
        let targetTokens = target.split(whereSeparator: \.isWhitespace).count
        let tokenRatio: Double
        if transcriptTokens == 0 || targetTokens == 0 {
            tokenRatio = 1.0
        } else {
            tokenRatio = Double(min(transcriptTokens, targetTokens)) / Double(max(transcriptTokens, targetTokens))
        }

        return clamp(0.75 * ratio + 0.25 * tokenRatio)
    }

    private static func normalizedSimilarity(lhs: [Character], rhs: [Character]) -> Double {
        if lhs.isEmpty && rhs.isEmpty { return 1.0 }
        guard !lhs.isEmpty, !rhs.isEmpty else { return 0.0 }

        let distance = levenshtein(lhs, rhs)
        let normalizer = max(lhs.count, rhs.count)
        guard normalizer > 0 else { return 0.0 }

        return clamp(1.0 - (Double(distance) / Double(normalizer)))
    }

    private static func levenshtein(_ lhs: [Character], _ rhs: [Character]) -> Int {
        if lhs == rhs { return 0 }
        if lhs.isEmpty { return rhs.count }
        if rhs.isEmpty { return lhs.count }

        var previous = Array(0...rhs.count)
        var current = Array(repeating: 0, count: rhs.count + 1)

        for i in 1...lhs.count {
            current[0] = i
            for j in 1...rhs.count {
                let cost = lhs[i - 1] == rhs[j - 1] ? 0 : 1
                current[j] = min(
                    previous[j] + 1,
                    current[j - 1] + 1,
                    previous[j - 1] + cost
                )
            }
            swap(&previous, &current)
        }

        return previous[rhs.count]
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0.0), 1.0)
    }
}
