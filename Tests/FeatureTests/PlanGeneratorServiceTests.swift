import Testing
import Foundation
@testable import HallyuCore

@Suite("PlanGeneratorService Tests")
struct PlanGeneratorServiceTests {

    private let generator = PlanGeneratorService()
    private let userId = UUID()

    // MARK: - Helpers

    private func makeProfile(
        cefrLevel: String = "A1",
        dailyGoalMinutes: Int = 15,
        hangulCompleted: Bool = true
    ) -> LearnerProfile {
        LearnerProfile(
            userId: userId,
            cefrLevel: cefrLevel,
            hangulCompleted: hangulCompleted,
            dailyGoalMinutes: dailyGoalMinutes
        )
    }

    private func makeDueItems(count: Int) -> [ReviewItem] {
        (0..<count).map { _ in
            ReviewItem(
                userId: userId,
                itemType: "vocabulary",
                itemId: UUID(),
                nextReviewAt: Date().addingTimeInterval(-3600)
            )
        }
    }

    private func makeMedia(count: Int = 5, difficulty: Double = 0.5, cefrLevel: String = "A1") -> [MediaContent] {
        (0..<count).map { i in
            MediaContent(
                title: "Media \(i + 1)",
                contentType: "drama",
                difficultyScore: difficulty,
                cefrLevel: cefrLevel,
                durationSeconds: 180
            )
        }
    }

    private func makeSkillMasteries(pronunciation: Double = 0.6, vocab: Double = 0.5, grammar: Double = 0.5) -> [SkillMastery] {
        [
            SkillMastery(userId: userId, skillType: "pronunciation", skillId: "general", accuracy: pronunciation, attempts: 10),
            SkillMastery(userId: userId, skillType: "vocab_recognition", skillId: "general", accuracy: vocab, attempts: 10),
            SkillMastery(userId: userId, skillType: "grammar", skillId: "general", accuracy: grammar, attempts: 10),
        ]
    }

    // MARK: - Basic Plan Generation

    @Test("Generates non-empty plan for active learner")
    func generatesPlan() {
        let plan = generator.generatePlan(
            profile: makeProfile(),
            dueReviewItems: makeDueItems(count: 5),
            availableMedia: makeMedia(),
            skillMasteries: makeSkillMasteries(),
            todaySessions: []
        )
        #expect(!plan.activities.isEmpty)
        #expect(plan.totalMinutes > 0)
        #expect(plan.totalMinutes <= makeProfile().dailyGoalMinutes)
    }

    @Test("Plan respects daily goal minutes")
    func respectsGoal() {
        let plan = generator.generatePlan(
            profile: makeProfile(dailyGoalMinutes: 15),
            dueReviewItems: makeDueItems(count: 20),
            availableMedia: makeMedia(count: 10),
            skillMasteries: makeSkillMasteries(),
            todaySessions: []
        )
        #expect(plan.totalMinutes <= 15)
        #expect(plan.goalMinutes == 15)
    }

    @Test("Larger goal produces more activities")
    func largerGoalMoreActivities() {
        let smallPlan = generator.generatePlan(
            profile: makeProfile(dailyGoalMinutes: 10),
            dueReviewItems: makeDueItems(count: 5),
            availableMedia: makeMedia(),
            skillMasteries: makeSkillMasteries(),
            todaySessions: []
        )
        let largePlan = generator.generatePlan(
            profile: makeProfile(dailyGoalMinutes: 30),
            dueReviewItems: makeDueItems(count: 5),
            availableMedia: makeMedia(),
            skillMasteries: makeSkillMasteries(),
            todaySessions: []
        )
        #expect(largePlan.totalMinutes >= smallPlan.totalMinutes)
    }

    // MARK: - SRS Review Priority

    @Test("Due review items are scheduled first")
    func reviewFirst() {
        let plan = generator.generatePlan(
            profile: makeProfile(),
            dueReviewItems: makeDueItems(count: 5),
            availableMedia: makeMedia(),
            skillMasteries: makeSkillMasteries(),
            todaySessions: []
        )
        guard let first = plan.activities.first else {
            Issue.record("Plan should have activities")
            return
        }
        #expect(first.type == .srsReview)
    }

    @Test("No review activity when no items are due")
    func noReviewWhenEmpty() {
        let plan = generator.generatePlan(
            profile: makeProfile(),
            dueReviewItems: [],
            availableMedia: makeMedia(),
            skillMasteries: makeSkillMasteries(),
            todaySessions: []
        )
        let hasReview = plan.activities.contains { $0.type == .srsReview }
        #expect(!hasReview)
    }

    @Test("Review activity shows item count")
    func reviewItemCount() {
        let plan = generator.generatePlan(
            profile: makeProfile(dailyGoalMinutes: 30),
            dueReviewItems: makeDueItems(count: 7),
            availableMedia: makeMedia(),
            skillMasteries: makeSkillMasteries(),
            todaySessions: []
        )
        let reviewActivity = plan.activities.first { $0.type == .srsReview }
        #expect(reviewActivity?.reviewItemCount == 7)
    }

    // MARK: - Beginner Path (Hangul)

    @Test("Beginner gets Hangul lesson when not completed")
    func beginnerGetsHangul() {
        let plan = generator.generatePlan(
            profile: makeProfile(cefrLevel: "pre-A1", dailyGoalMinutes: 20, hangulCompleted: false),
            dueReviewItems: [],
            availableMedia: makeMedia(),
            skillMasteries: makeSkillMasteries(),
            todaySessions: []
        )
        let hasHangul = plan.activities.contains { $0.type == .hangulLesson }
        #expect(hasHangul)
    }

    @Test("No Hangul lesson when already completed")
    func noHangulWhenCompleted() {
        let plan = generator.generatePlan(
            profile: makeProfile(hangulCompleted: true),
            dueReviewItems: [],
            availableMedia: makeMedia(),
            skillMasteries: makeSkillMasteries(),
            todaySessions: []
        )
        let hasHangul = plan.activities.contains { $0.type == .hangulLesson }
        #expect(!hasHangul)
    }

    // MARK: - Media Lesson Selection

    @Test("Plan includes media lesson when time allows")
    func includesMediaLesson() {
        let plan = generator.generatePlan(
            profile: makeProfile(dailyGoalMinutes: 20),
            dueReviewItems: [],
            availableMedia: makeMedia(),
            skillMasteries: makeSkillMasteries(),
            todaySessions: []
        )
        let hasMedia = plan.activities.contains { $0.type == .mediaLesson }
        #expect(hasMedia)
    }

    @Test("No media lesson when no content available")
    func noMediaWhenEmpty() {
        let plan = generator.generatePlan(
            profile: makeProfile(dailyGoalMinutes: 20),
            dueReviewItems: [],
            availableMedia: [],
            skillMasteries: makeSkillMasteries(),
            todaySessions: []
        )
        let hasMedia = plan.activities.contains { $0.type == .mediaLesson }
        #expect(!hasMedia)
    }

    @Test("Media lesson selects content near ideal difficulty")
    func selectsIdealDifficulty() {
        let easyMedia = makeMedia(count: 2, difficulty: 0.1, cefrLevel: "A1")
        let idealMedia = makeMedia(count: 2, difficulty: 0.5, cefrLevel: "A1")
        let hardMedia = makeMedia(count: 2, difficulty: 0.9, cefrLevel: "A1")
        let allMedia = easyMedia + idealMedia + hardMedia

        let plan = generator.generatePlan(
            profile: makeProfile(dailyGoalMinutes: 20),
            dueReviewItems: [],
            availableMedia: allMedia,
            skillMasteries: makeSkillMasteries(),
            todaySessions: []
        )
        let mediaActivity = plan.activities.first { $0.type == .mediaLesson }
        // Should select one of the ideal difficulty media
        #expect(mediaActivity != nil)
        if let contentId = mediaActivity?.mediaContentId {
            let selected = allMedia.first { $0.id == contentId }
            #expect(selected != nil)
            #expect(selected!.difficultyScore >= 0.3)
            #expect(selected!.difficultyScore <= 0.7)
        }
    }

    // MARK: - Pronunciation Practice

    @Test("Pronunciation practice added when mastery is low")
    func pronunciationWhenLow() {
        let plan = generator.generatePlan(
            profile: makeProfile(dailyGoalMinutes: 30),
            dueReviewItems: [],
            availableMedia: makeMedia(),
            skillMasteries: makeSkillMasteries(pronunciation: 0.2),
            todaySessions: []
        )
        let hasPronunciation = plan.activities.contains { $0.type == .pronunciationPractice }
        #expect(hasPronunciation)
    }

    @Test("No pronunciation practice when mastery is adequate")
    func noPronunciationWhenAdequate() {
        let plan = generator.generatePlan(
            profile: makeProfile(dailyGoalMinutes: 30),
            dueReviewItems: [],
            availableMedia: makeMedia(),
            skillMasteries: makeSkillMasteries(pronunciation: 0.7),
            todaySessions: []
        )
        let hasPronunciation = plan.activities.contains { $0.type == .pronunciationPractice }
        #expect(!hasPronunciation)
    }

    // MARK: - Skill Balancing

    @Test("Grammar review added when grammar lags behind vocab")
    func grammarWhenLagging() {
        let plan = generator.generatePlan(
            profile: makeProfile(dailyGoalMinutes: 30),
            dueReviewItems: [],
            availableMedia: makeMedia(),
            skillMasteries: makeSkillMasteries(vocab: 0.7, grammar: 0.3),
            todaySessions: []
        )
        let hasGrammar = plan.activities.contains { $0.type == .grammarReview }
        #expect(hasGrammar)
    }

    @Test("Vocabulary building when vocab lags or is equal to grammar")
    func vocabWhenLagging() {
        let plan = generator.generatePlan(
            profile: makeProfile(dailyGoalMinutes: 30),
            dueReviewItems: [],
            availableMedia: makeMedia(),
            skillMasteries: makeSkillMasteries(vocab: 0.5, grammar: 0.5),
            todaySessions: []
        )
        let hasVocab = plan.activities.contains { $0.type == .vocabularyBuilding }
        #expect(hasVocab)
    }

    // MARK: - Already Completed Sessions

    @Test("Already completed sessions reduce remaining time")
    func completedSessionsReduceTime() {
        let completedSession = StudySession(
            userId: userId,
            sessionType: "review",
            durationSeconds: 600, // 10 minutes
            completedAt: Date()
        )
        let plan = generator.generatePlan(
            profile: makeProfile(dailyGoalMinutes: 15),
            dueReviewItems: makeDueItems(count: 5),
            availableMedia: makeMedia(),
            skillMasteries: makeSkillMasteries(),
            todaySessions: [completedSession]
        )
        #expect(plan.totalMinutes <= 5)
    }

    // MARK: - Empty Inputs

    @Test("Handles completely empty inputs gracefully")
    func emptyInputs() {
        let plan = generator.generatePlan(
            profile: makeProfile(dailyGoalMinutes: 15),
            dueReviewItems: [],
            availableMedia: [],
            skillMasteries: [],
            todaySessions: []
        )
        // Should still produce a valid plan (possibly empty if no activities fit)
        #expect(plan.totalMinutes >= 0)
        #expect(plan.goalMinutes == 15)
    }
}
