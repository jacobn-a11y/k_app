import Testing
import Foundation
@testable import HallyuCore

@Suite("HangulUtilities Tests")
struct HangulUtilitiesTests {

    // MARK: - Syllable Composition

    @Test("Compose 가 (ga) from ㄱ + ㅏ")
    func composeGa() {
        let char = HangulUtilities.composeSyllable(leadIndex: 0, vowelIndex: 0)
        #expect(char == "가")
    }

    @Test("Compose 한 (han) from ㅎ + ㅏ + ㄴ")
    func composeHan() {
        // ㅎ is index 18, ㅏ is index 0, ㄴ is finalConsonant index 4
        let char = HangulUtilities.composeSyllable(leadIndex: 18, vowelIndex: 0, tailIndex: 4)
        #expect(char == "한")
    }

    @Test("Compose 글 (geul) from ㄱ + ㅡ + ㄹ")
    func composeGeul() {
        // ㄱ=0, ㅡ=18, ㄹ=8
        let char = HangulUtilities.composeSyllable(leadIndex: 0, vowelIndex: 18, tailIndex: 8)
        #expect(char == "글")
    }

    @Test("Invalid lead index returns nil")
    func invalidLeadIndex() {
        let char = HangulUtilities.composeSyllable(leadIndex: 99, vowelIndex: 0)
        #expect(char == nil)
    }

    @Test("Invalid vowel index returns nil")
    func invalidVowelIndex() {
        let char = HangulUtilities.composeSyllable(leadIndex: 0, vowelIndex: 99)
        #expect(char == nil)
    }

    @Test("Negative index returns nil")
    func negativeIndex() {
        let char = HangulUtilities.composeSyllable(leadIndex: -1, vowelIndex: 0)
        #expect(char == nil)
    }

    // MARK: - Syllable Decomposition

    @Test("Decompose 가 into ㄱ + ㅏ")
    func decomposeGa() {
        let result = HangulUtilities.decomposeSyllable("가")
        #expect(result?.leadIndex == 0)
        #expect(result?.vowelIndex == 0)
        #expect(result?.tailIndex == 0)
    }

    @Test("Decompose 한 into ㅎ + ㅏ + ㄴ")
    func decomposeHan() {
        let result = HangulUtilities.decomposeSyllable("한")
        #expect(result?.leadIndex == 18)
        #expect(result?.vowelIndex == 0)
        #expect(result?.tailIndex == 4)
    }

    @Test("Decompose non-Hangul returns nil")
    func decomposeNonHangul() {
        let result = HangulUtilities.decomposeSyllable("A")
        #expect(result == nil)
    }

    @Test("Roundtrip compose/decompose")
    func roundtripComposeDecompose() {
        // Compose, then decompose, should get the same indices
        for lead in 0..<19 {
            for vowel in stride(from: 0, to: 21, by: 7) {
                guard let char = HangulUtilities.composeSyllable(leadIndex: lead, vowelIndex: vowel) else {
                    Issue.record("Failed to compose syllable at lead=\(lead), vowel=\(vowel)")
                    continue
                }
                let result = HangulUtilities.decomposeSyllable(char)
                #expect(result?.leadIndex == lead)
                #expect(result?.vowelIndex == vowel)
                #expect(result?.tailIndex == 0)
            }
        }
    }

    // MARK: - Character Detection

    @Test("isHangulSyllable detects composed syllables")
    func detectSyllable() {
        #expect(HangulUtilities.isHangulSyllable("가") == true)
        #expect(HangulUtilities.isHangulSyllable("힣") == true)
        #expect(HangulUtilities.isHangulSyllable("A") == false)
        #expect(HangulUtilities.isHangulSyllable("1") == false)
    }

    @Test("isHangulJamo detects jamo characters")
    func detectJamo() {
        #expect(HangulUtilities.isHangulJamo("ㄱ") == true)
        #expect(HangulUtilities.isHangulJamo("ㅏ") == true)
        #expect(HangulUtilities.isHangulJamo("A") == false)
    }

    @Test("containsKorean detects Korean in mixed text")
    func containsKorean() {
        #expect(HangulUtilities.containsKorean("Hello 안녕") == true)
        #expect(HangulUtilities.containsKorean("Hello World") == false)
        #expect(HangulUtilities.containsKorean("ㄱ test") == true)
    }

    @Test("koreanCharacterCount counts correctly")
    func koreanCount() {
        #expect(HangulUtilities.koreanCharacterCount("안녕하세요") == 5)
        #expect(HangulUtilities.koreanCharacterCount("Hello 안녕") == 2)
        #expect(HangulUtilities.koreanCharacterCount("English only") == 0)
    }
}
