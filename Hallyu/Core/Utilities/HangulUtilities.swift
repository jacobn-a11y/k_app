import Foundation

enum HangulUtilities {
    // Unicode constants for Hangul syllable block composition
    static let syllableBase: UInt32 = 0xAC00
    static let leadBase: UInt32 = 0x1100
    static let vowelBase: UInt32 = 0x1161
    static let tailBase: UInt32 = 0x11A7
    static let vowelCount: UInt32 = 21
    static let tailCount: UInt32 = 28 // 27 finals + 1 for no final

    // Leading consonants (초성) - 19 total
    static let leadingConsonants: [Character] = [
        "ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ",
        "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"
    ]

    // Medial vowels (중성) - 21 total
    static let medialVowels: [Character] = [
        "ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ", "ㅙ",
        "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ", "ㅣ"
    ]

    // Final consonants (종성) - 27 total (+ empty)
    static let finalConsonants: [Character?] = [
        nil, "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ", "ㄻ",
        "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅁ", "ㅂ", "ㅄ", "ㅅ", "ㅆ",
        "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"
    ]

    // Approximate Revised Romanization mapping for UI hints.
    static let leadRomanization: [String] = [
        "g", "kk", "n", "d", "tt", "r", "m", "b", "pp",
        "s", "ss", "", "j", "jj", "ch", "k", "t", "p", "h"
    ]

    static let medialRomanization: [String] = [
        "a", "ae", "ya", "yae", "eo", "e", "yeo", "ye", "o", "wa", "wae",
        "oe", "yo", "u", "wo", "we", "wi", "yu", "eu", "ui", "i"
    ]

    static let finalRomanization: [String] = [
        "", "k", "k", "k", "n", "n", "n", "t", "l", "lk", "lm",
        "lp", "lt", "lt", "lp", "lh", "m", "p", "p", "t", "t",
        "ng", "t", "t", "k", "t", "p", "h"
    ]

    /// Compose a Hangul syllable from initial, medial, and optional final consonant indices.
    /// Returns nil if indices are out of range.
    static func composeSyllable(leadIndex: Int, vowelIndex: Int, tailIndex: Int = 0) -> Character? {
        guard leadIndex >= 0, leadIndex < leadingConsonants.count,
              vowelIndex >= 0, vowelIndex < medialVowels.count,
              tailIndex >= 0, tailIndex < finalConsonants.count else {
            return nil
        }

        let code = syllableBase
            + UInt32(leadIndex) * vowelCount * tailCount
            + UInt32(vowelIndex) * tailCount
            + UInt32(tailIndex)

        guard let scalar = Unicode.Scalar(code) else { return nil }
        return Character(scalar)
    }

    /// Decompose a Hangul syllable into its constituent jamo indices.
    /// Returns nil if the character is not a composed Hangul syllable.
    static func decomposeSyllable(_ char: Character) -> (leadIndex: Int, vowelIndex: Int, tailIndex: Int)? {
        guard let scalar = char.unicodeScalars.first else { return nil }
        let code = scalar.value

        guard code >= syllableBase, code < syllableBase + 11172 else { return nil }

        let offset = code - syllableBase
        let tailIndex = Int(offset % tailCount)
        let vowelIndex = Int((offset / tailCount) % vowelCount)
        let leadIndex = Int(offset / (tailCount * vowelCount))

        return (leadIndex, vowelIndex, tailIndex)
    }

    /// Check if a character is a composed Hangul syllable (가-힣)
    static func isHangulSyllable(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        return scalar.value >= syllableBase && scalar.value < syllableBase + 11172
    }

    /// Check if a character is a Hangul jamo (consonant or vowel)
    static func isHangulJamo(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        let value = scalar.value
        // Hangul Compatibility Jamo: U+3131 to U+3163
        return value >= 0x3131 && value <= 0x3163
    }

    /// Check if a string contains any Korean characters
    static func containsKorean(_ text: String) -> Bool {
        text.contains { isHangulSyllable($0) || isHangulJamo($0) }
    }

    /// Count the number of Korean characters in a string
    static func koreanCharacterCount(_ text: String) -> Int {
        text.filter { isHangulSyllable($0) || isHangulJamo($0) }.count
    }

    /// Romanize Korean text with a lightweight, readability-focused mapping.
    static func romanize(_ text: String) -> String {
        var output = ""
        output.reserveCapacity(text.count * 2)

        for character in text {
            if let parts = decomposeSyllable(character) {
                output += leadRomanization[parts.leadIndex]
                output += medialRomanization[parts.vowelIndex]
                output += finalRomanization[parts.tailIndex]
            } else if isHangulJamo(character) {
                output += romanizationForJamo(character)
            } else {
                output.append(character)
            }
        }

        return output
    }

    private static func romanizationForJamo(_ jamo: Character) -> String {
        if let leadIndex = leadingConsonants.firstIndex(of: jamo) {
            return leadRomanization[leadIndex]
        }
        if let medialIndex = medialVowels.firstIndex(of: jamo) {
            return medialRomanization[medialIndex]
        }
        if let finalIndex = finalConsonants.firstIndex(where: { $0 == jamo }) {
            return finalRomanization[finalIndex]
        }
        return String(jamo)
    }
}
