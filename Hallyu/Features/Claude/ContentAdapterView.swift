import SwiftUI

struct ContentAdapterView: View {
    @Bindable var viewModel: ContentAdapterViewModel
    let userId: UUID

    @State private var userAnswer: String = ""
    @State private var selectedAlternative: String?

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(.orange)
                Text("Practice Exercises")
                    .font(.headline)
                Spacer()
                if !viewModel.exercises.isEmpty {
                    Text("\(viewModel.currentExerciseIndex + 1)/\(viewModel.totalExercises)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Progress bar
            if viewModel.phase == .showingExercises {
                ProgressView(value: viewModel.progress)
                    .tint(.orange)
            }

            switch viewModel.phase {
            case .idle:
                EmptyView()

            case .generating:
                ProgressView("Generating exercises...")
                    .padding()

            case .showingExercises:
                if let exercise = viewModel.currentExercise {
                    exerciseView(exercise)
                }

            case .completed:
                completionView

            case .error(let message):
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    @ViewBuilder
    private func exerciseView(_ exercise: PracticeItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise type badge
            Text(exerciseTypeLabel(exercise.type))
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.orange.opacity(0.15), in: Capsule())

            // Prompt
            Text(exercise.prompt)
                .font(.body)

            if exercise.type == "production" {
                // Free-form answer
                TextField("Your answer...", text: $userAnswer)
                    .textFieldStyle(.roundedBorder)

                Button("Submit") {
                    viewModel.submitAnswer(userAnswer)
                }
                .buttonStyle(.borderedProminent)
                .disabled(userAnswer.isEmpty)
            } else {
                // Multiple choice
                let allOptions = ([exercise.correctAnswer] + exercise.alternatives).shuffled()
                ForEach(allOptions, id: \.self) { option in
                    Button {
                        selectedAlternative = option
                        viewModel.submitAnswer(option)
                    } label: {
                        HStack {
                            Text(option)
                                .foregroundStyle(.primary)
                            Spacer()
                            if viewModel.isShowingAnswer {
                                if option == exercise.correctAnswer {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else if option == selectedAlternative {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .padding()
                        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(viewModel.isShowingAnswer)
                }
            }

            if viewModel.isShowingAnswer {
                Button("Next") {
                    userAnswer = ""
                    selectedAlternative = nil
                    viewModel.nextExercise()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var completionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.yellow)

            Text("Exercises Complete!")
                .font(.title3)
                .fontWeight(.bold)

            Text("\(viewModel.correctCount)/\(viewModel.totalExercises) correct")
                .font(.body)
                .foregroundStyle(.secondary)

            Text("Accuracy: \(Int(viewModel.accuracy * 100))%")
                .font(.body)

            Button("Done") {
                Task { await viewModel.updateLearnerModel(userId: userId) }
                viewModel.reset()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func exerciseTypeLabel(_ type: String) -> String {
        switch type {
        case "fill_in_blank": return "Fill in the Blank"
        case "comprehension": return "Comprehension"
        case "production": return "Production"
        default: return type
        }
    }
}
