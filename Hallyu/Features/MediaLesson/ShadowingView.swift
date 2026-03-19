import SwiftUI

/// Step 5.3: Shadowing practice - user listens to and repeats key sentences.
struct ShadowingView: View {
    @Bindable var viewModel: MediaLessonViewModel
    @State private var isRecording: Bool = false
    @State private var lastTranscript: String = ""
    @State private var lastConfidence: Double = 0
    @State private var showFeedback: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            if let sentence = viewModel.currentShadowingSentence {
                sentenceView(sentence)
            } else {
                completedView
            }
        }
        .padding()
    }

    // MARK: - Sentence View

    private func sentenceView(_ sentence: MediaLessonViewModel.ShadowingSentence) -> some View {
        VStack(spacing: 20) {
            // Progress
            HStack {
                Text("Sentence \(viewModel.shadowingCurrentIndex + 1) of \(viewModel.shadowingSentences.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if sentence.attempts > 0 {
                    Text("Attempt \(sentence.attempts)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Target sentence
            VStack(spacing: 12) {
                Text(sentence.korean)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(sentence.english)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )

            // Play native audio button
            Button {
                // Play the segment from the media
            } label: {
                Label("Listen to Native", systemImage: "speaker.wave.2.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            // Recording area
            recordingArea(sentence: sentence)

            // Feedback area
            if showFeedback {
                feedbackArea(sentence: sentence)
            }

            Spacer()
        }
    }

    // MARK: - Recording

    private func recordingArea(sentence: MediaLessonViewModel.ShadowingSentence) -> some View {
        VStack(spacing: 12) {
            // Waveform placeholder
            if isRecording {
                waveformIndicator
            }

            // Record button
            Button {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                HStack {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 32))
                    Text(isRecording ? "Stop Recording" : "Record Your Voice")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(isRecording ? .red : .accentColor)
        }
    }

    private var waveformIndicator: some View {
        HStack(spacing: 3) {
            ForEach(0..<20, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.accentColor)
                    .frame(width: 3, height: CGFloat.random(in: 8...32))
            }
        }
        .frame(height: 40)
        .padding(.horizontal)
    }

    // MARK: - Feedback

    private func feedbackArea(sentence: MediaLessonViewModel.ShadowingSentence) -> some View {
        VStack(spacing: 12) {
            // Transcript comparison
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Target:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Text(sentence.korean)
                    .font(.body)

                HStack {
                    Text("You said:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Text(lastTranscript.isEmpty ? "(no speech detected)" : lastTranscript)
                    .font(.body)
                    .foregroundStyle(lastConfidence >= 0.7 ? .green : .orange)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )

            // Confidence score
            HStack {
                Text("Match: \(Int(lastConfidence * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(lastConfidence >= 0.7 ? .green : .orange)

                Spacer()

                confidenceBadge
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    showFeedback = false
                    lastTranscript = ""
                    lastConfidence = 0
                } label: {
                    Label("Try Again", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    withAnimation { viewModel.nextShadowingSentence() }
                    showFeedback = false
                    lastTranscript = ""
                    lastConfidence = 0
                } label: {
                    Text(viewModel.shadowingCurrentIndex + 1 < viewModel.shadowingSentences.count ? "Next" : "Finish")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var confidenceBadge: some View {
        let (text, color): (String, Color) = {
            if lastConfidence >= 0.9 { return ("Excellent", .green) }
            if lastConfidence >= 0.7 { return ("Good", .blue) }
            if lastConfidence >= 0.5 { return ("Fair", .orange) }
            return ("Keep Trying", .red)
        }()

        return Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    // MARK: - Recording Actions

    private func startRecording() {
        isRecording = true
        Task {
            _ = try? await viewModel.audioService.startRecording()
        }
    }

    private func stopRecording() {
        isRecording = false
        Task {
            guard let audioURL = try? await viewModel.audioService.stopRecording() else { return }
            let result = try? await viewModel.speechRecognition.recognizeSpeech(from: audioURL)

            await MainActor.run {
                lastTranscript = result?.transcript ?? ""
                lastConfidence = result?.confidence ?? 0
                showFeedback = true
                viewModel.recordShadowingAttempt(
                    transcript: lastTranscript,
                    confidence: lastConfidence
                )
            }
        }
    }

    // MARK: - Completed

    private var completedView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.accentColor)

            Text("Shadowing Complete!")
                .font(.title2)
                .fontWeight(.bold)

            let practiced = viewModel.shadowingSentences.prefix(viewModel.shadowingCurrentIndex)
            let avgConfidence = practiced.isEmpty ? 0 :
                practiced.reduce(0.0) { $0 + $1.bestConfidence } / Double(practiced.count)

            Text("Average match: \(Int(avgConfidence * 100))%")
                .font(.title3)
                .foregroundStyle(avgConfidence >= 0.7 ? .green : .orange)

            Text("\(practiced.count) sentences practiced")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}
