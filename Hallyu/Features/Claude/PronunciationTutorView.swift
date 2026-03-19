import SwiftUI

struct PronunciationTutorView: View {
    @Bindable var viewModel: PronunciationTutorViewModel

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "waveform.circle.fill")
                    .foregroundStyle(.blue)
                Text("Pronunciation Tutor")
                    .font(.headline)
                Spacer()
            }

            // Target text
            Text(viewModel.targetText)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            // Attempt counter
            if viewModel.attemptCount > 0 {
                Text("Attempt \(viewModel.attemptCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            switch viewModel.phase {
            case .idle:
                recordButton

            case .recording:
                VStack {
                    Image(systemName: "waveform")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                        .symbolEffect(.pulse)

                    Button("Stop") {
                        Task { await viewModel.stopRecordingAndAnalyze() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }

            case .processing:
                ProgressView("Analyzing pronunciation...")
                    .padding()

            case .showingFeedback:
                if let feedback = viewModel.feedback {
                    feedbackView(feedback)
                }

            case .showingDrill:
                Text("Drill mode")

            case .error(let message):
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Try Again") { viewModel.tryAgain() }
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding()
    }

    private var recordButton: some View {
        Button {
            Task { await viewModel.startRecording() }
        } label: {
            Label("Record", systemImage: "mic.fill")
                .font(.title3)
                .padding()
        }
        .buttonStyle(.borderedProminent)
    }

    @ViewBuilder
    private func feedbackView(_ feedback: PronunciationFeedback) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Result indicator
            HStack {
                Image(systemName: feedback.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(feedback.isCorrect ? .green : .orange)
                Text(feedback.isCorrect ? "Correct!" : "Keep practicing")
                    .fontWeight(.semibold)
            }
            .font(.title3)

            // What was heard
            if !viewModel.recognizedTranscript.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("We heard:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.recognizedTranscript)
                        .font(.body)
                }
            }

            // Feedback
            Text(feedback.feedback)
                .font(.body)

            // Articulatory tip
            if let tip = feedback.articulatoryTip {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(tip)
                        .font(.body)
                        .padding(8)
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
            }

            // Similar sounds
            if !feedback.similarSounds.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Practice these similar sounds:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        ForEach(feedback.similarSounds, id: \.self) { sound in
                            Text(sound)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.gray.opacity(0.15), in: Capsule())
                        }
                    }
                }
            }

            // Actions
            HStack {
                Button("Try Again") { viewModel.tryAgain() }
                    .buttonStyle(.borderedProminent)

                if viewModel.shouldSuggestDrill {
                    Button("Practice Drill") {
                        // Would navigate to drill view
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}
