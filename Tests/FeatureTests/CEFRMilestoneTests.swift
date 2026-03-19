import XCTest
@testable import HallyuCore

final class CEFRMilestoneTests: XCTestCase {

    // MARK: - Milestone Unlock Logic

    func testPreA1MilestoneUnlocksWhenHangulMastered() {
        let breakdowns = [
            SkillBreakdown(skillType: "hangul_recognition", displayName: "Reading", accuracy: 0.9, attempts: 50),
            SkillBreakdown(skillType: "hangul_production", displayName: "Writing", accuracy: 0.7, attempts: 30),
        ]

        let milestones = CEFRMilestoneData.allMilestones(skillBreakdowns: breakdowns)
        let preA1 = milestones.first { $0.id == "preA1" }

        XCTAssertNotNil(preA1)
        XCTAssertTrue(preA1!.isUnlocked)
        XCTAssertEqual(preA1!.progress, 1.0)
    }

    func testPreA1MilestoneLockedWhenHangulNotMastered() {
        let breakdowns = [
            SkillBreakdown(skillType: "hangul_recognition", displayName: "Reading", accuracy: 0.5, attempts: 10),
            SkillBreakdown(skillType: "hangul_production", displayName: "Writing", accuracy: 0.3, attempts: 5),
        ]

        let milestones = CEFRMilestoneData.allMilestones(skillBreakdowns: breakdowns)
        let preA1 = milestones.first { $0.id == "preA1" }

        XCTAssertNotNil(preA1)
        XCTAssertFalse(preA1!.isUnlocked)
    }

    func testA1GreetingsMilestoneUnlockLogic() {
        let breakdowns = [
            SkillBreakdown(skillType: "vocab_recognition", displayName: "Vocabulary", accuracy: 0.6, attempts: 40),
            SkillBreakdown(skillType: "listening", displayName: "Listening", accuracy: 0.35, attempts: 20),
        ]

        let milestones = CEFRMilestoneData.allMilestones(skillBreakdowns: breakdowns)
        let a1Greetings = milestones.first { $0.id == "a1_greetings" }

        XCTAssertNotNil(a1Greetings)
        XCTAssertTrue(a1Greetings!.isUnlocked)
    }

    func testB2MilestoneRequiresHighMastery() {
        let breakdowns = [
            SkillBreakdown(skillType: "listening", displayName: "Listening", accuracy: 0.7, attempts: 100),
            SkillBreakdown(skillType: "vocab_recognition", displayName: "Vocabulary", accuracy: 0.8, attempts: 100),
            SkillBreakdown(skillType: "grammar", displayName: "Grammar", accuracy: 0.7, attempts: 100),
            SkillBreakdown(skillType: "pronunciation", displayName: "Pronunciation", accuracy: 0.6, attempts: 100),
        ]

        let milestones = CEFRMilestoneData.allMilestones(skillBreakdowns: breakdowns)
        let b2 = milestones.first { $0.id == "b2_nosubs" }

        XCTAssertNotNil(b2)
        XCTAssertFalse(b2!.isUnlocked) // None meet the B2 threshold
    }

    func testB2MilestoneUnlocksAtHighMastery() {
        let breakdowns = [
            SkillBreakdown(skillType: "listening", displayName: "Listening", accuracy: 0.9, attempts: 200),
            SkillBreakdown(skillType: "vocab_recognition", displayName: "Vocabulary", accuracy: 0.95, attempts: 200),
            SkillBreakdown(skillType: "grammar", displayName: "Grammar", accuracy: 0.85, attempts: 200),
            SkillBreakdown(skillType: "pronunciation", displayName: "Pronunciation", accuracy: 0.75, attempts: 200),
        ]

        let milestones = CEFRMilestoneData.allMilestones(skillBreakdowns: breakdowns)
        let b2 = milestones.first { $0.id == "b2_nosubs" }

        XCTAssertNotNil(b2)
        XCTAssertTrue(b2!.isUnlocked)
    }

    // MARK: - Progress Calculation

    func testMilestoneProgressPartial() {
        let breakdowns = [
            SkillBreakdown(skillType: "hangul_recognition", displayName: "Reading", accuracy: 0.9, attempts: 50),
            SkillBreakdown(skillType: "hangul_production", displayName: "Writing", accuracy: 0.3, attempts: 10),
        ]

        let milestones = CEFRMilestoneData.allMilestones(skillBreakdowns: breakdowns)
        let preA1 = milestones.first { $0.id == "preA1" }

        XCTAssertNotNil(preA1)
        XCTAssertFalse(preA1!.isUnlocked)
        XCTAssertEqual(preA1!.progress, 0.5) // 1 of 2 requirements met
    }

    // MARK: - All Milestones Exist

    func testAllMilestonesAreGenerated() {
        let milestones = CEFRMilestoneData.allMilestones(skillBreakdowns: [])

        // We expect 8 milestones total
        XCTAssertEqual(milestones.count, 8)

        // Check all CEFR levels have at least 1 milestone
        let levels = Set(milestones.map { $0.level })
        XCTAssertTrue(levels.contains(.preA1))
        XCTAssertTrue(levels.contains(.a1))
        XCTAssertTrue(levels.contains(.a2))
        XCTAssertTrue(levels.contains(.b1))
        XCTAssertTrue(levels.contains(.b2))
    }

    func testMilestoneIdsAreUnique() {
        let milestones = CEFRMilestoneData.allMilestones(skillBreakdowns: [])
        let ids = milestones.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    // MARK: - Empty Skills

    func testAllMilestonesLockedWithNoSkills() {
        let milestones = CEFRMilestoneData.allMilestones(skillBreakdowns: [])

        for milestone in milestones {
            XCTAssertFalse(milestone.isUnlocked, "Milestone \(milestone.id) should be locked with no skills")
            XCTAssertEqual(milestone.progress, 0.0)
        }
    }

    // MARK: - MilestoneRequirement

    func testRequirementIsMet() {
        let req = MilestoneRequirement(id: "test", skillType: "listening", threshold: 0.5, currentValue: 0.6, description: "Test")
        XCTAssertTrue(req.isMet)
    }

    func testRequirementIsNotMet() {
        let req = MilestoneRequirement(id: "test", skillType: "listening", threshold: 0.5, currentValue: 0.3, description: "Test")
        XCTAssertFalse(req.isMet)
    }

    func testRequirementMetAtExactThreshold() {
        let req = MilestoneRequirement(id: "test", skillType: "listening", threshold: 0.5, currentValue: 0.5, description: "Test")
        XCTAssertTrue(req.isMet)
    }
}
