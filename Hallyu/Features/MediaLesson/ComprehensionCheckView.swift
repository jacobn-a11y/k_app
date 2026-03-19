import SwiftUI

/// Step 5.1 (sub-step 4): Comprehension check with Claude-generated or pre-authored questions.
struct ComprehensionCheckView: View {
    @Bindable var viewModel: MediaLessonViewModel

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isGeneratingQuestions {
                generatingView
            } else if let question = viewModel.currentComprehensionQuestion {
                questionView(question)
            } else {
                completedView
            }
        }
        .padding()
    }

    // MARK: - Generating

    private var generatingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Generating comprehension questions...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Question

    private func questionView(_ question: PracticeItem) -> some View {
        VStack(spacing: 20) {
            // Progress
            HStack {
                Text("Question \(viewModel.comprehensionCurrentIndex + 1) of \(viewModel.comprehensionQuestions.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(questionTypeBadge(question.type))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(questionTypeColor(question.type).opacity(0.15))
                    .foregroundStyle(questionTypeColor(question.type))
                    .clipShape(Capsule())
            }

            // Question prompt
            Text(question.prompt)
                .font(.title3)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            if viewModel.comprehensionShowingFeedback {
                feedbackView(for: question)
            } else {
                answerOptions(for: question)
            }
        }
    }

    // MARK: - Answer Options

    private func answerOptions(for question: PracticeItem) -> some View {
        VStack(spacing: 12) {
            // Correct answer + alternatives as multiple choice
            let allOptions = ([question.correctAnswer] + question.alternatives).shuffled()

            ForEach(allOptions, id: \.self) { option in
                Button {
                    withAnimation { viewModel.submitComprehensionAnswer(option) }
                } label: {
                    Text(option)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Feedback

    private func feedbackView(for question: PracticeItem) -> some View {
        let lastAnswer = viewModel.comprehensionAnswers.last
        let wasCorrect = lastAnswer?.wasCorrect ?? false

        return VStack(spacing: 16) {
            HStack {
                Image(systemName: wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(wasCorrect ? .green : .red)

                Text(wasCorrect ? "Correct!" : "Not quite")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            if !wasCorrect {
                VStack(spacing: 4) {
                    Text("The correct answer is:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(question.correctAnswer)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                }
            }

            Button {
                withAnimation { viewModel.nextComprehensionQuestion() }
            } label: {
                Text(viewModel.comprehensionCurrentIndex + 1 < viewModel.comprehensionQuestions.count ? "Next Question" : "Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(wasCorrect ? Color.green.opacity(0.08) : Color.red.opacity(0.08))
        )
    }

    // MARK: - Completed

    private var completedView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 56))
                .foregroundStyle(.accentColor)

            Text("Comprehension Check Complete!")
                .font(.title2)
                .fontWeight(.bold)

            let score = viewModel.comprehensionScore
            Text("Score: \(Int(score * 100))%")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(score >= 0.7 ? .green : .orange)

            let correct = viewModel.comprehensionAnswers.filter { $0.wasCorrect }.count
            let total = viewModel.comprehensionAnswers.count
            Text("\(correct) of \(total) correct")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    // MARK: - Helpers

    private func questionTypeBadge(_ type: String) -> String {
        switch type {
        case "fill_in_blank": return "Fill in Blank"
        case "comprehension": return "Comprehension"
        case "production": return "Production"
        default: return type.capitalized
        }
    }

    private func questionTypeColor(_ type: String) -> Color {
        switch type {
        case "fill_in_blank": return .blue
        case "comprehension": return .purple
        case "production": return .orange
        default: return .gray
        }
    }
}
