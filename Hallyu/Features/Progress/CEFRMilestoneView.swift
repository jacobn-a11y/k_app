import SwiftUI

// MARK: - CEFR Milestone Definitions

struct CEFRMilestone: Identifiable, Equatable {
    let id: String
    let level: String
    let title: String
    let description: String
    let requiredSkills: [SkillRequirement]
    let iconName: String

    struct SkillRequirement: Equatable {
        let skillType: String
        let minimumAccuracy: Double
    }
}

enum CEFRMilestones {
    static let all: [CEFRMilestone] = [
        // Pre-A1 Milestones
        CEFRMilestone(
            id: "preA1_hangul_recognition",
            level: "pre-A1",
            title: "Hangul Reader",
            description: "Can recognize all basic Hangul characters",
            requiredSkills: [
                .init(skillType: "hangul_recognition", minimumAccuracy: 0.8)
            ],
            iconName: "character.book.closed.fill"
        ),
        CEFRMilestone(
            id: "preA1_hangul_production",
            level: "pre-A1",
            title: "Hangul Writer",
            description: "Can write all basic Hangul characters from memory",
            requiredSkills: [
                .init(skillType: "hangul_production", minimumAccuracy: 0.7)
            ],
            iconName: "pencil.line"
        ),
        CEFRMilestone(
            id: "preA1_syllable_blocks",
            level: "pre-A1",
            title: "Block Builder",
            description: "Can compose syllable blocks correctly",
            requiredSkills: [
                .init(skillType: "hangul_recognition", minimumAccuracy: 0.85),
                .init(skillType: "hangul_production", minimumAccuracy: 0.75)
            ],
            iconName: "square.grid.2x2.fill"
        ),

        // A1 Milestones
        CEFRMilestone(
            id: "a1_basic_greetings",
            level: "A1",
            title: "First Words",
            description: "Can understand basic greetings in dramas",
            requiredSkills: [
                .init(skillType: "vocab_recognition", minimumAccuracy: 0.6),
                .init(skillType: "listening", minimumAccuracy: 0.5)
            ],
            iconName: "hand.wave.fill"
        ),
        CEFRMilestone(
            id: "a1_50_words",
            level: "A1",
            title: "Word Collector",
            description: "Can recognize 50 high-frequency Korean words",
            requiredSkills: [
                .init(skillType: "vocab_recognition", minimumAccuracy: 0.65)
            ],
            iconName: "textformat.abc"
        ),
        CEFRMilestone(
            id: "a1_basic_pronunciation",
            level: "A1",
            title: "First Speaker",
            description: "Can pronounce basic Korean words clearly",
            requiredSkills: [
                .init(skillType: "pronunciation", minimumAccuracy: 0.6)
            ],
            iconName: "mic.fill"
        ),

        // A2 Milestones
        CEFRMilestone(
            id: "a2_scaffolded_drama",
            level: "A2",
            title: "Drama Watcher",
            description: "Can follow a heavily scaffolded K-drama clip",
            requiredSkills: [
                .init(skillType: "listening", minimumAccuracy: 0.6),
                .init(skillType: "vocab_recognition", minimumAccuracy: 0.7),
                .init(skillType: "grammar", minimumAccuracy: 0.5)
            ],
            iconName: "tv.fill"
        ),
        CEFRMilestone(
            id: "a2_basic_grammar",
            level: "A2",
            title: "Grammar Starter",
            description: "Can identify basic Korean grammar patterns",
            requiredSkills: [
                .init(skillType: "grammar", minimumAccuracy: 0.6)
            ],
            iconName: "text.book.closed.fill"
        ),
        CEFRMilestone(
            id: "a2_webtoon_reader",
            level: "A2",
            title: "Webtoon Reader",
            description: "Can read simple webtoon dialogue with glosses",
            requiredSkills: [
                .init(skillType: "reading", minimumAccuracy: 0.6),
                .init(skillType: "vocab_recognition", minimumAccuracy: 0.7)
            ],
            iconName: "book.fill"
        ),

        // B1 Milestones
        CEFRMilestone(
            id: "b1_drama_subtitles",
            level: "B1",
            title: "Subtitle Viewer",
            description: "Can follow main plot of a K-drama episode with Korean subtitles",
            requiredSkills: [
                .init(skillType: "listening", minimumAccuracy: 0.7),
                .init(skillType: "vocab_recognition", minimumAccuracy: 0.8),
                .init(skillType: "grammar", minimumAccuracy: 0.7),
                .init(skillType: "reading", minimumAccuracy: 0.7)
            ],
            iconName: "captions.bubble.fill"
        ),
        CEFRMilestone(
            id: "b1_conversation",
            level: "B1",
            title: "Conversationalist",
            description: "Can understand and produce basic conversational Korean",
            requiredSkills: [
                .init(skillType: "vocab_production", minimumAccuracy: 0.7),
                .init(skillType: "pronunciation", minimumAccuracy: 0.7)
            ],
            iconName: "bubble.left.and.bubble.right.fill"
        ),

        // B2 Milestones
        CEFRMilestone(
            id: "b2_no_subtitles",
            level: "B2",
            title: "Subtitle-Free",
            description: "Can understand K-drama without subtitles for familiar topics",
            requiredSkills: [
                .init(skillType: "listening", minimumAccuracy: 0.85),
                .init(skillType: "vocab_recognition", minimumAccuracy: 0.9),
                .init(skillType: "grammar", minimumAccuracy: 0.85)
            ],
            iconName: "star.fill"
        ),
        CEFRMilestone(
            id: "b2_news_reader",
            level: "B2",
            title: "News Reader",
            description: "Can read Korean news articles with minimal dictionary use",
            requiredSkills: [
                .init(skillType: "reading", minimumAccuracy: 0.85),
                .init(skillType: "vocab_recognition", minimumAccuracy: 0.9)
            ],
            iconName: "newspaper.fill"
        ),
    ]

    static func milestones(for level: String) -> [CEFRMilestone] {
        all.filter { $0.level == level }
    }
}

// MARK: - Milestone View

struct CEFRMilestoneView: View {
    let skillMasteries: [SkillMastery]
    let currentLevel: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Learning Milestones")
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)

                ForEach(["pre-A1", "A1", "A2", "B1", "B2"], id: \.self) { level in
                    let milestones = CEFRMilestones.milestones(for: level)
                    if !milestones.isEmpty {
                        levelSection(level: level, milestones: milestones)
                    }
                }
            }
            .padding()
        }
    }

    private func levelSection(level: String, milestones: [CEFRMilestone]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(level)
                    .font(.headline)
                    .foregroundStyle(levelColor(level))
                    .accessibilityAddTraits(.isHeader)

                if level == currentLevel {
                    Text("Current")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(levelColor(level).opacity(0.2))
                        .clipShape(Capsule())
                        .accessibilityLabel("Current level: \(level)")
                }
            }

            ForEach(milestones) { milestone in
                milestoneRow(milestone)
            }
        }
    }

    private func milestoneRow(_ milestone: CEFRMilestone) -> some View {
        let isUnlocked = isMilestoneUnlocked(milestone)
        let progress = milestoneProgress(milestone)

        return HStack(spacing: 12) {
            Image(systemName: milestone.iconName)
                .font(.title3)
                .foregroundStyle(isUnlocked ? levelColor(milestone.level) : .secondary)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(milestone.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isUnlocked ? .primary : .secondary)

                    if isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }

                Text(milestone.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !isUnlocked {
                    ProgressView(value: progress)
                        .tint(levelColor(milestone.level))
                        .accessibilityLabel("Progress: \(Int(progress * 100)) percent")
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray6).opacity(isUnlocked ? 0.5 : 0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(milestone.title): \(milestone.description). \(isUnlocked ? "Completed" : "\(Int(progress * 100)) percent progress")")
    }

    // MARK: - Helpers

    private func isMilestoneUnlocked(_ milestone: CEFRMilestone) -> Bool {
        for req in milestone.requiredSkills {
            let mastery = skillMasteries.first { $0.skillType == req.skillType }
            guard let mastery = mastery, mastery.accuracy >= req.minimumAccuracy else {
                return false
            }
        }
        return true
    }

    private func milestoneProgress(_ milestone: CEFRMilestone) -> Double {
        guard !milestone.requiredSkills.isEmpty else { return 0 }
        let totalProgress = milestone.requiredSkills.reduce(0.0) { sum, req in
            let mastery = skillMasteries.first { $0.skillType == req.skillType }
            let accuracy = mastery?.accuracy ?? 0
            return sum + min(accuracy / req.minimumAccuracy, 1.0)
        }
        return totalProgress / Double(milestone.requiredSkills.count)
    }

    private func levelColor(_ level: String) -> Color {
        switch level {
        case "pre-A1": return .blue
        case "A1": return .green
        case "A2": return .orange
        case "B1": return .purple
        case "B2": return .red
        default: return .secondary
        }
    }
}
