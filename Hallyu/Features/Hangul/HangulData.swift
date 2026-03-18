import Foundation
import CoreGraphics

// MARK: - Data Types

struct JamoEntry: Identifiable, Equatable {
    let id: String
    let character: Character
    let romanization: String
    let ipa: String
    let audioFileRef: String
    let strokePaths: [StrokePath]
    let mnemonic: String
    let positionRules: Set<JamoPosition>
    let category: JamoCategory
    let groupIndex: Int // which lesson group (0-7)
}

enum JamoPosition: String, Codable, CaseIterable {
    case initial  // 초성
    case medial   // 중성
    case final_   // 종성
}

enum JamoCategory: String, Codable, CaseIterable {
    case basicConsonant
    case basicVowel
    case doubleConsonant
    case compoundVowel
}

struct StrokePath: Equatable {
    let points: [CGPoint]
    let order: Int
}

struct SyllableAssemblyRule: Equatable {
    let pattern: String // "CV" or "CVC"
    let description: String
    let initialRequired: Bool
    let medialRequired: Bool
    let finalOptional: Bool
}

struct LessonGroup: Identifiable {
    let id: Int
    let name: String
    let description: String
    let jamoIds: [String]
}

// MARK: - Hangul Data

enum HangulData {

    // MARK: - Basic Consonants (14)

    static let basicConsonants: [JamoEntry] = [
        JamoEntry(
            id: "ㄱ", character: "ㄱ", romanization: "g/k", ipa: "k/ɡ",
            audioFileRef: "jamo_giyeok",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.2, y: 0.1), CGPoint(x: 0.8, y: 0.1)], order: 0),
                StrokePath(points: [CGPoint(x: 0.8, y: 0.1), CGPoint(x: 0.8, y: 0.9)], order: 1)
            ],
            mnemonic: "Gun — looks like a gun pointing right",
            positionRules: [.initial, .final_],
            category: .basicConsonant,
            groupIndex: 0
        ),
        JamoEntry(
            id: "ㄴ", character: "ㄴ", romanization: "n", ipa: "n",
            audioFileRef: "jamo_nieun",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.2, y: 0.1), CGPoint(x: 0.2, y: 0.9)], order: 0),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.9), CGPoint(x: 0.8, y: 0.9)], order: 1)
            ],
            mnemonic: "Nose — shaped like a nose in profile",
            positionRules: [.initial, .final_],
            category: .basicConsonant,
            groupIndex: 0
        ),
        JamoEntry(
            id: "ㄷ", character: "ㄷ", romanization: "d/t", ipa: "t/d",
            audioFileRef: "jamo_digeut",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.2, y: 0.1), CGPoint(x: 0.8, y: 0.1)], order: 0),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.1), CGPoint(x: 0.2, y: 0.9)], order: 1),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.9), CGPoint(x: 0.8, y: 0.9)], order: 2)
            ],
            mnemonic: "Door — like an open doorway",
            positionRules: [.initial, .final_],
            category: .basicConsonant,
            groupIndex: 0
        ),
        JamoEntry(
            id: "ㄹ", character: "ㄹ", romanization: "r/l", ipa: "ɾ/l",
            audioFileRef: "jamo_rieul",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.2, y: 0.1), CGPoint(x: 0.8, y: 0.1)], order: 0),
                StrokePath(points: [CGPoint(x: 0.8, y: 0.1), CGPoint(x: 0.8, y: 0.4)], order: 1),
                StrokePath(points: [CGPoint(x: 0.8, y: 0.4), CGPoint(x: 0.2, y: 0.4)], order: 2),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.4), CGPoint(x: 0.2, y: 0.7)], order: 3),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.7), CGPoint(x: 0.8, y: 0.7)], order: 4)
            ],
            mnemonic: "Rattlesnake — zigzag like a snake",
            positionRules: [.initial, .final_],
            category: .basicConsonant,
            groupIndex: 1
        ),
        JamoEntry(
            id: "ㅁ", character: "ㅁ", romanization: "m", ipa: "m",
            audioFileRef: "jamo_mieum",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.2, y: 0.1), CGPoint(x: 0.2, y: 0.9)], order: 0),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.9), CGPoint(x: 0.8, y: 0.9)], order: 1),
                StrokePath(points: [CGPoint(x: 0.8, y: 0.9), CGPoint(x: 0.8, y: 0.1)], order: 2),
                StrokePath(points: [CGPoint(x: 0.8, y: 0.1), CGPoint(x: 0.2, y: 0.1)], order: 3)
            ],
            mnemonic: "Mouth — square shape like an open mouth",
            positionRules: [.initial, .final_],
            category: .basicConsonant,
            groupIndex: 1
        ),
        JamoEntry(
            id: "ㅂ", character: "ㅂ", romanization: "b/p", ipa: "p/b",
            audioFileRef: "jamo_bieup",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.2, y: 0.1), CGPoint(x: 0.2, y: 0.9)], order: 0),
                StrokePath(points: [CGPoint(x: 0.8, y: 0.1), CGPoint(x: 0.8, y: 0.9)], order: 1),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.5), CGPoint(x: 0.8, y: 0.5)], order: 2),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.9), CGPoint(x: 0.8, y: 0.9)], order: 3)
            ],
            mnemonic: "Bucket — looks like a bucket with handle",
            positionRules: [.initial, .final_],
            category: .basicConsonant,
            groupIndex: 1
        ),
        JamoEntry(
            id: "ㅅ", character: "ㅅ", romanization: "s", ipa: "s/ɕ",
            audioFileRef: "jamo_siot",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.2, y: 0.9), CGPoint(x: 0.5, y: 0.1)], order: 0),
                StrokePath(points: [CGPoint(x: 0.5, y: 0.1), CGPoint(x: 0.8, y: 0.9)], order: 1)
            ],
            mnemonic: "Sun — like rays of the sun",
            positionRules: [.initial, .final_],
            category: .basicConsonant,
            groupIndex: 2
        ),
        JamoEntry(
            id: "ㅇ", character: "ㅇ", romanization: "silent/ng", ipa: "∅/ŋ",
            audioFileRef: "jamo_ieung",
            strokePaths: [
                StrokePath(points: [
                    CGPoint(x: 0.5, y: 0.1), CGPoint(x: 0.8, y: 0.3),
                    CGPoint(x: 0.8, y: 0.7), CGPoint(x: 0.5, y: 0.9),
                    CGPoint(x: 0.2, y: 0.7), CGPoint(x: 0.2, y: 0.3),
                    CGPoint(x: 0.5, y: 0.1)
                ], order: 0)
            ],
            mnemonic: "Zero — circle means zero/silent sound",
            positionRules: [.initial, .final_],
            category: .basicConsonant,
            groupIndex: 2
        ),
        JamoEntry(
            id: "ㅈ", character: "ㅈ", romanization: "j", ipa: "tɕ/dʑ",
            audioFileRef: "jamo_jieut",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.2, y: 0.6), CGPoint(x: 0.5, y: 0.1)], order: 0),
                StrokePath(points: [CGPoint(x: 0.5, y: 0.1), CGPoint(x: 0.8, y: 0.6)], order: 1),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.9), CGPoint(x: 0.8, y: 0.9)], order: 2)
            ],
            mnemonic: "Jug — like a jug sitting on a shelf",
            positionRules: [.initial, .final_],
            category: .basicConsonant,
            groupIndex: 2
        ),
        JamoEntry(
            id: "ㅊ", character: "ㅊ", romanization: "ch", ipa: "tɕʰ",
            audioFileRef: "jamo_chieut",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.5, y: 0.05), CGPoint(x: 0.5, y: 0.2)], order: 0),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.55), CGPoint(x: 0.5, y: 0.2)], order: 1),
                StrokePath(points: [CGPoint(x: 0.5, y: 0.2), CGPoint(x: 0.8, y: 0.55)], order: 2),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.9), CGPoint(x: 0.8, y: 0.9)], order: 3)
            ],
            mnemonic: "Church — ㅈ with a steeple on top",
            positionRules: [.initial, .final_],
            category: .basicConsonant,
            groupIndex: 3
        ),
        JamoEntry(
            id: "ㅋ", character: "ㅋ", romanization: "k", ipa: "kʰ",
            audioFileRef: "jamo_kieuk",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.2, y: 0.1), CGPoint(x: 0.8, y: 0.1)], order: 0),
                StrokePath(points: [CGPoint(x: 0.8, y: 0.1), CGPoint(x: 0.8, y: 0.9)], order: 1),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.5), CGPoint(x: 0.8, y: 0.5)], order: 2)
            ],
            mnemonic: "Key — ㄱ with an extra bar, like a key",
            positionRules: [.initial, .final_],
            category: .basicConsonant,
            groupIndex: 3
        ),
        JamoEntry(
            id: "ㅌ", character: "ㅌ", romanization: "t", ipa: "tʰ",
            audioFileRef: "jamo_tieut",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.2, y: 0.1), CGPoint(x: 0.8, y: 0.1)], order: 0),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.1), CGPoint(x: 0.2, y: 0.9)], order: 1),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.5), CGPoint(x: 0.8, y: 0.5)], order: 2),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.9), CGPoint(x: 0.8, y: 0.9)], order: 3)
            ],
            mnemonic: "Teeth — ㄷ with an extra line, like teeth",
            positionRules: [.initial, .final_],
            category: .basicConsonant,
            groupIndex: 3
        ),
        JamoEntry(
            id: "ㅍ", character: "ㅍ", romanization: "p", ipa: "pʰ",
            audioFileRef: "jamo_pieup",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.2, y: 0.1), CGPoint(x: 0.2, y: 0.9)], order: 0),
                StrokePath(points: [CGPoint(x: 0.8, y: 0.1), CGPoint(x: 0.8, y: 0.9)], order: 1),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.35), CGPoint(x: 0.8, y: 0.35)], order: 2),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.65), CGPoint(x: 0.8, y: 0.65)], order: 3)
            ],
            mnemonic: "Pi — looks like the Greek letter π",
            positionRules: [.initial, .final_],
            category: .basicConsonant,
            groupIndex: 4
        ),
        JamoEntry(
            id: "ㅎ", character: "ㅎ", romanization: "h", ipa: "h",
            audioFileRef: "jamo_hieut",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.5, y: 0.05), CGPoint(x: 0.5, y: 0.2)], order: 0),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.4), CGPoint(x: 0.8, y: 0.4)], order: 1),
                StrokePath(points: [
                    CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.6),
                    CGPoint(x: 0.75, y: 0.8), CGPoint(x: 0.5, y: 0.9),
                    CGPoint(x: 0.25, y: 0.8), CGPoint(x: 0.25, y: 0.6),
                    CGPoint(x: 0.5, y: 0.5)
                ], order: 2)
            ],
            mnemonic: "Hat — person wearing a hat (dot on top, brim, head)",
            positionRules: [.initial],
            category: .basicConsonant,
            groupIndex: 4
        ),
    ]

    // MARK: - Basic Vowels (10)

    static let basicVowels: [JamoEntry] = [
        JamoEntry(
            id: "ㅏ", character: "ㅏ", romanization: "a", ipa: "a",
            audioFileRef: "jamo_a",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.3, y: 0.1), CGPoint(x: 0.3, y: 0.9)], order: 0),
                StrokePath(points: [CGPoint(x: 0.3, y: 0.5), CGPoint(x: 0.7, y: 0.5)], order: 1)
            ],
            mnemonic: "Ah! — line with branch to the right, mouth opens: 'ah!'",
            positionRules: [.medial],
            category: .basicVowel,
            groupIndex: 0
        ),
        JamoEntry(
            id: "ㅓ", character: "ㅓ", romanization: "eo", ipa: "ʌ",
            audioFileRef: "jamo_eo",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.2, y: 0.5)], order: 0),
                StrokePath(points: [CGPoint(x: 0.5, y: 0.1), CGPoint(x: 0.5, y: 0.9)], order: 1)
            ],
            mnemonic: "Uh — branch to the left, sounds like 'uh'",
            positionRules: [.medial],
            category: .basicVowel,
            groupIndex: 0
        ),
        JamoEntry(
            id: "ㅗ", character: "ㅗ", romanization: "o", ipa: "o",
            audioFileRef: "jamo_o",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.5, y: 0.2)], order: 0),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.7), CGPoint(x: 0.8, y: 0.7)], order: 1)
            ],
            mnemonic: "Oh! — branch goes up, lips round upward: 'oh!'",
            positionRules: [.medial],
            category: .basicVowel,
            groupIndex: 1
        ),
        JamoEntry(
            id: "ㅜ", character: "ㅜ", romanization: "u", ipa: "u",
            audioFileRef: "jamo_u",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.2, y: 0.3), CGPoint(x: 0.8, y: 0.3)], order: 0),
                StrokePath(points: [CGPoint(x: 0.5, y: 0.3), CGPoint(x: 0.5, y: 0.8)], order: 1)
            ],
            mnemonic: "Oo — branch goes down, like an upside-down 'oh', say 'oo'",
            positionRules: [.medial],
            category: .basicVowel,
            groupIndex: 1
        ),
        JamoEntry(
            id: "ㅡ", character: "ㅡ", romanization: "eu", ipa: "ɯ",
            audioFileRef: "jamo_eu",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.1, y: 0.5), CGPoint(x: 0.9, y: 0.5)], order: 0)
            ],
            mnemonic: "Brook — flat line like the surface of a brook",
            positionRules: [.medial],
            category: .basicVowel,
            groupIndex: 2
        ),
        JamoEntry(
            id: "ㅣ", character: "ㅣ", romanization: "i", ipa: "i",
            audioFileRef: "jamo_i",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.5, y: 0.1), CGPoint(x: 0.5, y: 0.9)], order: 0)
            ],
            mnemonic: "Tree — vertical line like a tree trunk, say 'ee'",
            positionRules: [.medial],
            category: .basicVowel,
            groupIndex: 2
        ),
        JamoEntry(
            id: "ㅑ", character: "ㅑ", romanization: "ya", ipa: "ja",
            audioFileRef: "jamo_ya",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.3, y: 0.1), CGPoint(x: 0.3, y: 0.9)], order: 0),
                StrokePath(points: [CGPoint(x: 0.3, y: 0.35), CGPoint(x: 0.7, y: 0.35)], order: 1),
                StrokePath(points: [CGPoint(x: 0.3, y: 0.65), CGPoint(x: 0.7, y: 0.65)], order: 2)
            ],
            mnemonic: "Ya! — double branch ㅏ, the extra line adds 'y'",
            positionRules: [.medial],
            category: .basicVowel,
            groupIndex: 3
        ),
        JamoEntry(
            id: "ㅕ", character: "ㅕ", romanization: "yeo", ipa: "jʌ",
            audioFileRef: "jamo_yeo",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.5, y: 0.35), CGPoint(x: 0.2, y: 0.35)], order: 0),
                StrokePath(points: [CGPoint(x: 0.5, y: 0.65), CGPoint(x: 0.2, y: 0.65)], order: 1),
                StrokePath(points: [CGPoint(x: 0.5, y: 0.1), CGPoint(x: 0.5, y: 0.9)], order: 2)
            ],
            mnemonic: "Young — double branch ㅓ, extra line adds 'y'",
            positionRules: [.medial],
            category: .basicVowel,
            groupIndex: 3
        ),
        JamoEntry(
            id: "ㅛ", character: "ㅛ", romanization: "yo", ipa: "jo",
            audioFileRef: "jamo_yo",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.35, y: 0.5), CGPoint(x: 0.35, y: 0.2)], order: 0),
                StrokePath(points: [CGPoint(x: 0.65, y: 0.5), CGPoint(x: 0.65, y: 0.2)], order: 1),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.7), CGPoint(x: 0.8, y: 0.7)], order: 2)
            ],
            mnemonic: "Yo! — double branch ㅗ, extra line adds 'y'",
            positionRules: [.medial],
            category: .basicVowel,
            groupIndex: 4
        ),
        JamoEntry(
            id: "ㅠ", character: "ㅠ", romanization: "yu", ipa: "ju",
            audioFileRef: "jamo_yu",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.2, y: 0.3), CGPoint(x: 0.8, y: 0.3)], order: 0),
                StrokePath(points: [CGPoint(x: 0.35, y: 0.3), CGPoint(x: 0.35, y: 0.8)], order: 1),
                StrokePath(points: [CGPoint(x: 0.65, y: 0.3), CGPoint(x: 0.65, y: 0.8)], order: 2)
            ],
            mnemonic: "You — double branch ㅜ, extra line adds 'y'",
            positionRules: [.medial],
            category: .basicVowel,
            groupIndex: 4
        ),
    ]

    // MARK: - Double Consonants (5)

    static let doubleConsonants: [JamoEntry] = [
        JamoEntry(
            id: "ㄲ", character: "ㄲ", romanization: "kk", ipa: "k͈",
            audioFileRef: "jamo_ssanggiyeok",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.1, y: 0.1), CGPoint(x: 0.4, y: 0.1)], order: 0),
                StrokePath(points: [CGPoint(x: 0.4, y: 0.1), CGPoint(x: 0.4, y: 0.9)], order: 1),
                StrokePath(points: [CGPoint(x: 0.5, y: 0.1), CGPoint(x: 0.8, y: 0.1)], order: 2),
                StrokePath(points: [CGPoint(x: 0.8, y: 0.1), CGPoint(x: 0.8, y: 0.9)], order: 3)
            ],
            mnemonic: "Double ㄱ — tense, like cracking knuckles",
            positionRules: [.initial, .final_],
            category: .doubleConsonant,
            groupIndex: 5
        ),
        JamoEntry(
            id: "ㄸ", character: "ㄸ", romanization: "tt", ipa: "t͈",
            audioFileRef: "jamo_ssangdigeut",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.1, y: 0.1), CGPoint(x: 0.4, y: 0.1)], order: 0),
                StrokePath(points: [CGPoint(x: 0.1, y: 0.1), CGPoint(x: 0.1, y: 0.9)], order: 1),
                StrokePath(points: [CGPoint(x: 0.1, y: 0.9), CGPoint(x: 0.4, y: 0.9)], order: 2),
                StrokePath(points: [CGPoint(x: 0.5, y: 0.1), CGPoint(x: 0.8, y: 0.1)], order: 3),
                StrokePath(points: [CGPoint(x: 0.5, y: 0.1), CGPoint(x: 0.5, y: 0.9)], order: 4),
                StrokePath(points: [CGPoint(x: 0.5, y: 0.9), CGPoint(x: 0.8, y: 0.9)], order: 5)
            ],
            mnemonic: "Double ㄷ — tense, tongue pressed hard",
            positionRules: [.initial],
            category: .doubleConsonant,
            groupIndex: 5
        ),
        JamoEntry(
            id: "ㅃ", character: "ㅃ", romanization: "pp", ipa: "p͈",
            audioFileRef: "jamo_ssangbieup",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.1, y: 0.1), CGPoint(x: 0.1, y: 0.9)], order: 0),
                StrokePath(points: [CGPoint(x: 0.35, y: 0.1), CGPoint(x: 0.35, y: 0.9)], order: 1),
                StrokePath(points: [CGPoint(x: 0.1, y: 0.5), CGPoint(x: 0.35, y: 0.5)], order: 2),
                StrokePath(points: [CGPoint(x: 0.1, y: 0.9), CGPoint(x: 0.35, y: 0.9)], order: 3),
                StrokePath(points: [CGPoint(x: 0.5, y: 0.1), CGPoint(x: 0.5, y: 0.9)], order: 4),
                StrokePath(points: [CGPoint(x: 0.75, y: 0.1), CGPoint(x: 0.75, y: 0.9)], order: 5),
                StrokePath(points: [CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.5)], order: 6),
                StrokePath(points: [CGPoint(x: 0.5, y: 0.9), CGPoint(x: 0.75, y: 0.9)], order: 7)
            ],
            mnemonic: "Double ㅂ — tense, lips pressed tightly",
            positionRules: [.initial],
            category: .doubleConsonant,
            groupIndex: 5
        ),
        JamoEntry(
            id: "ㅆ", character: "ㅆ", romanization: "ss", ipa: "s͈",
            audioFileRef: "jamo_ssangsiot",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.1, y: 0.9), CGPoint(x: 0.3, y: 0.1)], order: 0),
                StrokePath(points: [CGPoint(x: 0.3, y: 0.1), CGPoint(x: 0.45, y: 0.9)], order: 1),
                StrokePath(points: [CGPoint(x: 0.55, y: 0.9), CGPoint(x: 0.7, y: 0.1)], order: 2),
                StrokePath(points: [CGPoint(x: 0.7, y: 0.1), CGPoint(x: 0.9, y: 0.9)], order: 3)
            ],
            mnemonic: "Double ㅅ — sharp hiss, like a snake",
            positionRules: [.initial, .final_],
            category: .doubleConsonant,
            groupIndex: 5
        ),
        JamoEntry(
            id: "ㅉ", character: "ㅉ", romanization: "jj", ipa: "tɕ͈",
            audioFileRef: "jamo_ssangjieut",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.1, y: 0.6), CGPoint(x: 0.25, y: 0.1)], order: 0),
                StrokePath(points: [CGPoint(x: 0.25, y: 0.1), CGPoint(x: 0.4, y: 0.6)], order: 1),
                StrokePath(points: [CGPoint(x: 0.1, y: 0.9), CGPoint(x: 0.4, y: 0.9)], order: 2),
                StrokePath(points: [CGPoint(x: 0.55, y: 0.6), CGPoint(x: 0.7, y: 0.1)], order: 3),
                StrokePath(points: [CGPoint(x: 0.7, y: 0.1), CGPoint(x: 0.85, y: 0.6)], order: 4),
                StrokePath(points: [CGPoint(x: 0.55, y: 0.9), CGPoint(x: 0.85, y: 0.9)], order: 5)
            ],
            mnemonic: "Double ㅈ — tense, like 'jj' in hajj",
            positionRules: [.initial],
            category: .doubleConsonant,
            groupIndex: 5
        ),
    ]

    // MARK: - Compound Vowels (11)

    static let compoundVowels: [JamoEntry] = [
        JamoEntry(
            id: "ㅐ", character: "ㅐ", romanization: "ae", ipa: "ɛ",
            audioFileRef: "jamo_ae",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.2, y: 0.1), CGPoint(x: 0.2, y: 0.9)], order: 0),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.5), CGPoint(x: 0.5, y: 0.5)], order: 1),
                StrokePath(points: [CGPoint(x: 0.6, y: 0.1), CGPoint(x: 0.6, y: 0.9)], order: 2)
            ],
            mnemonic: "ㅏ + ㅣ combined — sounds like 'eh'",
            positionRules: [.medial],
            category: .compoundVowel,
            groupIndex: 6
        ),
        JamoEntry(
            id: "ㅔ", character: "ㅔ", romanization: "e", ipa: "e",
            audioFileRef: "jamo_e",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.4, y: 0.5), CGPoint(x: 0.1, y: 0.5)], order: 0),
                StrokePath(points: [CGPoint(x: 0.4, y: 0.1), CGPoint(x: 0.4, y: 0.9)], order: 1),
                StrokePath(points: [CGPoint(x: 0.7, y: 0.1), CGPoint(x: 0.7, y: 0.9)], order: 2)
            ],
            mnemonic: "ㅓ + ㅣ combined — sounds like 'eh' (nearly same as ㅐ)",
            positionRules: [.medial],
            category: .compoundVowel,
            groupIndex: 6
        ),
        JamoEntry(
            id: "ㅒ", character: "ㅒ", romanization: "yae", ipa: "jɛ",
            audioFileRef: "jamo_yae",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.2, y: 0.1), CGPoint(x: 0.2, y: 0.9)], order: 0),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.35), CGPoint(x: 0.5, y: 0.35)], order: 1),
                StrokePath(points: [CGPoint(x: 0.2, y: 0.65), CGPoint(x: 0.5, y: 0.65)], order: 2),
                StrokePath(points: [CGPoint(x: 0.65, y: 0.1), CGPoint(x: 0.65, y: 0.9)], order: 3)
            ],
            mnemonic: "ㅑ + ㅣ — 'yeh' sound",
            positionRules: [.medial],
            category: .compoundVowel,
            groupIndex: 6
        ),
        JamoEntry(
            id: "ㅖ", character: "ㅖ", romanization: "ye", ipa: "je",
            audioFileRef: "jamo_ye",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.4, y: 0.35), CGPoint(x: 0.1, y: 0.35)], order: 0),
                StrokePath(points: [CGPoint(x: 0.4, y: 0.65), CGPoint(x: 0.1, y: 0.65)], order: 1),
                StrokePath(points: [CGPoint(x: 0.4, y: 0.1), CGPoint(x: 0.4, y: 0.9)], order: 2),
                StrokePath(points: [CGPoint(x: 0.7, y: 0.1), CGPoint(x: 0.7, y: 0.9)], order: 3)
            ],
            mnemonic: "ㅕ + ㅣ — 'yeh' sound",
            positionRules: [.medial],
            category: .compoundVowel,
            groupIndex: 6
        ),
        JamoEntry(
            id: "ㅘ", character: "ㅘ", romanization: "wa", ipa: "wa",
            audioFileRef: "jamo_wa",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.3, y: 0.35), CGPoint(x: 0.3, y: 0.1)], order: 0),
                StrokePath(points: [CGPoint(x: 0.1, y: 0.55), CGPoint(x: 0.5, y: 0.55)], order: 1),
                StrokePath(points: [CGPoint(x: 0.65, y: 0.1), CGPoint(x: 0.65, y: 0.9)], order: 2),
                StrokePath(points: [CGPoint(x: 0.65, y: 0.5), CGPoint(x: 0.9, y: 0.5)], order: 3)
            ],
            mnemonic: "ㅗ + ㅏ — 'wa' as in 'waffle'",
            positionRules: [.medial],
            category: .compoundVowel,
            groupIndex: 7
        ),
        JamoEntry(
            id: "ㅙ", character: "ㅙ", romanization: "wae", ipa: "wɛ",
            audioFileRef: "jamo_wae",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.25, y: 0.35), CGPoint(x: 0.25, y: 0.1)], order: 0),
                StrokePath(points: [CGPoint(x: 0.05, y: 0.55), CGPoint(x: 0.45, y: 0.55)], order: 1),
                StrokePath(points: [CGPoint(x: 0.55, y: 0.1), CGPoint(x: 0.55, y: 0.9)], order: 2),
                StrokePath(points: [CGPoint(x: 0.55, y: 0.5), CGPoint(x: 0.75, y: 0.5)], order: 3),
                StrokePath(points: [CGPoint(x: 0.85, y: 0.1), CGPoint(x: 0.85, y: 0.9)], order: 4)
            ],
            mnemonic: "ㅗ + ㅐ — 'weh' sound",
            positionRules: [.medial],
            category: .compoundVowel,
            groupIndex: 7
        ),
        JamoEntry(
            id: "ㅚ", character: "ㅚ", romanization: "oe", ipa: "we",
            audioFileRef: "jamo_oe",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.3, y: 0.35), CGPoint(x: 0.3, y: 0.1)], order: 0),
                StrokePath(points: [CGPoint(x: 0.1, y: 0.55), CGPoint(x: 0.5, y: 0.55)], order: 1),
                StrokePath(points: [CGPoint(x: 0.7, y: 0.1), CGPoint(x: 0.7, y: 0.9)], order: 2)
            ],
            mnemonic: "ㅗ + ㅣ — 'weh' sound (like 'wet' without the t)",
            positionRules: [.medial],
            category: .compoundVowel,
            groupIndex: 7
        ),
        JamoEntry(
            id: "ㅝ", character: "ㅝ", romanization: "wo", ipa: "wʌ",
            audioFileRef: "jamo_wo",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.1, y: 0.3), CGPoint(x: 0.5, y: 0.3)], order: 0),
                StrokePath(points: [CGPoint(x: 0.3, y: 0.3), CGPoint(x: 0.3, y: 0.7)], order: 1),
                StrokePath(points: [CGPoint(x: 0.65, y: 0.5), CGPoint(x: 0.5, y: 0.5)], order: 2),
                StrokePath(points: [CGPoint(x: 0.65, y: 0.1), CGPoint(x: 0.65, y: 0.9)], order: 3)
            ],
            mnemonic: "ㅜ + ㅓ — 'wuh' sound",
            positionRules: [.medial],
            category: .compoundVowel,
            groupIndex: 7
        ),
        JamoEntry(
            id: "ㅞ", character: "ㅞ", romanization: "we", ipa: "we",
            audioFileRef: "jamo_we",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.05, y: 0.3), CGPoint(x: 0.4, y: 0.3)], order: 0),
                StrokePath(points: [CGPoint(x: 0.25, y: 0.3), CGPoint(x: 0.25, y: 0.7)], order: 1),
                StrokePath(points: [CGPoint(x: 0.55, y: 0.5), CGPoint(x: 0.4, y: 0.5)], order: 2),
                StrokePath(points: [CGPoint(x: 0.55, y: 0.1), CGPoint(x: 0.55, y: 0.9)], order: 3),
                StrokePath(points: [CGPoint(x: 0.8, y: 0.1), CGPoint(x: 0.8, y: 0.9)], order: 4)
            ],
            mnemonic: "ㅜ + ㅔ — 'weh' sound",
            positionRules: [.medial],
            category: .compoundVowel,
            groupIndex: 7
        ),
        JamoEntry(
            id: "ㅟ", character: "ㅟ", romanization: "wi", ipa: "wi",
            audioFileRef: "jamo_wi",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.1, y: 0.3), CGPoint(x: 0.5, y: 0.3)], order: 0),
                StrokePath(points: [CGPoint(x: 0.3, y: 0.3), CGPoint(x: 0.3, y: 0.7)], order: 1),
                StrokePath(points: [CGPoint(x: 0.7, y: 0.1), CGPoint(x: 0.7, y: 0.9)], order: 2)
            ],
            mnemonic: "ㅜ + ㅣ — 'wee' sound",
            positionRules: [.medial],
            category: .compoundVowel,
            groupIndex: 7
        ),
        JamoEntry(
            id: "ㅢ", character: "ㅢ", romanization: "ui", ipa: "ɰi",
            audioFileRef: "jamo_ui",
            strokePaths: [
                StrokePath(points: [CGPoint(x: 0.1, y: 0.5), CGPoint(x: 0.5, y: 0.5)], order: 0),
                StrokePath(points: [CGPoint(x: 0.7, y: 0.1), CGPoint(x: 0.7, y: 0.9)], order: 1)
            ],
            mnemonic: "ㅡ + ㅣ — 'euee' glide from flat to 'ee'",
            positionRules: [.medial],
            category: .compoundVowel,
            groupIndex: 7
        ),
    ]

    // MARK: - All Jamo (combined)

    static let allJamo: [JamoEntry] = basicConsonants + basicVowels + doubleConsonants + compoundVowels

    static func jamo(for id: String) -> JamoEntry? {
        allJamo.first { $0.id == id }
    }

    // MARK: - Lesson Groups (8 groups)

    static let lessonGroups: [LessonGroup] = [
        LessonGroup(
            id: 0,
            name: "First Sounds",
            description: "Common consonants ㄱㄴㄷ and vowels ㅏㅓ",
            jamoIds: ["ㄱ", "ㄴ", "ㄷ", "ㅏ", "ㅓ"]
        ),
        LessonGroup(
            id: 1,
            name: "Building Blocks",
            description: "More consonants ㄹㅁㅂ and vowels ㅗㅜ",
            jamoIds: ["ㄹ", "ㅁ", "ㅂ", "ㅗ", "ㅜ"]
        ),
        LessonGroup(
            id: 2,
            name: "Sibilants & Essentials",
            description: "ㅅㅇㅈ and vowels ㅡㅣ",
            jamoIds: ["ㅅ", "ㅇ", "ㅈ", "ㅡ", "ㅣ"]
        ),
        LessonGroup(
            id: 3,
            name: "Aspirated Sounds",
            description: "Breathy consonants ㅊㅋㅌ and y-vowels ㅑㅕ",
            jamoIds: ["ㅊ", "ㅋ", "ㅌ", "ㅑ", "ㅕ"]
        ),
        LessonGroup(
            id: 4,
            name: "Final Basics",
            description: "Last basic consonants ㅍㅎ and y-vowels ㅛㅠ",
            jamoIds: ["ㅍ", "ㅎ", "ㅛ", "ㅠ"]
        ),
        LessonGroup(
            id: 5,
            name: "Double Consonants",
            description: "Tense sounds ㄲㄸㅃㅆㅉ",
            jamoIds: ["ㄲ", "ㄸ", "ㅃ", "ㅆ", "ㅉ"]
        ),
        LessonGroup(
            id: 6,
            name: "Compound Vowels I",
            description: "Diphthongs ㅐㅔㅒㅖ",
            jamoIds: ["ㅐ", "ㅔ", "ㅒ", "ㅖ"]
        ),
        LessonGroup(
            id: 7,
            name: "Compound Vowels II",
            description: "W-glides ㅘㅙㅚㅝㅞㅟㅢ",
            jamoIds: ["ㅘ", "ㅙ", "ㅚ", "ㅝ", "ㅞ", "ㅟ", "ㅢ"]
        ),
    ]

    // MARK: - Syllable Assembly Rules

    static let assemblyRules: [SyllableAssemblyRule] = [
        SyllableAssemblyRule(
            pattern: "CV",
            description: "Consonant + Vowel (e.g., 가, 나, 도)",
            initialRequired: true,
            medialRequired: true,
            finalOptional: true
        ),
        SyllableAssemblyRule(
            pattern: "CVC",
            description: "Consonant + Vowel + Consonant (e.g., 한, 글, 말)",
            initialRequired: true,
            medialRequired: true,
            finalOptional: false
        ),
    ]
}
