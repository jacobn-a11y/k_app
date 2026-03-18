import Testing
import Foundation
import CoreGraphics
@testable import HallyuCore

@Suite("HangulData Tests")
struct HangulDataTests {

    // MARK: - Jamo Completeness

    @Test("Has exactly 14 basic consonants")
    func basicConsonantCount() {
        #expect(HangulData.basicConsonants.count == 14)
    }

    @Test("Has exactly 10 basic vowels")
    func basicVowelCount() {
        #expect(HangulData.basicVowels.count == 10)
    }

    @Test("Has exactly 5 double consonants")
    func doubleConsonantCount() {
        #expect(HangulData.doubleConsonants.count == 5)
    }

    @Test("Has exactly 11 compound vowels")
    func compoundVowelCount() {
        #expect(HangulData.compoundVowels.count == 11)
    }

    @Test("Total jamo count is 40")
    func totalJamoCount() {
        #expect(HangulData.allJamo.count == 40)
    }

    // MARK: - Jamo Entry Validation

    @Test("All jamo have unique IDs")
    func uniqueIds() {
        let ids = HangulData.allJamo.map { $0.id }
        #expect(Set(ids).count == ids.count)
    }

    @Test("All jamo have non-empty romanization")
    func nonEmptyRomanization() {
        for jamo in HangulData.allJamo {
            #expect(!jamo.romanization.isEmpty, "Jamo \(jamo.id) has empty romanization")
        }
    }

    @Test("All jamo have non-empty IPA")
    func nonEmptyIPA() {
        for jamo in HangulData.allJamo {
            #expect(!jamo.ipa.isEmpty, "Jamo \(jamo.id) has empty IPA")
        }
    }

    @Test("All jamo have non-empty mnemonic")
    func nonEmptyMnemonic() {
        for jamo in HangulData.allJamo {
            #expect(!jamo.mnemonic.isEmpty, "Jamo \(jamo.id) has empty mnemonic")
        }
    }

    @Test("All jamo have non-empty audio file reference")
    func nonEmptyAudioRef() {
        for jamo in HangulData.allJamo {
            #expect(!jamo.audioFileRef.isEmpty, "Jamo \(jamo.id) has empty audio ref")
        }
    }

    @Test("All jamo have at least one stroke path")
    func hasStrokePaths() {
        for jamo in HangulData.allJamo {
            #expect(!jamo.strokePaths.isEmpty, "Jamo \(jamo.id) has no stroke paths")
        }
    }

    @Test("All stroke paths have at least 2 points")
    func strokePathsHavePoints() {
        for jamo in HangulData.allJamo {
            for stroke in jamo.strokePaths {
                #expect(stroke.points.count >= 2, "Jamo \(jamo.id) stroke \(stroke.order) has < 2 points")
            }
        }
    }

    @Test("All stroke path points are in 0-1 normalized range")
    func strokePointsNormalized() {
        for jamo in HangulData.allJamo {
            for stroke in jamo.strokePaths {
                for point in stroke.points {
                    #expect(point.x >= 0 && point.x <= 1, "Jamo \(jamo.id) stroke \(stroke.order) x out of range: \(point.x)")
                    #expect(point.y >= 0 && point.y <= 1, "Jamo \(jamo.id) stroke \(stroke.order) y out of range: \(point.y)")
                }
            }
        }
    }

    @Test("All jamo have at least one position rule")
    func hasPositionRules() {
        for jamo in HangulData.allJamo {
            #expect(!jamo.positionRules.isEmpty, "Jamo \(jamo.id) has no position rules")
        }
    }

    @Test("Consonants include initial position rule")
    func consonantsHaveInitialPosition() {
        for jamo in HangulData.basicConsonants {
            #expect(jamo.positionRules.contains(.initial), "Consonant \(jamo.id) missing initial position")
        }
    }

    @Test("Vowels have medial position rule")
    func vowelsHaveMedialPosition() {
        for jamo in HangulData.basicVowels {
            #expect(jamo.positionRules.contains(.medial), "Vowel \(jamo.id) missing medial position")
        }
    }

    @Test("Categories are correctly assigned")
    func correctCategories() {
        for jamo in HangulData.basicConsonants {
            #expect(jamo.category == .basicConsonant)
        }
        for jamo in HangulData.basicVowels {
            #expect(jamo.category == .basicVowel)
        }
        for jamo in HangulData.doubleConsonants {
            #expect(jamo.category == .doubleConsonant)
        }
        for jamo in HangulData.compoundVowels {
            #expect(jamo.category == .compoundVowel)
        }
    }

    // MARK: - Lesson Groups

    @Test("Has 8 lesson groups")
    func lessonGroupCount() {
        #expect(HangulData.lessonGroups.count == 8)
    }

    @Test("Lesson groups have 3-7 jamo each")
    func lessonGroupSizes() {
        for group in HangulData.lessonGroups {
            #expect(group.jamoIds.count >= 3 && group.jamoIds.count <= 7,
                    "Group \(group.id) has \(group.jamoIds.count) jamo (expected 3-7)")
        }
    }

    @Test("All jamo in lesson groups are valid")
    func lessonGroupJamoValid() {
        for group in HangulData.lessonGroups {
            for jamoId in group.jamoIds {
                #expect(HangulData.jamo(for: jamoId) != nil, "Group \(group.id) references invalid jamo: \(jamoId)")
            }
        }
    }

    @Test("All jamo belong to exactly one lesson group")
    func allJamoInGroups() {
        var allGroupJamoIds: [String] = []
        for group in HangulData.lessonGroups {
            allGroupJamoIds.append(contentsOf: group.jamoIds)
        }
        // Every jamo should be in some group
        for jamo in HangulData.allJamo {
            #expect(allGroupJamoIds.contains(jamo.id), "Jamo \(jamo.id) not in any lesson group")
        }
        // No duplicates
        #expect(Set(allGroupJamoIds).count == allGroupJamoIds.count, "Duplicate jamo in groups")
    }

    @Test("Lesson groups have unique IDs")
    func uniqueGroupIds() {
        let ids = HangulData.lessonGroups.map { $0.id }
        #expect(Set(ids).count == ids.count)
    }

    // MARK: - Jamo Lookup

    @Test("jamo(for:) returns correct entry")
    func jamoLookup() {
        let result = HangulData.jamo(for: "ㄱ")
        #expect(result?.character == "ㄱ")
        #expect(result?.romanization == "g/k")
    }

    @Test("jamo(for:) returns nil for invalid ID")
    func jamoLookupInvalid() {
        #expect(HangulData.jamo(for: "X") == nil)
    }

    // MARK: - Assembly Rules

    @Test("Assembly rules include CV and CVC patterns")
    func assemblyRules() {
        #expect(HangulData.assemblyRules.count == 2)
        let patterns = HangulData.assemblyRules.map { $0.pattern }
        #expect(patterns.contains("CV"))
        #expect(patterns.contains("CVC"))
    }
}
