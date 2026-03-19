import SwiftUI
import SwiftData

struct MediaChallengeView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MediaChallengeViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    challengeContent(vm)
                } else {
                    ProgressView("Preparing challenge...")
                        .onAppear { setupChallenge() }
                }
            }
            .navigationTitle("Monthly Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if case .completed = viewModel?.state {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
    }

    // MARK: - Challenge Content

    @ViewBuilder
    private func challengeContent(_ vm: MediaChallengeViewModel) -> some View {
        switch vm.state {
        case .notStarted:
            notStartedView(vm)
        case .inProgress:
            if let question = vm.currentQuestion {
                questionView(question: question, vm: vm)
            }
        case .completed(let result):
            resultView(result)
        }
    }

    // MARK: - Not Started

    private func notStartedView(_ vm: MediaChallengeViewModel) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)

            Text("Monthly Proficiency Challenge")
                .font(.title2.bold())

            if let media = vm.mediaContent {
                Text("Test your skills with: \(media.title)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("Answer \(vm.questions.count) questions to assess your current Korean proficiency. No scaffolding — this is a real test!")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Button {
                if !vm.questions.isEmpty {
                    vm.state = .inProgress(questionIndex: 0)
                }
            } label: {
                Text("Start Challenge")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
        .padding()
    }

    // MARK: - Question View

    private func questionView(question: ChallengeQuestion, vm: MediaChallengeViewModel) -> some View {
        VStack(spacing: 20) {
            // Progress
            VStack(spacing: 4) {
                ProgressView(value: vm.progress)
                    .tint(.blue)
                Text("Question \(vm.currentQuestionIndex + 1) of \(vm.questions.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Spacer()

            // Question
            Text(question.prompt)
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Skill badge
            Text(ProgressViewModel.skillDisplayNames[question.skillType] ?? question.skillType)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())

            Spacer()

            // Options
            VStack(spacing: 12) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    Button {
                        vm.answerQuestion(selectedIndex: index)
                    } label: {
                        HStack {
                            Text(option)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                            Spacer()

                            if question.isAnswered {
                                if index == question.correctIndex {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else if index == question.selectedIndex {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            } else if question.selectedIndex == index {
                                Image(systemName: "circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding()
                        .background(optionBackground(index: index, question: question))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(question.isAnswered)
                }
            }
            .padding(.horizontal)

            // Next button
            if question.isAnswered {
                Button {
                    vm.advance()
                } label: {
                    Text(vm.isLastQuestion ? "See Results" : "Next Question")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.vertical)
    }

    private func optionBackground(index: Int, question: ChallengeQuestion) -> Color {
        guard question.isAnswered else {
            return question.selectedIndex == index ? Color.blue.opacity(0.1) : Color(.systemGray6)
        }
        if index == question.correctIndex { return Color.green.opacity(0.15) }
        if index == question.selectedIndex { return Color.red.opacity(0.15) }
        return Color(.systemGray6)
    }

    // MARK: - Result View

    private func resultView(_ result: ChallengeResult) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Score
                VStack(spacing: 8) {
                    Text("\(result.correctCount)/\(result.totalQuestions)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text("\(Int(result.accuracy * 100))% Accuracy")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding()

                // Level assessment
                VStack(spacing: 8) {
                    Text("Estimated Level")
                        .font(.headline)

                    Text(result.estimatedLevel.rawValue)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(result.levelChanged ? .orange : .blue)

                    if result.levelChanged {
                        HStack(spacing: 4) {
                            Text(result.previousLevel.rawValue)
                            Image(systemName: "arrow.right")
                            Text(result.estimatedLevel.rawValue)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Skill breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Skill Breakdown")
                        .font(.headline)

                    ForEach(Array(result.skillResults.sorted { $0.key < $1.key }), id: \.key) { key, skillResult in
                        HStack {
                            Text(ProgressViewModel.skillDisplayNames[key] ?? key)
                                .font(.subheadline)
                            Spacer()
                            Text("\(skillResult.correct)/\(skillResult.total)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Circle()
                                .fill(skillResult.accuracy >= 0.7 ? .green : skillResult.accuracy >= 0.5 ? .orange : .red)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Strengths
                if !result.strengths.isEmpty {
                    feedbackSection(title: "Strengths", items: result.strengths, icon: "star.fill", color: .green)
                }

                // Weaknesses
                if !result.weaknesses.isEmpty {
                    feedbackSection(title: "Areas to Improve", items: result.weaknesses, icon: "arrow.up.circle.fill", color: .orange)
                }

                // Recommendations
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations")
                        .font(.headline)

                    ForEach(result.recommendations, id: \.self) { rec in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                            Text(rec)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }

    private func feedbackSection(title: String, items: [String], icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            ForEach(items, id: \.self) { item in
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .font(.caption)
                    Text(item)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Setup

    private func setupChallenge() {
        let vm = MediaChallengeViewModel(learnerModel: services.learnerModel)

        let mediaDescriptor = FetchDescriptor<MediaContent>()
        let media = (try? modelContext.fetch(mediaDescriptor)) ?? []

        let profileDescriptor = FetchDescriptor<LearnerProfile>()
        let profiles = (try? modelContext.fetch(profileDescriptor)) ?? []
        let currentLevel = AppState.CEFRLevel(rawValue: profiles.first?.cefrLevel ?? "pre-A1") ?? .preA1

        // Pick a random unseen media piece for the challenge
        if let challengeMedia = media.randomElement() {
            vm.startChallenge(media: challengeMedia, previousLevel: currentLevel)
        }

        viewModel = vm
    }
}
