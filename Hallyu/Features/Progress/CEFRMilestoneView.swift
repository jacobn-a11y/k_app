import SwiftUI

// MARK: - Milestone Definition

struct CEFRMilestone: Identifiable, Equatable, Sendable {
    let id: String
    let level: AppState.CEFRLevel
    let title: String
    let description: String
    let requiredSkills: [MilestoneRequirement]

    var isUnlocked: Bool {
        requiredSkills.allSatisfy { $0.isMet }
    }

    var progress: Double {
        guard !requiredSkills.isEmpty else { return 0 }
        let metCount = requiredSkills.filter { $0.isMet }.count
        return Double(metCount) / Double(requiredSkills.count)
    }
}

struct MilestoneRequirement: Identifiable, Equatable, Sendable {
    let id: String
    let skillType: String
    let threshold: Double
    let currentValue: Double
    let description: String

    var isMet: Bool {
        currentValue >= threshold
    }
}

// MARK: - Milestone Data

enum CEFRMilestoneData {

    static func allMilestones(skillBreakdowns: [SkillBreakdown]) -> [CEFRMilestone] {
        func accuracy(for skillType: String) -> Double {
            skillBreakdowns.first { $0.skillType == skillType }?.accuracy ?? 0.0
        }

        return [
            CEFRMilestone(
                id: "preA1",
                level: .preA1,
                title: "Can recognize all Hangul characters",
                description: "You can identify and sound out all basic Korean consonants and vowels.",
                requiredSkills: [
                    MilestoneRequirement(id: "preA1_hangul_rec", skillType: "hangul_recognition", threshold: 0.8, currentValue: accuracy(for: "hangul_recognition"), description: "Hangul recognition accuracy >= 80%"),
                    MilestoneRequirement(id: "preA1_hangul_prod", skillType: "hangul_production", threshold: 0.6, currentValue: accuracy(for: "hangul_production"), description: "Hangul production accuracy >= 60%"),
                ]
            ),
            CEFRMilestone(
                id: "a1_greetings",
                level: .a1,
                title: "Can understand basic greetings in dramas",
                description: "You recognize common greetings and simple phrases when watching K-dramas.",
                requiredSkills: [
                    MilestoneRequirement(id: "a1_vocab", skillType: "vocab_recognition", threshold: 0.5, currentValue: accuracy(for: "vocab_recognition"), description: "Vocabulary recognition >= 50%"),
                    MilestoneRequirement(id: "a1_listening", skillType: "listening", threshold: 0.3, currentValue: accuracy(for: "listening"), description: "Listening comprehension >= 30%"),
                ]
            ),
            CEFRMilestone(
                id: "a1_selfintro",
                level: .a1,
                title: "Can introduce yourself in Korean",
                description: "You can say your name, where you're from, and ask simple questions.",
                requiredSkills: [
                    MilestoneRequirement(id: "a1_pronunciation", skillType: "pronunciation", threshold: 0.4, currentValue: accuracy(for: "pronunciation"), description: "Pronunciation accuracy >= 40%"),
                    MilestoneRequirement(id: "a1_grammar", skillType: "grammar", threshold: 0.3, currentValue: accuracy(for: "grammar"), description: "Grammar accuracy >= 30%"),
                ]
            ),
            CEFRMilestone(
                id: "a2_scaffolded",
                level: .a2,
                title: "Can follow a heavily scaffolded K-drama clip",
                description: "With vocabulary pre-teaching and subtitles, you follow short drama scenes.",
                requiredSkills: [
                    MilestoneRequirement(id: "a2_vocab", skillType: "vocab_recognition", threshold: 0.6, currentValue: accuracy(for: "vocab_recognition"), description: "Vocabulary recognition >= 60%"),
                    MilestoneRequirement(id: "a2_listening", skillType: "listening", threshold: 0.5, currentValue: accuracy(for: "listening"), description: "Listening comprehension >= 50%"),
                    MilestoneRequirement(id: "a2_grammar", skillType: "grammar", threshold: 0.5, currentValue: accuracy(for: "grammar"), description: "Grammar accuracy >= 50%"),
                ]
            ),
            CEFRMilestone(
                id: "a2_webtoon",
                level: .a2,
                title: "Can read a simple webtoon panel",
                description: "You understand dialogue in webtoon panels with common vocabulary.",
                requiredSkills: [
                    MilestoneRequirement(id: "a2_reading", skillType: "reading", threshold: 0.5, currentValue: accuracy(for: "reading"), description: "Reading comprehension >= 50%"),
                    MilestoneRequirement(id: "a2_vocab_prod", skillType: "vocab_production", threshold: 0.4, currentValue: accuracy(for: "vocab_production"), description: "Vocabulary production >= 40%"),
                ]
            ),
            CEFRMilestone(
                id: "b1_drama",
                level: .b1,
                title: "Can follow main plot of a K-drama episode",
                description: "With Korean subtitles, you understand the main storyline of a full episode.",
                requiredSkills: [
                    MilestoneRequirement(id: "b1_vocab", skillType: "vocab_recognition", threshold: 0.75, currentValue: accuracy(for: "vocab_recognition"), description: "Vocabulary recognition >= 75%"),
                    MilestoneRequirement(id: "b1_listening", skillType: "listening", threshold: 0.65, currentValue: accuracy(for: "listening"), description: "Listening comprehension >= 65%"),
                    MilestoneRequirement(id: "b1_grammar", skillType: "grammar", threshold: 0.65, currentValue: accuracy(for: "grammar"), description: "Grammar accuracy >= 65%"),
                ]
            ),
            CEFRMilestone(
                id: "b1_news",
                level: .b1,
                title: "Can understand a simple Korean news article",
                description: "You read and understand straightforward news articles on familiar topics.",
                requiredSkills: [
                    MilestoneRequirement(id: "b1_reading", skillType: "reading", threshold: 0.65, currentValue: accuracy(for: "reading"), description: "Reading comprehension >= 65%"),
                    MilestoneRequirement(id: "b1_vocab2", skillType: "vocab_recognition", threshold: 0.7, currentValue: accuracy(for: "vocab_recognition"), description: "Vocabulary recognition >= 70%"),
                ]
            ),
            CEFRMilestone(
                id: "b2_nosubs",
                level: .b2,
                title: "Can understand K-drama without subtitles",
                description: "For familiar topics and genres, you follow along without any subtitle assistance.",
                requiredSkills: [
                    MilestoneRequirement(id: "b2_listening", skillType: "listening", threshold: 0.85, currentValue: accuracy(for: "listening"), description: "Listening comprehension >= 85%"),
                    MilestoneRequirement(id: "b2_vocab", skillType: "vocab_recognition", threshold: 0.9, currentValue: accuracy(for: "vocab_recognition"), description: "Vocabulary recognition >= 90%"),
                    MilestoneRequirement(id: "b2_grammar", skillType: "grammar", threshold: 0.8, currentValue: accuracy(for: "grammar"), description: "Grammar accuracy >= 80%"),
                    MilestoneRequirement(id: "b2_pronunciation", skillType: "pronunciation", threshold: 0.7, currentValue: accuracy(for: "pronunciation"), description: "Pronunciation accuracy >= 70%"),
                ]
            ),
        ]
    }
}

// MARK: - View

struct CEFRMilestoneView: View {
    let currentLevel: AppState.CEFRLevel
    let skillBreakdowns: [SkillBreakdown]

    private var milestones: [CEFRMilestone] {
        CEFRMilestoneData.allMilestones(skillBreakdowns: skillBreakdowns)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                currentLevelHeader

                ForEach(AppState.CEFRLevel.allCases, id: \.self) { level in
                    let levelMilestones = milestones.filter { $0.level == level }
                    if !levelMilestones.isEmpty {
                        levelSection(level: level, milestones: levelMilestones)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Milestones")
    }

    // MARK: - Current Level Header

    private var currentLevelHeader: some View {
        VStack(spacing: 8) {
            Text("Current Level: \(currentLevel.rawValue)")
                .font(.title2.bold())

            let unlocked = milestones.filter { $0.isUnlocked }.count
            let total = milestones.count
            Text("\(unlocked) of \(total) milestones achieved")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Level Section

    private func levelSection(level: AppState.CEFRLevel, milestones: [CEFRMilestone]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(level.rawValue)
                .font(.headline)
                .foregroundStyle(level <= currentLevel ? .primary : .secondary)

            ForEach(milestones) { milestone in
                milestoneCard(milestone)
            }
        }
    }

    // MARK: - Milestone Card

    private func milestoneCard(_ milestone: CEFRMilestone) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: milestone.isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                    .foregroundStyle(milestone.isUnlocked ? .green : .secondary)

                Text(milestone.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(milestone.isUnlocked ? .primary : .secondary)

                Spacer()

                if !milestone.isUnlocked {
                    Text("\(Int(milestone.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }

            Text(milestone.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !milestone.isUnlocked {
                ProgressView(value: milestone.progress)
                    .tint(.blue)

                ForEach(milestone.requiredSkills) { req in
                    HStack(spacing: 4) {
                        Image(systemName: req.isMet ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(req.isMet ? .green : .secondary)
                            .font(.caption2)
                        Text(req.description)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(milestone.isUnlocked ? Color.green.opacity(0.05) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
