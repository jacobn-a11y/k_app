import XCTest
@testable import Hallyu

final class AccessibilityTests: XCTestCase {

    // MARK: - Korean Accessibility

    func testJamoDescriptionForBasicConsonants() {
        let description = KoreanAccessibility.jamoDescription("ㄱ")
        XCTAssertTrue(description.contains("giyeok"), "Should contain romanized name")
        XCTAssertTrue(description.contains("g or k"), "Should contain pronunciation hint")
    }

    func testJamoDescriptionForVowels() {
        let description = KoreanAccessibility.jamoDescription("ㅏ")
        XCTAssertTrue(description.contains("ah"), "Should contain pronunciation hint for ㅏ")
    }

    func testJamoDescriptionForUnknownCharacter() {
        let description = KoreanAccessibility.jamoDescription("A")
        XCTAssertTrue(description.contains("Korean character"), "Should return generic description for unknown character")
    }

    func testSyllableDescription() {
        let description = KoreanAccessibility.syllableDescription("한")
        XCTAssertTrue(description.contains("한"), "Should contain the original syllable")
        XCTAssertTrue(description.contains("Composed of"), "Should describe composition")
    }

    func testSyllableDescriptionForNonKorean() {
        let description = KoreanAccessibility.syllableDescription("A")
        XCTAssertEqual(description, "A", "Should return the character as-is for non-Korean")
    }

    // MARK: - Haptic Types

    func testHapticManagerDoesNotCrash() {
        // Verify that calling haptic methods doesn't crash (even in test environment)
        // These may not produce actual haptics in a test runner
        HapticManager.play(.success)
        HapticManager.play(.error)
        HapticManager.play(.warning)
        HapticManager.play(.light)
        HapticManager.play(.medium)
        HapticManager.play(.heavy)
        HapticManager.play(.selection)
    }

    func testPrepareHapticDoesNotCrash() {
        HapticManager.prepareHaptic(.success)
        HapticManager.prepareHaptic(.light)
        HapticManager.prepareHaptic(.selection)
    }

    // MARK: - Deep Link Equality

    func testDeepLinkEquality() {
        XCTAssertEqual(DeepLink.reviewSession, DeepLink.reviewSession)
        XCTAssertEqual(DeepLink.dailyPlan, DeepLink.dailyPlan)
        XCTAssertNotEqual(DeepLink.reviewSession, DeepLink.dailyPlan)

        let id = UUID()
        XCTAssertEqual(DeepLink.mediaLesson(id: id), DeepLink.mediaLesson(id: id))
        XCTAssertNotEqual(DeepLink.mediaLesson(id: id), DeepLink.mediaLesson(id: UUID()))
    }
}
